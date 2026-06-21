# AppFit — Apple Watch app (pasos en Xcode)

El código del reloj ya está en esta carpeta (`WatchApp/`). Solo falta crear el
**target watchOS** en Xcode y añadirle estos archivos. ~5 minutos.

## Archivos ya listos
- `WatchApp/AppFitWatchApp.swift` — entrada de la app del reloj.
- `WatchApp/WatchHomeView.swift` — rutina del día + marcar series.
- `WatchApp/WatchConnectivityManager.swift` — sincronización con el iPhone.
- Lado iPhone ya integrado en el target principal: `PhoneConnectivity.swift`
  (se activa solo y envía la rutina del día al reloj; recibe "completar serie").

## Pasos en Xcode
1. Abre `FitnessApp.xcodeproj`.
2. **File ▸ New ▸ Target… ▸ watchOS ▸ Watch App** (para una app de iOS existente).
   - Product Name: `AppFit Watch`
   - Interface: **SwiftUI**, Language: **Swift**
   - Marca que va asociada a la app `FitnessApp`.
3. Xcode crea un target con su `…App.swift` y un `ContentView`. **Borra** esos
   archivos generados (o su contenido) para no duplicar el `@main`.
4. **Arrastra** los 3 archivos `.swift` de `WatchApp/` al nuevo target del Watch
   (al añadirlos, marca **Target Membership = AppFit Watch**, NO el target iOS).
5. **HealthKit (frecuencia cardíaca, opcional):** en el target del Watch ▸
   Signing & Capabilities ▸ + Capability ▸ **HealthKit**. (La lectura de pulso
   se puede añadir luego; esta v1 muestra rutina y registro de series.)
6. **WatchConnectivity** no necesita capability; funciona al activar `WCSession`
   en ambos lados (ya está en el código).
7. Selecciona el scheme del Watch y **ejecuta** en el Apple Watch Series 11
   emparejado (o en el simulador de Watch).

## Cómo funciona
- Al abrir AppFit en el iPhone, este envía la **rutina del día** al reloj
  (`updateApplicationContext`).
- En el reloj ves la lista de ejercicios con sus series; pulsa **"+"** para
  marcar una serie → el iPhone la registra (`completeSet`) y reenvía el estado.

## Notas
- Si el reloj muestra "Abre AppFit en el iPhone para sincronizar": abre la app
  del iPhone una vez para que envíe el contexto.
- Modelos compartidos: el reloj usa structs propios (`WatchExercise`) y se
  comunica por diccionarios, así que **no** necesitas compartir `Exercise`/
  `WorkoutExercise` con el target del Watch.
