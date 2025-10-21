import { calculateDayProgress } from '../utils/workoutUtils';
import ExerciseCard from './ExerciseCard';

function Calendar({ dayId, dayName, exercises, onCompleteSet, onUndoSet, onResetDay }) {
  const progress = calculateDayProgress(exercises);

  return (
    <div className="calendar">
      <div className="calendar-header">
        <div className="calendar-title">
          <h2>{dayName}</h2>
          <div className="progress-info">
            {exercises.length > 0 && (
              <>
                <span className="progress-text">{Math.round(progress)}% completado</span>
                <div className="progress-bar">
                  <div className="progress-fill" style={{ width: `${progress}%` }}></div>
                </div>
              </>
            )}
          </div>
        </div>

        {exercises.length > 0 && (
          <button className="btn-reset" onClick={() => onResetDay(dayId)}>
            🔄 Resetear
          </button>
        )}
      </div>

      <div className="exercises-list">
        {exercises.map(exercise => (
          <ExerciseCard
            key={exercise.id}
            exercise={exercise}
            onCompleteSet={() => onCompleteSet(dayId, exercise.id)}
            onUndoSet={() => onUndoSet(dayId, exercise.id)}
          />
        ))}
      </div>
    </div>
  );
}

export default Calendar;
