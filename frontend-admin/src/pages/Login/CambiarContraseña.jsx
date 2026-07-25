import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { cambiarPasswordInicial, logout } from "../../auth/authService";
import "../Styles/Login.css";

function CambiarPasswordInicial() {
  const navigate = useNavigate();

  const [passwordActual, setPasswordActual] = useState("");
  const [nuevaPassword, setNuevaPassword] = useState("");
  const [confirmarPassword, setConfirmarPassword] = useState("");
  const [error, setError] = useState("");
  const [mensaje, setMensaje] = useState("");
  const [cargando, setCargando] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();

    setError("");
    setMensaje("");

    if (nuevaPassword !== confirmarPassword) {
      setError("Las contraseñas no coinciden.");
      return;
    }

    setCargando(true);

    try {
      await cambiarPasswordInicial({
        passwordActual,
        nuevaPassword,
        confirmarPassword,
      });

      setMensaje("Contraseña actualizada correctamente.");

      setTimeout(() => {
        navigate("/dashboard");
      }, 1000);
    } catch (error) {
      const data = error.response?.data;

      setError(
        data?.password_actual ||
          data?.nueva_password ||
          data?.confirmar_password ||
          data?.error ||
          data?.detail ||
          error.message ||
          "No se pudo cambiar la contraseña."
      );
    } finally {
      setCargando(false);
    }
  };

  const handleSalir = () => {
    logout();
    navigate("/");
  };

  return (
    <div className="login-page">
      <div className="login-wrapper">
        <div className="login-left">
          <div className="login-left-content">
            <span className="login-badge">Primer ingreso</span>
            <h1>Cambia tu contraseña temporal</h1>
            <p>
              Por seguridad, debes establecer una nueva contraseña antes de
              acceder al panel administrativo.
            </p>
          </div>
        </div>

        <div className="login-right">
          <div className="login-card">
            <div className="login-brand">
              <div className="login-logo">🔐</div>
              <h2>Cambiar contraseña</h2>
              <p>Panel Administrativo</p>
            </div>

            <form onSubmit={handleSubmit} className="login-form">
              <div className="form-group">
                <label htmlFor="passwordActual">Contraseña actual</label>
                <div className="input-with-icon">
                  <input
                    id="passwordActual"
                    type="password"
                    value={passwordActual}
                    onChange={(e) => setPasswordActual(e.target.value)}
                    placeholder="Contraseña temporal"
                    required
                  />
                </div>
              </div>

              <div className="form-group">
                <label htmlFor="nuevaPassword">Nueva contraseña</label>
                <div className="input-with-icon">
                  <input
                    id="nuevaPassword"
                    type="password"
                    value={nuevaPassword}
                    onChange={(e) => setNuevaPassword(e.target.value)}
                    placeholder="Nueva contraseña"
                    required
                  />
                </div>
              </div>

              <div className="form-group">
                <label htmlFor="confirmarPassword">Confirmar contraseña</label>
                <div className="input-with-icon">
                  <input
                    id="confirmarPassword"
                    type="password"
                    value={confirmarPassword}
                    onChange={(e) => setConfirmarPassword(e.target.value)}
                    placeholder="Repite la nueva contraseña"
                    required
                  />
                </div>
              </div>

              {error && <div className="error-message">{error}</div>}

              {mensaje && (
                <div className="error-message" style={{ background: "#dcfce7", color: "#166534" }}>
                  {mensaje}
                </div>
              )}

              <button type="submit" className="login-button" disabled={cargando}>
                {cargando ? "Actualizando..." : "Cambiar contraseña"}
              </button>

              <button
                type="button"
                className="forgot-link"
                onClick={handleSalir}
                disabled={cargando}
              >
                Salir
              </button>
            </form>
          </div>
        </div>
      </div>
    </div>
  );
}

export default CambiarPasswordInicial;