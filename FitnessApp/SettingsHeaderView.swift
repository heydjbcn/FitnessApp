import SwiftUI

struct SettingsHeaderView: View {
    // Usamos @Binding para que la vista pueda cambiar el estado de la vista padre
    @Binding var showingNotifications: Bool
    
    // El NotificationStore lo podemos observar directamente aquí
    @StateObject private var notificationStore = NotificationStore.shared
    
    // El ThemeManager y el dismiss los recibimos del entorno
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        HStack {
            // Campanita de notificaciones
            Button(action: { showingNotifications = true }) {
                ZStack {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                    
                    // Badge rojo con número de notificaciones
                    if notificationStore.unreadCount > 0 {
                        Text("\(notificationStore.unreadCount)")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(.white)
                            .frame(minWidth: 16, minHeight: 16)
                            .background(Circle().fill(Color.red))
                            .offset(x: 10, y: -10)
                    }
                }
            }
            
            Spacer()
            
            // Botón X para cerrar
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 25)  // Incrementado el padding superior
        .padding(.bottom, 10)
    }
}

#Preview {
    SettingsHeaderView(showingNotifications: .constant(false))
        .environmentObject(ThemeManager())
}
