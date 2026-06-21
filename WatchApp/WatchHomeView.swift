//
//  WatchHomeView.swift
//  AppFit Watch App (target watchOS)
//
//  Rutina del día: lista de ejercicios con su progreso de series; tocar
//  "+" marca una serie (se sincroniza con el iPhone).
//

import SwiftUI

struct WatchHomeView: View {
    @EnvironmentObject var sync: WatchConnectivityManager

    private let lime = Color(red: 0xC6/255, green: 0xF5/255, blue: 0x42/255)

    var body: some View {
        NavigationStack {
            if sync.exercises.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "dumbbell.fill").foregroundColor(lime)
                    Text("Abre AppFit en el iPhone para sincronizar tu rutina")
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                .padding()
                .navigationTitle("AppFit")
            } else {
                List {
                    ForEach(sync.exercises) { ex in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(ex.name).font(.headline).lineLimit(2)
                            HStack {
                                Text("\(ex.completed)/\(ex.totalSets) series")
                                    .font(.caption2).foregroundColor(.secondary)
                                Spacer()
                                Text("\(Int(ex.weight)) kg · \(ex.reps) reps")
                                    .font(.caption2).foregroundColor(.secondary)
                            }
                            // Indicadores de serie
                            HStack(spacing: 4) {
                                ForEach(0..<max(ex.totalSets, 0), id: \.self) { i in
                                    Circle()
                                        .fill(i < ex.completed ? lime : Color.gray.opacity(0.4))
                                        .frame(width: 10, height: 10)
                                }
                                Spacer()
                                Button {
                                    sync.completeSet(ex.id)
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.black)
                                        .frame(width: 28, height: 28)
                                        .background(Circle().fill(lime))
                                }
                                .buttonStyle(.plain)
                                .disabled(ex.completed >= ex.totalSets)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
                .navigationTitle(sync.dayName.isEmpty ? "Hoy" : sync.dayName)
            }
        }
    }
}
