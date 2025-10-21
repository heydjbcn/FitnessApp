import { useState } from 'react';
import { useLocalStorage } from './hooks/useLocalStorage';
import { getCurrentDay, DAYS } from './utils/workoutUtils';
import Header from './components/Header';
import Calendar from './components/Calendar';
import Stats from './components/Stats';
import Timer from './components/Timer';
import './App.css';

function App() {
  const [selectedDay, setSelectedDay] = useState(getCurrentDay());
  const [workouts, setWorkouts] = useLocalStorage('fitness-workouts', {});
  const [isDarkMode, setIsDarkMode] = useLocalStorage('fitness-darkMode', false);
  const [timerActive, setTimerActive] = useState(false);
  const [timerDuration, setTimerDuration] = useState(0);
  const [timerRemaining, setTimerRemaining] = useState(0);

  // Completar una serie
  const completeSet = (dayId, exerciseId) => {
    setWorkouts(prev => {
      const dayWorkouts = prev[dayId] || [];
      const updatedWorkouts = dayWorkouts.map(ex => {
        if (ex.id === exerciseId && ex.completedSets < ex.totalSets) {
          const newCompletedSets = ex.completedSets + 1;

          // Iniciar timer automáticamente si no es la última serie
          if (newCompletedSets < ex.totalSets) {
            startTimer(ex.restDuration || 90);
          }

          return { ...ex, completedSets: newCompletedSets };
        }
        return ex;
      });

      return { ...prev, [dayId]: updatedWorkouts };
    });
  };

  // Deshacer última serie
  const undoSet = (dayId, exerciseId) => {
    setWorkouts(prev => {
      const dayWorkouts = prev[dayId] || [];
      const updatedWorkouts = dayWorkouts.map(ex => {
        if (ex.id === exerciseId && ex.completedSets > 0) {
          return { ...ex, completedSets: ex.completedSets - 1 };
        }
        return ex;
      });

      return { ...prev, [dayId]: updatedWorkouts };
    });
  };

  // Iniciar timer
  const startTimer = (duration) => {
    setTimerDuration(duration);
    setTimerRemaining(duration);
    setTimerActive(true);
  };

  // Detener timer
  const stopTimer = () => {
    setTimerActive(false);
    setTimerRemaining(0);
  };

  // Agregar ejercicios de ejemplo
  const addExampleExercises = () => {
    const examples = {
      monday: [
        { id: '1', name: 'HIP THRUST MÁQUINA', totalSets: 4, repetitions: 10, weight: 65, completedSets: 0, restDuration: 90, icon: '🍑' },
        { id: '2', name: 'MÁQUINA DE ABDUCCIÓN', totalSets: 4, repetitions: 20, weight: 15, completedSets: 0, restDuration: 60, icon: '🦵' },
      ],
      wednesday: [
        { id: '3', name: 'JALÓN AL PECHO', totalSets: 4, repetitions: 12, weight: 0, completedSets: 0, restDuration: 90, icon: '💪' },
        { id: '4', name: 'REMO EN POLEA BAJA', totalSets: 4, repetitions: 10, weight: 0, completedSets: 0, restDuration: 90, icon: '🚣' },
      ],
      friday: [
        { id: '5', name: 'SENTADILLA HACK', totalSets: 4, repetitions: 8, weight: 0, completedSets: 0, restDuration: 120, icon: '🏋️' },
        { id: '6', name: 'PRENSA DE PIERNA', totalSets: 4, repetitions: 10, weight: 0, completedSets: 0, restDuration: 90, icon: '🦵' },
      ]
    };

    setWorkouts(examples);
  };

  // Resetear progreso del día
  const resetDay = (dayId) => {
    setWorkouts(prev => {
      const dayWorkouts = prev[dayId] || [];
      const resetWorkouts = dayWorkouts.map(ex => ({ ...ex, completedSets: 0 }));
      return { ...prev, [dayId]: resetWorkouts };
    });
  };

  const currentDayWorkouts = workouts[selectedDay] || [];

  return (
    <div className={`app ${isDarkMode ? 'dark' : ''}`}>
      <Header
        isDarkMode={isDarkMode}
        toggleDarkMode={() => setIsDarkMode(!isDarkMode)}
      />

      <main className="container">
        <Stats workouts={workouts} />

        <div className="day-selector">
          {DAYS.map(day => (
            <button
              key={day.id}
              className={`day-btn ${selectedDay === day.id ? 'active' : ''}`}
              onClick={() => setSelectedDay(day.id)}
            >
              <span className="day-short">{day.short}</span>
              <span className="exercise-count">
                {(workouts[day.id] || []).length}
              </span>
            </button>
          ))}
        </div>

        <Calendar
          dayId={selectedDay}
          dayName={DAYS.find(d => d.id === selectedDay)?.name}
          exercises={currentDayWorkouts}
          onCompleteSet={completeSet}
          onUndoSet={undoSet}
          onResetDay={resetDay}
        />

        {currentDayWorkouts.length === 0 && (
          <div className="empty-state">
            <div className="empty-icon">💪</div>
            <h3>No hay ejercicios para hoy</h3>
            <p>Agrega ejercicios para comenzar tu rutina</p>
            <button className="btn-primary" onClick={addExampleExercises}>
              Cargar ejercicios de ejemplo
            </button>
          </div>
        )}
      </main>

      {timerActive && (
        <Timer
          duration={timerDuration}
          remaining={timerRemaining}
          setRemaining={setTimerRemaining}
          onStop={stopTimer}
        />
      )}
    </div>
  );
}

export default App;
