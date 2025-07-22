import SwiftUI

struct NotificationsView: View {
    @StateObject private var notificationStore = NotificationStore.shared
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 10) {
                    // Título y botón cerrar
                    HStack {
                        Text("Notificaciones")
                            .font(AppFonts.title)
                            .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                        
                        Spacer()
                        
                        // Botón cerrar
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                        }
                    }
                    
                    // Contador y acciones
                    HStack {
                        // Contador de notificaciones
                        if notificationStore.unreadCount > 0 {
                            Text("\(notificationStore.unreadCount) sin leer")
                                .font(AppFonts.caption)
                                .foregroundColor(AppColors.primary)
                        } else {
                            Text("Todas leídas")
                                .font(AppFonts.caption)
                                .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                        }
                        
                        Spacer()
                        
                        // Botones de acción
                        HStack(spacing: 16) {
                            // Botón para marcar todas como leídas
                            if notificationStore.unreadCount > 0 {
                                Button("Marcar todas") {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        notificationStore.markAllAsRead()
                                    }
                                }
                                .font(AppFonts.caption.bold())
                                .foregroundColor(AppColors.primary)
                            }
                            
                            // Botón para eliminar todas las notificaciones
                            if !notificationStore.notifications.isEmpty {
                                Button("Eliminar todas") {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        notificationStore.clearAll()
                                    }
                                }
                                .font(AppFonts.caption.bold())
                                .foregroundColor(.red)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(AppColors.cardBackground(isDark: themeManager.isDarkMode))
                
                // Lista de notificaciones
                if notificationStore.notifications.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(notificationStore.notifications) { notification in
                                NotificationRow(notification: notification)
                                    .environmentObject(themeManager)
                                    .onTapGesture {
                                        if !notification.isRead {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                notificationStore.markAsRead(notification)
                                            }
                                        }
                                    }
                            }
                        }
                        .padding()
                    }
                }
                
                Spacer()
            }
            .background(AppColors.background(isDark: themeManager.isDarkMode))
        }
        .navigationBarHidden(true)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "bell.slash")
                .font(.system(size: 60))
                .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
            
            VStack(spacing: 8) {
                Text("No hay notificaciones")
                    .font(AppFonts.title)
                    .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                
                Text("Las notificaciones de entrenamientos y recordatorios aparecerán aquí")
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
    }
}

struct NotificationRow: View {
    let notification: AppNotification
    @EnvironmentObject var themeManager: ThemeManager
    
    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: notification.timestamp, relativeTo: Date())
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Icono de la notificación
            Image(systemName: notification.type.icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(colorForType(notification.type))
                .frame(width: 32, height: 32)
                .background(colorForType(notification.type).opacity(0.1))
                .cornerRadius(8)
            
            // Contenido
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(notification.title)
                        .font(AppFonts.body.weight(.semibold))
                        .foregroundColor(AppColors.textPrimary(isDark: themeManager.isDarkMode))
                    
                    Spacer()
                    
                    Text(timeAgo)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                }
                
                Text(notification.message)
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textSecondary(isDark: themeManager.isDarkMode))
                    .multilineTextAlignment(.leading)
            }
            
            // Indicador de no leída
            if !notification.isRead {
                Circle()
                    .fill(AppColors.primary)
                    .frame(width: 8, height: 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(notification.isRead ? 
                     AppColors.cardBackground(isDark: themeManager.isDarkMode) : 
                     AppColors.primary.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(notification.isRead ? 
                               Color.clear : 
                               AppColors.primary.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private func colorForType(_ type: AppNotification.NotificationType) -> Color {
        switch type {
        case .workoutReminder: return .green
        case .restTimer: return .orange
        case .achievement: return .yellow
        case .general: return .blue
        }
    }
}

#Preview {
    NotificationsView()
        .environmentObject(ThemeManager())
}
