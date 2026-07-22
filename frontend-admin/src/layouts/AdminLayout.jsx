import {useMemo, useState} from "react";
import {NavLink, Outlet, useLocation, useNavigate} from "react-router-dom";
import {getStoredProfile, logout} from "../auth/authService";
import "../layouts/styles/AdminLayout.css";
import NotificationBell from "../components/NotificationBell/NotificationBell.jsx";

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

    const perfilAdmin = useMemo(() => getStoredProfile(), []);
    const tituloActual = pageTitles[location.pathname] || "Panel administrativo";
    const nombreAdmin =
        perfilAdmin?.usuario_username ||
        perfilAdmin?.usuario?.username ||
        perfilAdmin?.username ||
        "Administrador";
    const rolAdmin = perfilAdmin?.rol || perfilAdmin?.perfil?.rol || "VíaSmart";

    const [sidebarOculto, setSidebarOculto] = useState(false);
    const [sidebarMovilAbierto, setSidebarMovilAbierto] = useState(false);

    const handleLogout = () => {
        logout();
        navigate("/");
    };

    const cerrarMenuMovil = () => {
        setSidebarMovilAbierto(false);
    };

    const handleMenuButton = () => {
        const esMovil = window.matchMedia("(max-width: 900px)").matches;

        if (esMovil) {
            setSidebarMovilAbierto((actual) => !actual);
            return;
        }

        setSidebarOculto((actual) => !actual);
    };

    return (
        <div
            className={`admin-layout ${sidebarOculto ? "sidebar-collapsed" : ""} ${
                sidebarMovilAbierto ? "mobile-sidebar-open" : ""
            }`}
        >
            <button
                className="mobile-menu-button"
                type="button"
                onClick={handleMenuButton}
                aria-label={sidebarOculto ? "Expandir menú" : "Contraer menú"}
                title={sidebarOculto ? "Expandir menú" : "Contraer menú"}
            >
                ☰
            </button>

            <aside className="sidebar">
                <div className="sidebar-brand">
                    <div className="sidebar-logo">V</div>

                    <div className="sidebar-brand-text">
                        <h2>VíaSmart</h2>
                        <span>Admin Panel</span>
                    </div>

                    <button
                        className="sidebar-mobile-close"
                        type="button"
                        onClick={cerrarMenuMovil}
                        aria-label="Cerrar menú"
                    >
                        ×
                    </button>
                </div>
                <div className="admin-floating-notification">
                    <NotificationBell/>
                </div>

                <nav className="sidebar-nav">
                    {menuItems.map((item) => (
                        <NavLink
                            key={item.to}
                            to={item.to}
                            onClick={cerrarMenuMovil}
                            className={({isActive}) =>
                                isActive ? "sidebar-link active" : "sidebar-link"
                            }
                            title={sidebarOculto ? item.label : ""}
                        >
                            <span className="sidebar-icon">{item.icon}</span>
                            <span className="sidebar-label">{item.label}</span>
                        </NavLink>
                    ))}
                </nav>

                <div className="sidebar-footer">
                    <div className="sidebar-user">
                        <div className="sidebar-user-avatar">A</div>

                        <div className="sidebar-user-info">
                            <strong>{nombreAdmin}</strong>
                            <span>{rolAdmin}</span>
                        </div>
                    </div>

                    <button className="logout-button" onClick={handleLogout}>
                        <span className="logout-icon">⏻</span>
                        <span className="logout-text">Cerrar sesión</span>
                    </button>
                </div>
            </aside>

            <div className="sidebar-overlay" onClick={cerrarMenuMovil}></div>

            <main className="main-content">
                <section className="content">
                    <div className="admin-current-page" aria-label="Página actual">
                        {tituloActual}
                    </div>
                    <Outlet/>
                </section>
            </main>
        </div>
    );
}

export default AdminLayout;