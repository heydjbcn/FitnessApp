import SwiftUI

struct SettingsHeaderView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userManager: UserManager
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar del usuario
            ZStack {
                Circle()
                    .fill(AppColors.primary(themeManager: themeManager).opacity(0.1))
                    .frame(width: 60, height: 60)
                
                if let profileImageData = userManager.profileImageData,
                   let profileImage = UIImage(data: profileImageData) {
                    Image(uiImage: profileImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.fill")
                        .font(.title2)
                        .foregroundColor(AppColors.primary(themeManager: themeManager))
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Hola, \(userManager.userName.isEmpty ? "Usuario" : userManager.userName)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                
                Text("Configuración de la app")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
        .cornerRadius(16)
    }
}
