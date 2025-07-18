import SwiftUI
import PhotosUI

struct ProfileEditView: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var age: String = ""
    @State private var height: String = ""
    @State private var weight: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImage: Image?
    @State private var profileImageData: Data?
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background(isDark: themeManager.isDarkMode).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Foto de perfil
                        VStack(spacing: 16) {
                            if let profileImage = profileImage {
                                profileImage
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(AppColors.primary, lineWidth: 3))
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 120))
                                    .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                            }
                            
                            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                Text("Cambiar foto")
                                    .font(AppFonts.caption)
                                    .foregroundColor(AppColors.primary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
                                    .cornerRadius(16)
                            }
                        }
                        .padding(.top, 20)
                        
                        // Formulario
                        VStack(spacing: 20) {
                            // Nombre
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Nombre")
                                    .font(AppFonts.caption)
                                    .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                                
                                TextField("Tu nombre", text: $name)
                                    .font(AppFonts.body)
                                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                                    .padding()
                                    .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
                                    .cornerRadius(12)
                            }
                            
                            // Edad
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Edad")
                                    .font(AppFonts.caption)
                                    .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                                
                                TextField("Años", text: $age)
                                    .font(AppFonts.body)
                                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                                    .keyboardType(.numberPad)
                                    .padding()
                                    .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
                                    .cornerRadius(12)
                            }
                            
                            // Altura
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Altura")
                                    .font(AppFonts.caption)
                                    .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                                
                                TextField("cm", text: $height)
                                    .font(AppFonts.body)
                                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                                    .keyboardType(.numberPad)
                                    .padding()
                                    .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
                                    .cornerRadius(12)
                            }
                            
                            // Peso
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Peso")
                                    .font(AppFonts.caption)
                                    .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                                
                                TextField("kg", text: $weight)
                                    .font(AppFonts.body)
                                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                                    .keyboardType(.decimalPad)
                                    .padding()
                                    .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Botón Guardar
                        Button(action: saveProfile) {
                            Text("Guardar cambios")
                                .font(AppFonts.body)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppColors.primary)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Editar Perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.primary)
                }
            }
        }
        .onAppear {
            loadCurrentData()
        }
        .onChange(of: selectedPhoto) { oldValue, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    profileImage = Image(uiImage: uiImage)
                    profileImageData = data
                }
            }
        }
    }
    
    private func loadCurrentData() {
        name = userManager.userName
        age = userManager.userAge
        height = userManager.userHeight  
        weight = userManager.userWeight
        
        // Cargar la imagen actual si existe
        if let imageData = userManager.profileImageData,
           let uiImage = UIImage(data: imageData) {
            profileImage = Image(uiImage: uiImage)
            profileImageData = imageData
        }
    }
    
    private func saveProfile() {
        userManager.saveUserProfile(
            name: name, 
            age: age, 
            height: height, 
            weight: weight,
            imageData: profileImageData
        )
        dismiss()
    }
}

#Preview {
    ProfileEditView()
        .environmentObject(UserManager())
        .environmentObject(ThemeManager())
}
