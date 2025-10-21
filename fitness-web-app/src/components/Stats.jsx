import { calculateWeeklyProgress } from '../utils/workoutUtils';

function Stats({ workouts }) {
  const progress = calculateWeeklyProgress(workouts);

  // Calcular total de series completadas
  const totalCompletedSets = Object.values(workouts).reduce((sum, dayWorkouts) => {
    return sum + dayWorkouts.reduce((daySum, ex) => daySum + ex.completedSets, 0);
  }, 0);

  // Calcular total de series
  const totalSets = Object.values(workouts).reduce((sum, dayWorkouts) => {
    return sum + dayWorkouts.reduce((daySum, ex) => daySum + ex.totalSets, 0);
  }, 0);

  return (
    <div className="stats-card">
      <div className="stat">
        <div className="stat-icon">📊</div>
        <div className="stat-content">
          <div className="stat-label">Progreso Semanal</div>
          <div className="stat-value">{progress}%</div>
        </div>
      </div>

      <div className="stat">
        <div className="stat-icon">🎯</div>
        <div className="stat-content">
          <div className="stat-label">Series</div>
          <div className="stat-value">{totalCompletedSets}/{totalSets}</div>
        </div>
      </div>
    </div>
  );
}

export default Stats;
