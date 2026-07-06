import {useEffect, useState} from "react";
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

    const obtenerClaseEstadoPago = (estadoPago) => {
        if (estadoPago === "pagado" || estadoPago === "membresia") {
            return "success";
        }

        if (estadoPago === "fallido") {
            return "danger";
        }

        return "warning";
    };

    const obtenerClaseSeguridad = (estadoSeguridad) => {
        if (
            estadoSeguridad === "normal" ||
            estadoSeguridad === "sin_novedades" ||
            !estadoSeguridad
        ) {
            return "success";
        }

        return "danger";
    };

    const obtenerPeajeDeteccion = (deteccion) => {
        return deteccion?.django?.peaje || "Durán Tambo";
    };

    const obtenerTarifaDeteccion = (deteccion) => {
        return deteccion?.django?.tarifa_aplicada
            ? `$${deteccion.django.tarifa_aplicada}`
            : "--";
    };

    const obtenerVehiculoRegistrado = (deteccion) => {
        if (deteccion?.django?.vehiculo_encontrado === true) {
            return "Sí";
        }

        if (deteccion?.django?.vehiculo_encontrado === false) {
            return "No";
        }

        return "--";
    };

    const obtenerDuplicado = (deteccion) => {
        if (deteccion?.django?.duplicado === true) {
            return "Sí";
        }

        if (deteccion?.django?.duplicado === false) {
            return "No";
        }

        return "--";
    };

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

                    <span className="peaje-tag">
            Peaje: {obtenerPeajeDeteccion(ultimaDeteccion)}
          </span>
                </div>
            </div>

            {errorServidor && (
                <div className="server-warning">
                    {errorServidor}
                </div>
            )}
            {ultimaDeteccion?.estado_vehiculo === "alerta" && (
                <div className="security-alert-banner">
                    🚨 Vehículo con aviso activo detectado. Alerta de seguridad generada.
                    {ultimaDeteccion?.django?.seguridad?.url_maps && (
                        <a
                            href={ultimaDeteccion.django.seguridad.url_maps}
                            target="_blank"
                            rel="noreferrer"
                        >
                            Ver ubicación
                        </a>
                    )}
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
                                <span>{ultimaDeteccion?.placa || "Esperando..."}</span>
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
                                    <strong>{ultimaDeteccion?.fecha_hora || "--"}</strong>
                                </div>

                                <div>
                                    <span>Punto de Peaje</span>
                                    <strong>{obtenerPeajeDeteccion(ultimaDeteccion)}</strong>
                                </div>

                                <div>
                                    <span>Estado de Pago</span>
                                    <strong
                                        className={obtenerClaseEstadoPago(
                                            ultimaDeteccion?.estado_pago
                                        )}
                                    >
                                        {ultimaDeteccion?.estado_pago || "--"}
                                    </strong>
                                </div>

                                <div>
                                    <span>Estado Seguridad</span>
                                    <strong
                                        className={obtenerClaseSeguridad(
                                            ultimaDeteccion?.estado_vehiculo
                                        )}
                                    >
                                        {ultimaDeteccion?.estado_vehiculo === "alerta"
                                            ? "ALERTA"
                                            : ultimaDeteccion?.estado_vehiculo || "Sin novedades"}
                                    </strong>
                                </div>

                                <div>
                                    <span>Vehículo Registrado</span>
                                    <strong>{obtenerVehiculoRegistrado(ultimaDeteccion)}</strong>
                                </div>

                                <div>
                                    <span>Tarifa Aplicada</span>
                                    <strong>{obtenerTarifaDeteccion(ultimaDeteccion)}</strong>
                                </div>



                                <div>
                                    <span>Duplicado</span>
                                    <strong>{obtenerDuplicado(ultimaDeteccion)}</strong>
                                </div>
                                <div>
                                    <span>Alerta Generada</span>
                                    <strong
                                        className={
                                            ultimaDeteccion?.django?.seguridad?.alerta_generada
                                                ? "danger"
                                                : "success"
                                        }
                                    >
                                        {ultimaDeteccion?.django?.seguridad?.alerta_generada ? "Sí" : "No"}
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
                            historial
                                .slice(-4)
                                .reverse()
                                .map((item, index) => (
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
                        <input type="text" placeholder="Buscar placa..."/>
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
                            <th>Seguridad</th>
                            <th>Tarifa</th>
                            <th>Registrado</th>
                            <th>Duplicado</th>
                            <th>Acciones</th>
                        </tr>
                        </thead>

                        <tbody>
                        {historial.length > 0 ? (
                            historial
                                .slice()
                                .reverse()
                                .map((item, index) => (
                                    <tr key={index}>
                                        <td>{item.fecha_hora}</td>
                                        <td>{item.placa}</td>
                                        <td>{obtenerPeajeDeteccion(item)}</td>
                                        <td>{item.confianza}%</td>
                                        <td>{item.estado_pago}</td>
                                        <td>
                                        <span
                                            className={
                                                item.estado_vehiculo === "alerta"
                                                    ? "history-status danger"
                                                    : "history-status success"
                                                      }
                                                    >
                                                      {item.estado_vehiculo === "alerta" ? "ALERTA" : "Normal"}
                                            </span>
                                        </td>
                                        <td>{obtenerTarifaDeteccion(item)}</td>
                                        <td>{obtenerVehiculoRegistrado(item)}</td>
                                        <td>{obtenerDuplicado(item)}</td>
                                        <td>
                                            <button className="table-action-btn">
                                                Ver
                                            </button>
                                        </td>
                                    </tr>
                                ))
                        ) : (
                            <tr>
                                <td colSpan="10">
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