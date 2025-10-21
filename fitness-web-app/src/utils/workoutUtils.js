// Días de la semana
export const DAYS = [
  { id: 'monday', name: 'Lunes', short: 'Lun' },
  { id: 'tuesday', name: 'Martes', short: 'Mar' },
  { id: 'wednesday', name: 'Miércoles', short: 'Mié' },
  { id: 'thursday', name: 'Jueves', short: 'Jue' },
  { id: 'friday', name: 'Viernes', short: 'Vie' },
  { id: 'saturday', name: 'Sábado', short: 'Sáb' },
  { id: 'sunday', name: 'Domingo', short: 'Dom' }
];

// Obtener el día actual
export function getCurrentDay() {
  const dayIndex = new Date().getDay();
  // getDay() devuelve 0-6 (domingo-sábado), ajustamos para lunes-domingo
  const adjusted = dayIndex === 0 ? 6 : dayIndex - 1;
  return DAYS[adjusted].id;
}

// Generar ID único
export function generateId() {
  return Date.now().toString(36) + Math.random().toString(36).substr(2);
}

// Calcular progreso de un día
export function calculateDayProgress(exercises) {
  if (!exercises || exercises.length === 0) return 0;

  const totalSets = exercises.reduce((sum, ex) => sum + ex.totalSets, 0);
  const completedSets = exercises.reduce((sum, ex) => sum + ex.completedSets, 0);

  return totalSets > 0 ? (completedSets / totalSets) * 100 : 0;
}

// Calcular progreso semanal
export function calculateWeeklyProgress(workouts) {
  let totalSets = 0;
  let completedSets = 0;

  Object.values(workouts).forEach(dayWorkouts => {
    dayWorkouts.forEach(exercise => {
      totalSets += exercise.totalSets;
      completedSets += exercise.completedSets;
    });
  });

  return totalSets > 0 ? Math.round((completedSets / totalSets) * 100) : 0;
}
