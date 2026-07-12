import { useState } from "react";
import { useNavigate } from "react-router-dom";
import {
  solicitarResetPassword,
  confirmarResetPassword,
} from "../../api/passwordResetService";
import "../Styles/ForgotPassword.css";

function ForgotPassword() {
  const navigate = useNavigate();

  const [paso, setPaso] = useState(1);
  const [email, setEmail] = useState("");
  const [codigo, setCodigo] = useState("");
  const [nuevaPassword, setNuevaPassword] = useState("");
  const [confirmarPassword, setConfirmarPassword] = useState("");
  const [mostrarPassword, setMostrarPassword] = useState(false);
  const [cargando, setCargando] = useState(false);
  const [mensaje, setMensaje] = useState("");
  const [error, setError] = useState("");

  const limpiarMensajes = () => {
    setMensaje("");
    setError("");
  };

  const enviarCodigo = async (e) => {
    e.preventDefault();
    limpiarMensajes();

    if (!email.trim()) {
      setError("Ingresa tu correo electrónico.");
      return;
    }

    setCargando(true);

    try {
      await solicitarResetPassword(email.trim());

      setMensaje(
        "Te enviamos un código de recuperación. Revisa tu correo electrónico."
      );
      setPaso(2);
    } catch (error) {
      const data = error.response?.data;

      setError(
        data?.error ||
          data?.detail ||
          data?.mensaje ||
          "No se pudo enviar el código de recuperación."
      );
    } finally {
      setCargando(false);
    }
  };

  const cambiarPassword = async (e) => {
    e.preventDefault();
    limpiarMensajes();

    if (!codigo.trim()) {
      setError("Ingresa el código de recuperación.");
      return;
    }

    if (!nuevaPassword.trim()) {
      setError("Ingresa tu nueva contraseña.");
      return;
    }

    if (nuevaPassword.length < 8) {
      setError("La nueva contraseña debe tener mínimo 8 caracteres.");
      return;
    }

    if (nuevaPassword !== confirmarPassword) {
      setError("Las contraseñas no coinciden.");
      return;
    }

    setCargando(true);

    try {
      await confirmarResetPassword({
        email: email.trim(),
        codigo: codigo.trim(),
        nuevaPassword,
      });

      setMensaje("Contraseña actualizada correctamente. Ya puedes iniciar sesión.");

      setTimeout(() => {
        navigate("/");
      }, 1800);
    } catch (error) {
      const data = error.response?.data;

      setError(
        data?.error ||
          data?.detail ||
          data?.mensaje ||
          "No se pudo cambiar la contraseña. Verifica el código."
      );
    } finally {
      setCargando(false);
    }
  };

  return (
    <div className="forgot-page">
      <div className="forgot-card">
        <button
          type="button"
          className="forgot-back"
          onClick={() => navigate("/")}
        >
          ← Volver al login
        </button>

        <div className="forgot-brand">
          <div className="forgot-logo">🔐</div>
          <span>VíaSmart</span>
          <h1>Recuperar contraseña</h1>
          <p>
            {paso === 1
              ? "Ingresa tu correo para recibir un código de recuperación."
              : "Ingresa el código recibido y crea una nueva contraseña."}
          </p>
        </div>

        {paso === 1 && (
          <form className="forgot-form" onSubmit={enviarCodigo}>
            <div className="forgot-group">
              <label>Correo electrónico</label>
              <div className="forgot-input-box">
                <span>✉️</span>
                <input
                  type="email"
                  placeholder="ejemplo@correo.com"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  autoComplete="email"
                />
              </div>
            </div>

            {error && <div className="forgot-error">{error}</div>}
            {mensaje && <div className="forgot-success">{mensaje}</div>}

            <button className="forgot-button" type="submit" disabled={cargando}>
              {cargando ? "Enviando..." : "Enviar código"}
            </button>
          </form>
        )}

        {paso === 2 && (
          <form className="forgot-form" onSubmit={cambiarPassword}>
            <div className="forgot-group">
              <label>Correo electrónico</label>
              <div className="forgot-input-box disabled">
                <span>✉️</span>
                <input type="email" value={email} disabled />
              </div>
            </div>

            <div className="forgot-group">
              <label>Código de recuperación</label>
              <div className="forgot-input-box">
                <span>🔢</span>
                <input
                  type="text"
                  placeholder="Ingresa el código"
                  value={codigo}
                  onChange={(e) => setCodigo(e.target.value)}
                />
              </div>
            </div>

            <div className="forgot-group">
              <label>Nueva contraseña</label>
              <div className="forgot-input-box">
                <span>🔒</span>
                <input
                  type={mostrarPassword ? "text" : "password"}
                  placeholder="Nueva contraseña"
                  value={nuevaPassword}
                  onChange={(e) => setNuevaPassword(e.target.value)}
                  autoComplete="new-password"
                />

                <button
                  type="button"
                  className="forgot-eye"
                  onClick={() => setMostrarPassword(!mostrarPassword)}
                >
                  {mostrarPassword ? "🙈" : "👁️"}
                </button>
              </div>
            </div>

            <div className="forgot-group">
              <label>Confirmar contraseña</label>
              <div className="forgot-input-box">
                <span>🔒</span>
                <input
                  type={mostrarPassword ? "text" : "password"}
                  placeholder="Repite la contraseña"
                  value={confirmarPassword}
                  onChange={(e) => setConfirmarPassword(e.target.value)}
                  autoComplete="new-password"
                />
              </div>
            </div>

            {error && <div className="forgot-error">{error}</div>}
            {mensaje && <div className="forgot-success">{mensaje}</div>}

            <button className="forgot-button" type="submit" disabled={cargando}>
              {cargando ? "Actualizando..." : "Cambiar contraseña"}
            </button>

            <button
              type="button"
              className="forgot-secondary"
              onClick={enviarCodigo}
              disabled={cargando}
            >
              Reenviar código
            </button>
          </form>
        )}
      </div>
    </div>
  );
}

export default ForgotPassword;