import { useEffect, useState } from "react";
import {
  obtenerNotificaciones,
  obtenerNotificacionesNoLeidas,
  marcarNotificacionLeida,
  marcarTodasNotificacionesLeidas,
} from "../../api/notificacionesService.js";
import "../../components/NotificationBell/NotificationBell.css";

function NotificationBell() {
  const [abierto, setAbierto] = useState(false);
  const [notificaciones, setNotificaciones] = useState([]);
  const [noLeidas, setNoLeidas] = useState(0);
  const [cargando, setCargando] = useState(false);

  const cargarContador = async () => {
    try {
      const data = await obtenerNotificacionesNoLeidas();
      setNoLeidas(Number(data?.no_leidas || 0));
    } catch (error) {
      setNoLeidas(0);
    }
  };

  const cargarNotificaciones = async () => {
    try {
      setCargando(true);

      const data = await obtenerNotificaciones();

      if (Array.isArray(data)) {
        setNotificaciones(data);
      } else if (Array.isArray(data?.results)) {
        setNotificaciones(data.results);
      } else {
        setNotificaciones([]);
      }

      await cargarContador();
    } catch (error) {
      setNotificaciones([]);
    } finally {
      setCargando(false);
    }
  };

  useEffect(() => {
    cargarContador();

    const interval = setInterval(() => {
      cargarContador();
    }, 30000);

    return () => clearInterval(interval);
  }, []);

  const abrirPanel = async () => {
    const nuevoEstado = !abierto;
    setAbierto(nuevoEstado);

    if (nuevoEstado) {
      await cargarNotificaciones();
    }
  };

  const abrirAccion = async (notificacion) => {
    if (!notificacion?.leida) {
      await marcarNotificacionLeida(notificacion.id);
      await cargarNotificaciones();
    }

    if (notificacion?.url_accion) {
      window.open(notificacion.url_accion, "_blank", "noopener,noreferrer");
      return;
    }

    switch (notificacion?.tipo_accion) {
      case "vehiculos":
        window.location.href = "/vehiculos";
        break;
      case "seguridad":
        window.location.href = "/alertas";
        break;
      case "membresias":
        window.location.href = "/membresias";
        break;
      case "billetera":
        window.location.href = "/billetera";
        break;
      case "pasos":
        window.location.href = "/pasos";
        break;
      default:
        break;
    }
  };

  const marcarTodas = async () => {
    await marcarTodasNotificacionesLeidas();
    await cargarNotificaciones();
  };

  return (
    <div className="notification-bell-wrapper">
      <button
        type="button"
        className="notification-bell-button"
        onClick={abrirPanel}
        title="Notificaciones"
      >
        🔔
        {noLeidas > 0 && (
          <span className="notification-bell-badge">
            {noLeidas > 99 ? "99+" : noLeidas}
          </span>
        )}
      </button>

      {abierto && (
        <div className="notification-panel">
          <div className="notification-panel-header">
            <div>
              <strong>Notificaciones</strong>
              <span>{noLeidas} sin leer</span>
            </div>

            <button type="button" onClick={marcarTodas}>
              Marcar todas
            </button>
          </div>

          <div className="notification-panel-body">
            {cargando ? (
              <p className="notification-empty">Cargando...</p>
            ) : notificaciones.length === 0 ? (
              <p className="notification-empty">No tienes notificaciones.</p>
            ) : (
              notificaciones.map((notificacion) => (
                <button
                  key={notificacion.id}
                  type="button"
                  className={
                    notificacion.leida
                      ? "notification-item"
                      : "notification-item unread"
                  }
                  onClick={() => abrirAccion(notificacion)}
                >
                  <div className="notification-item-title">
                    {notificacion.titulo || "Notificación"}
                  </div>

                  <div className="notification-item-message">
                    {notificacion.mensaje || ""}
                  </div>

                  <div className="notification-item-date">
                    {notificacion.fecha_hora
                      ? new Date(notificacion.fecha_hora).toLocaleString()
                      : ""}
                  </div>
                </button>
              ))
            )}
          </div>
        </div>
      )}
    </div>
  );
}

export default NotificationBell;