function Header({ isDarkMode, toggleDarkMode }) {
  return (
    <header className="header">
      <div className="container">
        <h1 className="logo">💪 Fitness App</h1>
        <button className="theme-toggle" onClick={toggleDarkMode} aria-label="Cambiar tema">
          {isDarkMode ? '☀️' : '🌙'}
        </button>
      </div>
    </header>
  );
}

export default Header;
