import { useState } from "react";
import { useNavigate, Link } from "react-router-dom";
import { login } from "../../auth/authService.js";
import "../Styles/Login.css";

function Login() {
  const navigate = useNavigate();

  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [recordarme, setRecordarme] = useState(false);
  const [mostrarPassword, setMostrarPassword] = useState(false);
  const [error, setError] = useState("");
  const [cargando, setCargando] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError("");
    setCargando(true);

    try {
      await login(username, password);

      if (recordarme) {
        localStorage.setItem("recordar_usuario", username);
      } else {
        localStorage.removeItem("recordar_usuario");
      }

      navigate("/dashboard");
    } catch (error) {
      setError("Usuario o contraseña incorrectos.");
    } finally {
      setCargando(false);
    }
  };

  return (
    <div className="login-page">
      <div className="login-shell">
        <div className="login-card">
          <div className="login-left">
            <div className="login-left-content">
              <span className="login-badge">Bienvenido</span>

              <h1>Administra, controla y optimiza cada paso del camino.</h1>

              <p>
                Gestiona peajes, cámaras, vehículos, alertas, membresías y
                reportes desde un solo panel administrativo inteligente.
              </p>

              <div className="login-illustration">
                <div className="scene">
                  <div className="scene-cloud cloud-1"></div>
                  <div className="scene-cloud cloud-2"></div>
                  <div className="scene-hill hill-1"></div>
                  <div className="scene-hill hill-2"></div>
                  <div className="scene-road"></div>
                  <div className="scene-booth">
                    <div className="booth-roof"></div>
                    <div className="booth-body"></div>
                    <div className="barrier-post"></div>
                    <div className="barrier-arm"></div>
                  </div>
                  <div className="scene-car">
                    <div className="car-top"></div>
                    <div className="car-body"></div>
                    <div className="car-wheel wheel-left"></div>
                    <div className="car-wheel wheel-right"></div>
                  </div>
                </div>
              </div>

              <div className="login-feature-grid">
                <div className="feature-card">
                  <div className="feature-icon">🚗</div>
                  <span>Gestión de vehículos</span>
                </div>

                <div className="feature-card">
                  <div className="feature-icon">💳</div>
                  <span>Pagos automatizados</span>
                </div>

                <div className="feature-card">
                  <div className="feature-icon">📊</div>
                  <span>Reportes inteligentes</span>
                </div>
              </div>
            </div>
          </div>

          <div className="login-right">
            <div className="login-form-panel">
              <div className="login-brand">
                <div className="login-logo">🛣️</div>
                <h2>Sistema de Peaje</h2>
                <span>Panel Administrativo</span>
              </div>

              <form onSubmit={handleSubmit} className="login-form">
                <div className="form-group">
                  <label>Usuario</label>
                  <div className="input-wrapper">
                    <span className="input-icon">👤</span>
                    <input
                      type="text"
                      value={username}
                      onChange={(e) => setUsername(e.target.value)}
                      placeholder="Ingresa tu usuario"
                      required
                    />
                  </div>
                </div>

                <div className="form-group">
                  <label>Contraseña</label>
                  <div className="input-wrapper">
                    <span className="input-icon">🔒</span>
                    <input
                      type={mostrarPassword ? "text" : "password"}
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      placeholder="Ingresa tu contraseña"
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
                  <label className="checkbox-row">
                    <input
                      type="checkbox"
                      checked={recordarme}
                      onChange={(e) => setRecordarme(e.target.checked)}
                    />
                    <span>Recordarme</span>
                  </label>

                  <Link to="/forgot-password" className="forgot-link">
                    ¿Olvidaste tu contraseña?
                  </Link>
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
    </div>
  );
}

export default Login;