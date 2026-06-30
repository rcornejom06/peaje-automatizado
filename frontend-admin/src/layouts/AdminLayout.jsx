import {NavLink, Outlet, useNavigate} from "react-router-dom";
import {logout} from "../auth/authService";
import "../layouts/styles/AdminLayout.css";

function AdminLayout() {
    const navigate = useNavigate();

    const handleLogout = () => {
        logout();
        navigate("/");
    };

    return (
        <div className="admin-layout">
            <aside className="sidebar">
                <div className="sidebar-header">
                    <h2>Peaje</h2>
                    <span>Admin Panel</span>
                </div>

                <nav className="sidebar-nav">
                    <NavLink to="/dashboard">Dashboard</NavLink>
                    <NavLink to="/peajes">Peajes</NavLink>
                    <NavLink to="/camaras">Cámaras</NavLink>
                    <NavLink to="/vehiculos">Vehículos</NavLink>
                    <NavLink to="/alertas">Alertas</NavLink>
                    <NavLink to="/membresias">Membresías</NavLink>
                    <NavLink to="/reportes">Reportes</NavLink>
                    <NavLink to="/usuarios">Usuarios</NavLink>
                    <NavLink to="/reconocimiento-placas">Reconocimiento LPR</NavLink>
                    <NavLink to="/auditoria"> Auditoria </NavLink>
                    <NavLink
                        to="/vehiculos/revision"
                        className={({isActive}) =>
                            isActive
                                ? "bg-blue-600 text-white px-4 py-2 rounded-lg block"
                                : "text-gray-700 hover:bg-gray-100 px-4 py-2 rounded-lg block"
                        }
                    >
                        Revisión de vehículos
                    </NavLink>
                </nav>

                <button className="logout-button" onClick={handleLogout}>
                    Cerrar sesión
                </button>
            </aside>

            <main className="main-content">
                <header className="topbar">
                    <h1>Sistema Inteligente de Peaje</h1>
                </header>

                <section className="content">
                    <Outlet/>
                </section>
            </main>
        </div>
    );
}

export default AdminLayout;