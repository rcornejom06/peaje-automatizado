import { useEffect, useState } from "react";
import "../Styles/ReconocimientoPlacas.css";

function ReconocimientoPlacas() {
  const [estadoCamara, setEstadoCamara] = useState("cargando");
  const [ultimaDeteccion, setUltimaDeteccion] = useState(null);
  const [historial, setHistorial] = useState([]);
  const [errorServidor, setErrorServidor] = useState("");

  const cameraServerUrl = "http://localhost:5001";
  const cameraFeedUrl = `${cameraServerUrl}/video_feed`;

  const cargarDetecciones = async () => {
    try {
      const respuestaUltima = await fetch(`${cameraServerUrl}/last_detection`);
      const dataUltima = await respuestaUltima.json();

      if (dataUltima.detectado) {
        setUltimaDeteccion(dataUltima.deteccion);
      } else {
        setUltimaDeteccion(null);
      }

      const respuestaHistorial = await fetch(`${cameraServerUrl}/detections`);
      const dataHistorial = await respuestaHistorial.json();

      setHistorial(dataHistorial.detecciones || []);
      setErrorServidor("");
    } catch (error) {
      setErrorServidor("No se pudo conectar con el servidor de cámara.");
    }
  };

  useEffect(() => {
    cargarDetecciones();

    const intervalo = setInterval(() => {
      cargarDetecciones();
    }, 1500);

    return () => clearInterval(intervalo);
  }, []);

  return (
    <div className="lpr-page">
      <div className="lpr-header">
        <div>
          <h2>Reconocimiento de Placas (LPR)</h2>
          <p>Monitoreo en tiempo real y análisis del flujo vehicular.</p>
        </div>

        <div className="lpr-header-actions">
          <span
            className={
              estadoCamara === "activa"
                ? "camera-status active"
                : estadoCamara === "error"
                ? "camera-status error"
                : "camera-status loading"
            }
          >
            {estadoCamara === "activa"
              ? "Sistema Operativo"
              : estadoCamara === "error"
              ? "Cámara no disponible"
              : "Conectando cámara"}
          </span>

          <span className="peaje-tag">Peaje: Durán Tambo</span>
        </div>
      </div>

      {errorServidor && (
        <div className="server-warning">
          {errorServidor}
        </div>
      )}

      <div className="lpr-main-grid">
        <section className="lpr-card lpr-live-card">
          <div className="card-title-row">
            <h3>Última Captura</h3>
            <span>
              {ultimaDeteccion
                ? `ID Evento: ${ultimaDeteccion.fecha_hora}`
                : "ID Evento: esperando detección"}
            </span>
          </div>

          <div className="live-content">
            <div className="video-frame">
              <div className="detection-label">DETECCIÓN LPR</div>

              <img
                src={cameraFeedUrl}
                alt="Cámara en vivo"
                className="live-camera"
                onLoad={() => setEstadoCamara("activa")}
                onError={() => setEstadoCamara("error")}
              />
            </div>

            <div className="plate-info">
              <span className="small-label">PLACA DETECTADA</span>

              <div className="plate-box">
                <span>
                  {ultimaDeteccion?.placa || "Esperando..."}
                </span>
              </div>

              <div className="confidence-circle">
                <strong>
                  {ultimaDeteccion?.confianza
                    ? `${ultimaDeteccion.confianza}%`
                    : "--"}
                </strong>
                <span>IA</span>
              </div>

              <div className="info-grid">
                <div>
                  <span>Fecha / Hora</span>
                  <strong>
                    {ultimaDeteccion?.fecha_hora || "--"}
                  </strong>
                </div>

                <div>
                  <span>Punto de Peaje</span>
                  <strong>Durán Tambo</strong>
                </div>

                <div>
                  <span>Estado de Pago</span>
                  <strong className="success">
                    {ultimaDeteccion?.estado_pago || "--"}
                  </strong>
                </div>

                <div>
                  <span>Estado Vehículo</span>
                  <strong>
                    {ultimaDeteccion?.estado_vehiculo || "Sin novedades"}
                  </strong>
                </div>
              </div>

              <div className="plate-actions">
                <button className="btn-detail">Ver Detalle</button>
                <button className="btn-print">🖨️</button>
              </div>
            </div>
          </div>
        </section>

        <section className="lpr-card recent-card">
          <h3>Capturas Recientes</h3>

          <div className="recent-grid">
            {historial.length > 0 ? (
              historial.slice(-4).reverse().map((item, index) => (
                <div className="recent-detection" key={index}>
                  <strong>{item.placa}</strong>
                  <span>{item.fecha_hora}</span>
                </div>
              ))
            ) : (
              <>
                <div className="recent-placeholder">Sin captura</div>
                <div className="recent-placeholder">Sin captura</div>
                <div className="recent-placeholder">Sin captura</div>
                <div className="recent-placeholder">Sin captura</div>
              </>
            )}
          </div>

          <button className="btn-gallery">Ver Galería Completa</button>
        </section>
      </div>

      <section className="lpr-card history-card">
        <div className="history-header">
          <h3>Historial de Detecciones</h3>

          <div className="history-tools">
            <input type="text" placeholder="Buscar placa..." />
            <button>Filtrar</button>
          </div>
        </div>

        <div className="history-table-wrapper">
          <table>
            <thead>
              <tr>
                <th>Fecha / Hora</th>
                <th>Placa</th>
                <th>Peaje</th>
                <th>Confianza IA</th>
                <th>Estado Pago</th>
                <th>Acciones</th>
              </tr>
            </thead>

            <tbody>
              {historial.length > 0 ? (
                historial.slice().reverse().map((item, index) => (
                  <tr key={index}>
                    <td>{item.fecha_hora}</td>
                    <td>{item.placa}</td>
                    <td>Durán Tambo</td>
                    <td>{item.confianza}%</td>
                    <td>{item.estado_pago}</td>
                    <td>
                      <button className="table-action-btn">
                        Ver
                      </button>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan="6">
                    Esperando detecciones reales...
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </section>
    </div>
  );
}

export default ReconocimientoPlacas;