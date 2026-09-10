import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject var viewModel: WorkoutViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userManager: UserManager

    @State private var selectedTab = 0
    /// Día que enseña Inicio; el Calendario lo cambia con "Entrenar este día".
    @State private var homeDay: WorkoutDay = WeeklyCalendarView.getCurrentDay()
    @State private var tutorial: TutorialStep? = nil
    @State private var showingWelcome = false
    @State private var tutorialForm = false

    @AppStorage("keepScreenOn") private var keepScreenOn = false
    @ObservedObject private var spotify = SpotifyManager.shared

    private var p: Palette { themeManager.p }

    /// La píldora de Spotify sale cuando hay sesión y no está escondida.
    private var showsSpotifyPill: Bool {
        spotify.hasSession && spotify.presentation == .compact && tutorial == nil
    }

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                HomeView(selectedTab: $selectedTab, selectedDay: $homeDay)
                    .tabItem { Label("Inicio", systemImage: "house.fill") }
                    .tag(0)

                WeeklyCalendarView(onTrain: { day in
                    homeDay = day
                    selectedTab = 0
                })
                    .tabItem { Label("Calendario", systemImage: "calendar") }
                    .tag(1)

                ExercisesView()
                    .tabItem { Label("Ejercicios", systemImage: "dumbbell.fill") }
                    .tag(2)

                HistoryView()
                    .tabItem { Label("Historial", systemImage: "clock.fill") }
                    .tag(3)

                SettingsTabView(onStartTutorial: { startTutorial() })
                    .tabItem { Label("Ajustes", systemImage: "gearshape.fill") }
                    .tag(4)
            }
            .tint(p.acc)
            .environmentObject(viewModel)
            .environmentObject(themeManager)
            .environmentObject(userManager)

            // Descanso y reproductor de Spotify flotan sobre la barra de pestañas
            // en cualquier pantalla; si coinciden, el descanso va encima.
            if (viewModel.timerActive || showsSpotifyPill) && tutorial == nil {
                VStack(spacing: 8) {
                    Spacer()
                    if viewModel.timerActive {
                        PulsoRestTimer()
                            .environmentObject(viewModel)
                            .environmentObject(themeManager)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    if showsSpotifyPill {
                        SpotifyPill(spotify: spotify, p: p)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 64)
            }

            if spotify.hasSession && spotify.presentation == .minimized && tutorial == nil {
                HStack {
                    Spacer()
                    SpotifyMiniTab(spotify: spotify, p: p)
                }
                .padding(.top, 150)
                .frame(maxHeight: .infinity, alignment: .top)
                .transition(.move(edge: .trailing))
            }

            // Celebración de récord personal
            if let pr = viewModel.prCelebration {
                VStack {
                    HStack(spacing: 8) {
                        Image(systemName: "trophy.fill")
                        Text(pr).font(.fig(14, .bold))
                    }
                    .foregroundColor(p.onacc)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(p.hgrad))
                    .shadow(color: p.glow1, radius: 16, y: 8)
                    .padding(.top, 8)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation { viewModel.prCelebration = nil }
                    }
                }
            }

            TutorialOverlay(step: $tutorial, selectedTab: $selectedTab, onCreate: { tutorialForm = true })
                .environmentObject(viewModel)
                .environmentObject(themeManager)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: viewModel.timerActive)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: viewModel.prCelebration)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: spotify.presentation)
        .sheet(isPresented: $spotify.expanded) { SpotifyExpandedSheet(spotify: spotify, p: p) }
        .onAppear {
            PhoneConnectivity.shared.viewModel = viewModel
            syncStyle()
            viewModel.trainingDay = homeDay
            PhoneConnectivity.shared.sendTodayContext()
            viewModel.updateTimerEnabledState(themeManager.isTimerEnabled)
            UIApplication.shared.isIdleTimerDisabled = keepScreenOn
            // Primera vez: la pantalla "Entrena con pulso" pide el nombre.
            if userManager.userName.trimmingCharacters(in: .whitespaces).isEmpty {
                showingWelcome = true
            }
        }
        .onChange(of: themeManager.isTimerEnabled) { _, on in viewModel.updateTimerEnabledState(on) }
        .onChange(of: themeManager.selectedAccentColor) { _, _ in syncStyle() }
        .onChange(of: themeManager.isDarkMode) { _, _ in syncStyle() }
        .onChange(of: homeDay) { _, day in
            viewModel.trainingDay = day
            PhoneConnectivity.shared.sendTodayContext()
        }
        .onChange(of: keepScreenOn) { _, on in UIApplication.shared.isIdleTimerDisabled = on }
        .onChange(of: selectedTab) { _, _ in HapticManager.shared.tabChanged() }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Si ha cambiado el día, la sesión de ayer se archiva y hoy empieza
            // a cero; el descanso en curso se recalcula contra el reloj de pared.
            let wasToday = homeDay == WeeklyCalendarView.getCurrentDay()
            viewModel.ensureSession()
            viewModel.tick()
            NotificationManager.shared.clearDelivered()
            PhoneConnectivity.shared.sendTodayContext()
            spotify.reconnectIfNeeded()
            if !wasToday || viewModel.sessionDate != Calendar.current.startOfDay(for: Date()) {
                homeDay = WeeklyCalendarView.getCurrentDay()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            viewModel.saveNow()
        }
        .fullScreenCover(isPresented: $showingWelcome) {
            PulsoWelcomeView {
                showingWelcome = false
                viewModel.markWelcomeSeen()
                // Recién llegado: el tutorial arranca solo.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { startTutorial() }
            }
            .environmentObject(userManager)
            .environmentObject(themeManager)
        }
        .sheet(isPresented: $tutorialForm, onDismiss: {
            // Tras crear el ejercicio, el tutorial sigue en "Ejercicio creado".
            if tutorial != nil, !viewModel.availableExercises.isEmpty { tutorial = .created; selectedTab = 2 }
        }) {
            ExerciseFormSheet(editing: nil, prefillDay: nil)
                .environmentObject(viewModel)
                .environmentObject(themeManager)
        }
    }

    /// La Live Activity y el widget se pintan con el degradado del acento del usuario.
    private func syncStyle() {
        let colors = themeManager.selectedAccentColor.gradientColors(isDark: themeManager.isDarkMode)
        viewModel.activityStyle = ActivityStyle(accent1: colors[0].hexString, accent2: colors[1].hexString,
                                                onAccentDark: themeManager.isDarkMode)
        viewModel.publishSummary()
    }

    private func startTutorial() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            tutorial = .welcome
            selectedTab = 0
        }
    }
}
