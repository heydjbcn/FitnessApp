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

    private var p: Palette { themeManager.p }

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

            // Descanso: flota sobre la barra de pestañas en cualquier pantalla.
            if viewModel.timerActive && tutorial == nil {
                VStack {
                    Spacer()
                    PulsoRestTimer()
                        .environmentObject(viewModel)
                        .environmentObject(themeManager)
                        .padding(.horizontal, 14)
                        .padding(.bottom, 64)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
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
        .onAppear {
            PhoneConnectivity.shared.viewModel = viewModel
            PhoneConnectivity.shared.sendTodayContext()
            viewModel.updateTimerEnabledState(themeManager.isTimerEnabled)
            UIApplication.shared.isIdleTimerDisabled = keepScreenOn
            // Primera vez: la pantalla "Entrena con pulso" pide el nombre.
            if userManager.userName.trimmingCharacters(in: .whitespaces).isEmpty {
                showingWelcome = true
            }
        }
        .onChange(of: themeManager.isTimerEnabled) { _, on in viewModel.updateTimerEnabledState(on) }
        .onChange(of: keepScreenOn) { _, on in UIApplication.shared.isIdleTimerDisabled = on }
        .onChange(of: selectedTab) { _, _ in HapticManager.shared.tabChanged() }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Al volver a la app se empieza por Inicio, en el día de hoy.
            if tutorial == nil {
                selectedTab = 0
                homeDay = WeeklyCalendarView.getCurrentDay()
            }
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

    private func startTutorial() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            tutorial = .welcome
            selectedTab = 0
        }
    }
}
