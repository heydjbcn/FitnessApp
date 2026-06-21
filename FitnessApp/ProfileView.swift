//
//  ProfileView.swift
//  FitnessApp
//
//  Created by Jordi Mauri on 29/7/25.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var workoutViewModel: WorkoutViewModel
    @State private var showingProfileEdit = false
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background(isDark: themeManager.isDarkMode).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        HStack(spacing: 16) {
                            if let imageData = userManager.profileImageData, let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage).resizable().aspectRatio(contentMode: .fill)
                                    .frame(width: 80, height: 80).clipShape(Circle())
                                    .overlay(Circle().stroke(AppColors.primary(themeManager: themeManager), lineWidth: 3))
                            } else {
                                Image(systemName: "person.circle.fill").font(.system(size: 80))
                                    .foregroundColor(AppColors.primary(themeManager: themeManager))
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(userManager.userName.isEmpty ? "Usuario" : userManager.userName)
                                    .font(AppFonts.title)
                                Text("Nivel 1: Principiante")
                                    .font(AppFonts.caption).foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        .padding()

                        // Tarjetas de Info
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ProfileInfoCard(icon: "calendar", title: "Edad", value: userManager.userAge.isEmpty ? "N/A" : "\(userManager.userAge) años")
                            ProfileInfoCard(icon: "ruler", title: "Altura", value: userManager.userHeight.isEmpty ? "N/A" : "\(userManager.userHeight) cm")
                            ProfileInfoCard(icon: "scalemass", title: "Peso", value: userManager.userWeight.isEmpty ? "N/A" : "\(userManager.userWeight) kg")
                            ProfileInfoCard(icon: "heart.text.square", title: "IMC", value: calculateBMI())
                        }
                        .padding(.horizontal)

                        // Tarjetas de Progreso
                        VStack(spacing: 12) {
                             let weeklyDays = workoutViewModel.weeklyCompletedDays()
                             let weeklyProg = workoutViewModel.weeklyProgress()
                             ProfileProgressCard(title: "Entrenamientos Semanales", value: "\(weeklyDays)", subtitle: "días", progress: weeklyProg)
                             let weeklyTime = workoutViewModel.weeklyTotalTime()
                             let timeInMinutes = Int(weeklyTime / 60)
                             let timeProgress = weeklyTime / (300 * 60)
                             ProfileProgressCard(title: "Tiempo de Ejercicio", value: "\(timeInMinutes) min", subtitle: "esta semana", progress: timeProgress) // 300 min goal
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Mi Perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape.fill")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingProfileEdit = true }) {
                        Image(systemName: "pencil")
                    }
                }
            }
            .sheet(isPresented: $showingProfileEdit) { ProfileEditView() }
            .sheet(isPresented: $showingSettings) { ProgramSettingsView() }
        }
    }

    private func calculateBMI() -> String {
        guard let weight = Double(userManager.userWeight), let height = Double(userManager.userHeight), height > 0 else { return "N/A" }
        let heightInMeters = height / 100
        let bmi = weight / (heightInMeters * heightInMeters)
        return String(format: "%.1f", bmi)
    }
}

// (Incluir ProfileInfoCard y ProfileProgressCard aquí)

// MARK: - Profile Components

struct ProfileInfoCard: View {
    let icon: String
    let title: String
    let value: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(AppColors.primary(themeManager: themeManager))
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct ProfileProgressCard: View {
    let title: String
    let value: String
    let subtitle: String
    let progress: Double
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                    
                    HStack(spacing: 4) {
                        Text(value)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.primary(themeManager: themeManager))
                        
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                    }
                }
                
                Spacer()
                
                CircularProgressView(progress: progress, themeManager: themeManager)
            }
            
            ProgressView(value: min(progress, 1.0))
                .progressViewStyle(LinearProgressViewStyle(tint: AppColors.primary(themeManager: themeManager)))
                .scaleEffect(y: 2)
        }
        .padding()
        .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct CircularProgressView: View {
    let progress: Double
    let themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(AppColors.textSecondary(isDark: themeManager.isDarkMode).opacity(0.3), lineWidth: 4)
                .frame(width: 40, height: 40)
            
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(AppColors.primary(themeManager: themeManager), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 40, height: 40)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.8), value: progress)
            
            Text("\(Int(min(progress, 1.0) * 100))%")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
        }
    }
}
