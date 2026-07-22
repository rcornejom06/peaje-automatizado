import {useState} from "react";
import {useNavigate} from "react-router-dom";
import {login} from "../../auth/authService.js";
import "../Styles/Login.css";

function Login() {
    const navigate = useNavigate();

    const [username, setUsername] = useState("");
    const [password, setPassword] = useState("");
    const [mostrarPassword, setMostrarPassword] = useState(false);
    const [recordarme, setRecordarme] = useState(false);
    const [error, setError] = useState("");
    const [cargando, setCargando] = useState(false);

    const handleSubmit = async (e) => {
        e.preventDefault();

        setError("");
        setCargando(true);

        try {
            await login(username, password);

            if (localStorage.getItem("requiere_cambio_password") === "true") {
                navigate("/cambiar-password-inicial");
                return;
            }

            navigate("/dashboard");
        } catch (error) {
            if (error.code === "correo_no_verificado") {
                navigate(
                    `/verificar-correo-operador?email=${encodeURIComponent(error.email || "")}`
                );
                return;
            }

        setError(
            error.message ||
            error.response?.data?.detail ||
            error.response?.data?.error ||
            "Usuario o contraseña incorrectos."
        );
    }
finally
    {
        setCargando(false);
    }
};

return (
    <div className="login-page">
        <div className="login-wrapper">
            <div className="login-left">
                <div className="login-left-content">
                    <span className="login-badge">Bienvenido</span>

                    <h1>Administra y controla tu sistema de peaje</h1>

                    <p>
                        Gestiona vehículos, monitorea accesos, revisa reportes y mantén
                        el control de cada paso del camino desde un solo lugar.
                    </p>

                    <div className="login-features">
                        <div className="feature-card">
                            <div className="feature-icon">🚗</div>
                            <h3>Gestión de vehículos</h3>
                            <p>Control centralizado de vehículos registrados.</p>
                        </div>

                        <div className="feature-card">
                            <div className="feature-icon">💳</div>
                            <h3>Pagos automatizados</h3>
                            <p>Cobros ágiles y seguimiento de transacciones.</p>
                        </div>

                        <div className="feature-card">
                            <div className="feature-icon">📊</div>
                            <h3>Reportes inteligentes</h3>
                            <p>Consulta indicadores y métricas del sistema.</p>
                        </div>
                    </div>
                </div>
            </div>

            <div className="login-right">
                <div className="login-card">
                    <div className="login-brand">
                        <div className="login-logo">🛣️</div>
                        <h2>Sistema de Peaje</h2>
                        <p>Panel Administrativo</p>
                    </div>

                    <form onSubmit={handleSubmit} className="login-form">
                        <div className="form-group">
                            <label htmlFor="username">Usuario</label>
                            <div className="input-with-icon">
                                <input
                                    id="username"
                                    type="text"
                                    value={username}
                                    onChange={(e) => setUsername(e.target.value)}
                                    placeholder="Ingresa tu usuario"
                                    autoComplete="username"
                                    required
                                />
                            </div>
                        </div>

                        <div className="form-group">
                            <label htmlFor="password">Contraseña</label>
                            <div className="input-with-icon">
                                <input
                                    id="password"
                                    type={mostrarPassword ? "text" : "password"}
                                    value={password}
                                    onChange={(e) => setPassword(e.target.value)}
                                    placeholder="Ingresa tu contraseña"
                                    autoComplete="current-password"
                                    required
                                />
                                <button
                                    type="button"
                                    className="toggle-password"
                                    onClick={() => setMostrarPassword(!mostrarPassword)}
                                >
                                    {mostrarPassword ? "🙈" : "👁️"}
                                </button>
                            </div>
                        </div>

                        <div className="login-options">
                            <label className="remember-me">
                                <input
                                    type="checkbox"
                                    checked={recordarme}
                                    onChange={(e) => setRecordarme(e.target.checked)}
                                />
                                <span>Recordarme</span>
                            </label>

                            <button
                                type="button"
                                className="forgot-link"
                                onClick={() => navigate("/forgot-password")}
                            >
                                ¿Olvidaste tu contraseña?
                            </button>
                        </div>

                        {error && <div className="error-message">{error}</div>}

                        <button type="submit" className="login-button" disabled={cargando}>
                            {cargando ? "Ingresando..." : "Iniciar sesión"}
                        </button>
                    </form>
                </div>
            </div>
        </div>
    </div>
);
}

export default Login;