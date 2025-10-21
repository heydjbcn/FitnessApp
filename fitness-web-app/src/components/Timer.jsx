import { useEffect } from 'react';

function Timer({ duration, remaining, setRemaining, onStop }) {
  useEffect(() => {
    if (remaining <= 0) {
      // Timer completado
      onStop();

      // Vibración si está disponible
      if ('vibrate' in navigator) {
        navigator.vibrate([200, 100, 200]);
      }

      // Notificación de audio
      const audio = new Audio('data:audio/wav;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACBhYqFbF1fdJivrJBhNjVgodDbq2EcBj+a2/LDciUFLIHO8tiJNwgZaLvt559NEAxQp+PwtmMcBjiR1/LMeSwFJHfH8N2QQAoUXrTp66hVFApGn+DyvmwhBixx0PLRglgOEWG049qcVRIJQ'
        );
      audio.play().catch(() => {});

      return;
    }

    const interval = setInterval(() => {
      setRemaining(prev => prev - 1);
    }, 1000);

    return () => clearInterval(interval);
  }, [remaining, onStop, setRemaining]);

  const minutes = Math.floor(remaining / 60);
  const seconds = remaining % 60;
  const progress = ((duration - remaining) / duration) * 100;

  return (
    <div className="timer-overlay" onClick={onStop}>
      <div className="timer-modal" onClick={(e) => e.stopPropagation()}>
        <div className="timer-content">
          <div className="timer-circle">
            <svg viewBox="0 0 100 100">
              <circle
                cx="50"
                cy="50"
                r="45"
                fill="none"
                stroke="var(--color-bg-secondary)"
                strokeWidth="8"
              />
              <circle
                cx="50"
                cy="50"
                r="45"
                fill="none"
                stroke="var(--color-primary)"
                strokeWidth="8"
                strokeDasharray={`${2 * Math.PI * 45}`}
                strokeDashoffset={`${2 * Math.PI * 45 * (1 - progress / 100)}`}
                transform="rotate(-90 50 50)"
                strokeLinecap="round"
              />
            </svg>
            <div className="timer-time">
              {String(minutes).padStart(2, '0')}:{String(seconds).padStart(2, '0')}
            </div>
          </div>

          <div className="timer-label">Descanso</div>

          <button className="btn-stop-timer" onClick={onStop}>
            Detener
          </button>
        </div>
      </div>
    </div>
  );
}

export default Timer;
