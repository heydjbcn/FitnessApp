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
    @State private var profileImage: UIImage?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Imagen de perfil
                    VStack(spacing: 16) {
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            ZStack {
                                Circle()
                                    .fill(themeManager.selectedAccentColor.color)
                                    .frame(width: 120, height: 120)
                                
                                if let profileImage = profileImage {
                                    Image(uiImage: profileImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                } else if let imageData = userManager.profileImageData,
                                          let uiImage = UIImage(data: imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.white)
                                }
                                
                                // Overlay para editar
                                Circle()
                                    .fill(Color.black.opacity(0.3))
                                    .frame(width: 120, height: 120)
                                    .overlay(
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.white)
                                    )
                            }
                        }
                        
                        Text("Toca para cambiar foto")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                    }
                    
                    // Formulario
                    VStack(spacing: 20) {
                        // Nombre
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Nombre")
                                .font(AppFonts.body)
                                .fontWeight(.medium)
                                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                            
                            TextField("Ingresa tu nombre", text: $name)
                                .textFieldStyle(CustomTextFieldStyle(themeManager: themeManager))
                        }
                        
                        // Edad
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Edad")
                                .font(AppFonts.body)
                                .fontWeight(.medium)
                                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                            
                            TextField("Años", text: $age)
                                .keyboardType(.numberPad)
                                .textFieldStyle(CustomTextFieldStyle(themeManager: themeManager))
                        }
                        
                        // Altura
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Altura")
                                .font(AppFonts.body)
                                .fontWeight(.medium)
                                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                            
                            TextField("cm", text: $height)
                                .keyboardType(.numberPad)
                                .textFieldStyle(CustomTextFieldStyle(themeManager: themeManager))
                        }
                        
                        // Peso
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Peso")
                                .font(AppFonts.body)
                                .fontWeight(.medium)
                                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                            
                            TextField("kg", text: $weight)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(CustomTextFieldStyle(themeManager: themeManager))
                        }
                    }
                    
                    // IMC Preview si hay datos
                    if !height.isEmpty && !weight.isEmpty,
                       let heightValue = Double(height),
                       let weightValue = Double(weight),
                       heightValue > 0 {
                        let bmi = weightValue / pow(heightValue / 100, 2)
                        
                        VStack(spacing: 8) {
                            Text("Índice de Masa Corporal")
                                .font(AppFonts.body)
                                .fontWeight(.medium)
                                .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                            
                            Text(String(format: "%.1f", bmi))
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(AppColors.primary(themeManager: themeManager))
                            
                            Text(bmiCategory(for: bmi))
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
                        .cornerRadius(12)
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(AppColors.background(isDark: themeManager.isDarkMode))
            .navigationTitle("Editar Perfil")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") {
                        saveProfile()
                    }
                    .foregroundColor(AppColors.primary(themeManager: themeManager))
                    .fontWeight(.medium)
                }
            }
        }
        .onAppear {
            loadCurrentData()
        }
        .onChange(of: selectedPhoto) { _, newPhoto in
            Task {
                if let data = try? await newPhoto?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    profileImage = image
                }
            }
        }
        .simultaneousGesture(
            TapGesture().onEnded { _ in
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        )
    }
    
    private func loadCurrentData() {
        name = userManager.userName
        age = userManager.userAge
        height = userManager.userHeight
        weight = userManager.userWeight
    }
    
    private func saveProfile() {
        var imageData: Data? = nil
        if let profileImage = profileImage {
            imageData = profileImage.jpegData(compressionQuality: 0.8)
        }
        
        userManager.saveUserProfile(
            name: name,
            age: age,
            height: height,
            weight: weight,
            imageData: imageData
        )
        
        dismiss()
    }
    
    private func bmiCategory(for bmi: Double) -> String {
        switch bmi {
        case ..<18.5:
            return "Bajo peso"
        case 18.5..<25:
            return "Peso normal"
        case 25..<30:
            return "Sobrepeso"
        default:
            return "Obesidad"
        }
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    let themeManager: ThemeManager
    
    @MainActor
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.textSecondary(isDark: themeManager.isDarkMode).opacity(0.2), lineWidth: 1)
            )
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
