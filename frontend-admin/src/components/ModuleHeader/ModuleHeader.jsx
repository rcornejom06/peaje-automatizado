import "../ModuleHeader/Moduleeader.css"

function ModuleHeader({
  icon = "🧭",
  title = "Módulo",
  subtitle = "Sistema Inteligente de Peaje Automatizado",
  badge = "VíaSmart",
  status = "Activo",
  actions,
}) {
  return (
    <header className="module-header">
      <div className="module-header-bg-circle one"></div>
      <div className="module-header-bg-circle two"></div>

      <div className="module-header-left">
        <div className="module-header-icon">{icon}</div>

        <div>
          <span className="module-header-kicker">{badge}</span>
          <h2>{title}</h2>
          <p>{subtitle}</p>
        </div>
      </div>

      <div className="module-header-right">
        <div className="module-header-status">
          <span></span>
          {status}
        </div>

        {actions && <div className="module-header-actions">{actions}</div>}
      </div>
    </header>
  );
}

export default ModuleHeader;