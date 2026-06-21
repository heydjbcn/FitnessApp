# Rutina por Defecto - Documentación

## Descripción General
Se ha implementado un sistema de rutina por defecto que incluye un plan de entrenamiento de 3 días específicamente diseñado para el usuario de la aplicación FitnessApp.

## Estructura de la Rutina

### Día 1 - Lunes: Piernas & Isquios
**5 ejercicios enfocados en tren inferior**
- Sentadillas (Piernas, Fuerza, 4×15, 50kg)
- Peso Muerto Rumano (Isquios, Fuerza, 4×15, 60kg) 
- Prensa de Piernas (Piernas, Fuerza, 4×15, 80kg)
- Curl de Isquios (Isquios, Fuerza, 4×15, 30kg)
- Extensiones de Cuádriceps (Piernas, Fuerza, 4×15, 40kg)

### Día 2 - Miércoles: Espalda & Hombros
**6 ejercicios enfocados en tren superior**
- Dominadas (Espalda, Fuerza, 4×15, Peso corporal)
- Remo con Barra (Espalda, Fuerza, 4×15, 50kg)
- Press Militar (Hombros, Fuerza, 4×15, 40kg)
- Elevaciones Laterales (Hombros, Fuerza, 4×15, 15kg)
- Jalones al Pecho (Espalda, Fuerza, 4×15, 45kg)
- Face Pulls (Hombros, Fuerza, 4×15, 20kg)

### Día 3 - Viernes: Piernas Variadas
**4 ejercicios de tren inferior variados**
- Zancadas (Piernas, Fuerza, 4×15, 25kg)
- Sentadilla Búlgara (Piernas, Fuerza, 4×15, 20kg)
- Elevaciones de Gemelos (Gemelos, Fuerza, 4×15, 45kg)
- Peso Muerto Sumo (Piernas, Fuerza, 4×15, 55kg)

## Características Técnicas

### Archivos Implementados

1. **DefaultRoutineManager.swift**
   - Clase principal que gestiona la carga de la rutina por defecto
   - Métodos especializados para cada día de entrenamiento
   - Integración con Firebase para obtener ejercicios existentes

2. **Modificaciones en WorkoutViewModel.swift**
   - Auto-carga de rutina por defecto al inicializar la aplicación
   - Métodos para resetear y recargar la rutina
   - Integración fluida con el sistema existente

3. **Mejoras en SettingsView.swift**
   - Sección dedicada para gestión de rutina de entrenamiento
   - Botón para cargar/resetear rutina por defecto
   - Interfaz intuitiva para el usuario

4. **Nuevo componente DefaultRoutineInfoCard**
   - Tarjeta informativa en el dashboard principal
   - Muestra resumen de la rutina de 3 días
   - Indicadores de progreso para cada día

### Funcionalidades Clave

- **Auto-carga**: La rutina se carga automáticamente al abrir la aplicación
- **Persistencia**: La rutina se mantiene hasta que el usuario la resetee
- **Flexibilidad**: El usuario puede recargar la rutina desde configuración
- **Integración**: Compatible con el sistema de tracking existente
- **UI Mejorada**: Nueva tarjeta en dashboard para información visual

### Parámetros de Entrenamiento
- **Series**: 4 por ejercicio
- **Repeticiones**: 15 por serie
- **Pesos**: Variados según ejercicio y grupo muscular
- **Frecuencia**: 3 días por semana (Lunes, Miércoles, Viernes)
- **Duración estimada**: ~45 minutos por sesión

## Beneficios del Sistema

1. **Inmediatez**: El usuario tiene una rutina lista desde el primer uso
2. **Estructura**: Plan organizado y progresivo de entrenamiento
3. **Facilidad**: No necesita configurar nada manualmente
4. **Flexibilidad**: Puede modificar o resetear cuando desee
5. **Tracking**: Integrado con el sistema de seguimiento de progreso

## Uso para el Usuario

1. **Primera vez**: La rutina se carga automáticamente
2. **Dashboard**: Puede ver el resumen en la tarjeta informativa
3. **Calendario**: Los ejercicios aparecen en los días correspondientes
4. **Seguimiento**: Puede marcar ejercicios como completados
5. **Reset**: Desde Configuración puede recargar la rutina original

## Notas Técnicas

- Los ejercicios deben existir en Firebase para cargar correctamente
- La rutina se aplica solo a días específicos (Lunes, Miércoles, Viernes)
- Compatible con el sistema de temas oscuro/claro existente
- Integrado con el gestor de notificaciones hápticas
- Respeta el sistema de navegación de tabs existente
