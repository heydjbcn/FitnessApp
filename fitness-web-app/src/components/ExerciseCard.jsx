function ExerciseCard({ exercise, onCompleteSet, onUndoSet }) {
  const { name, totalSets, repetitions, weight, completedSets, icon, restDuration } = exercise;

  return (
    <div className="exercise-card">
      <div className="exercise-header">
        <div className="exercise-title">
          <span className="exercise-icon">{icon || '💪'}</span>
          <div>
            <h3>{name}</h3>
            <div className="exercise-meta">
              {repetitions} reps {weight > 0 && `• ${weight}kg`}
              {restDuration && ` • ${restDuration}s descanso`}
            </div>
          </div>
        </div>
      </div>

      <div className="sets-tracker">
        <div className="sets-grid">
          {Array.from({ length: totalSets }).map((_, index) => {
            const isCompleted = index < completedSets;
            const isNext = index === completedSets;

            return (
              <button
                key={index}
                className={`set-btn ${isCompleted ? 'completed' : ''} ${isNext ? 'next' : ''}`}
                onClick={() => {
                  if (isCompleted && index === completedSets - 1) {
                    onUndoSet();
                  } else if (isNext) {
                    onCompleteSet();
                  }
                }}
                disabled={!isCompleted && !isNext}
              >
                {isCompleted ? '✓' : index + 1}
              </button>
            );
          })}
        </div>

        <div className="sets-info">
          {completedSets}/{totalSets} series completadas
        </div>
      </div>
    </div>
  );
}

export default ExerciseCard;
