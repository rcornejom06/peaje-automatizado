import { NavLink, Outlet, useLocation, useNavigate } from "react-router-dom";
import { logout } from "../auth/authService";
import "../layouts/styles/AdminLayout.css";

const menuItems = [
  {
    to: "/dashboard",
    label: "Dashboard",
    icon: "📊",
  },
  {
    to: "/peajes",
    label: "Peajes",
    icon: "🛣️",
  },
  {
    to: "/camaras",
    label: "Cámaras",
    icon: "📷",
  },
  {
    to: "/vehiculos",
    label: "Vehículos",
    icon: "🚗",
  },
  {
    to: "/reconocimiento-placas",
    label: "Reconocimiento LPR",
    icon: "🔎",
  },
  {
    to: "/alertas",
    label: "Alertas",
    icon: "🚨",
  },
  {
    to: "/membresias",
    label: "Membresías",
    icon: "🎫",
  },
  {
    to: "/reportes",
    label: "Reportes",
    icon: "📈",
  },
  {
    to: "/usuarios",
    label: "Usuarios",
    icon: "👤",
  },
  {
    to: "/auditoria",
    label: "Auditoría",
    icon: "🧾",
  },
];

const pageTitles = {
  "/dashboard": "Dashboard",
  "/peajes": "Gestión de peajes",
  "/camaras": "Gestión de cámaras",
  "/vehiculos": "Vehículos registrados",
  "/reconocimiento-placas": "Reconocimiento de placas",
  "/alertas": "Alertas de seguridad",
  "/membresias": "Membresías y paquetes",
  "/reportes": "Reportes del sistema",
  "/usuarios": "Usuarios",
  "/auditoria": "Auditoría",
};

function AdminLayout() {
  const navigate = useNavigate();
  const location = useLocation();

  const handleLogout = () => {
    logout();
    navigate("/");
  };

  const tituloActual = pageTitles[location.pathname] || "Panel administrativo";

  return (
    <div className="admin-layout">
      <aside className="sidebar">
        <div className="sidebar-brand">
          <div className="sidebar-logo">P</div>

          <div>
            <h2>Peaje Smart</h2>
            <span>Admin Panel</span>
          </div>
        </div>

        <nav className="sidebar-nav">
          {menuItems.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              className={({ isActive }) =>
                isActive ? "sidebar-link active" : "sidebar-link"
              }
            >
              <span className="sidebar-icon">{item.icon}</span>
              <span>{item.label}</span>
            </NavLink>
          ))}
        </nav>

        <div className="sidebar-footer">
          <div className="sidebar-user">
            <div className="sidebar-user-avatar">A</div>
            <div>
              <strong>Administrador</strong>
              <span>Sistema de peaje</span>
            </div>
          </div>

          <button className="logout-button" onClick={handleLogout}>
            Cerrar sesión
          </button>
        </div>
      </aside>

      <main className="main-content">
        <header className="topbar">
          <div>
            <h1>{tituloActual}</h1>
            <p>Sistema Inteligente de Peaje Automatizado</p>
          </div>

          <div className="topbar-status">
            <span className="status-dot"></span>
            Sistema activo
          </div>
        </header>

        <section className="content">
          <Outlet />
        </section>
      </main>
    </div>
  );
}

export default AdminLayout;