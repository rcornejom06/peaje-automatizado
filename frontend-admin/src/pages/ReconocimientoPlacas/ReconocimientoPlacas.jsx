import {useEffect, useState} from "react";
import "../Styles/ReconocimientoPlacas.css";
import {QRCodeCanvas} from "qrcode.react";
import {obtenerComprobantePaso} from "../../api/comprobantesService.js";

function ReconocimientoPlacas() {
    const [estadoCamara, setEstadoCamara] = useState("cargando");
    const [ultimaDeteccion, setUltimaDeteccion] = useState(null);
    const [historial, setHistorial] = useState([]);
    const [errorServidor, setErrorServidor] = useState("");

    const [detalleAbierto, setDetalleAbierto] = useState(false);
    const [comprobanteSeleccionado, setComprobanteSeleccionado] = useState(null);
    const [cargandoComprobante, setCargandoComprobante] = useState(false);
    const [errorComprobante, setErrorComprobante] = useState("");

    const cameraServerUrl =
        import.meta.env.VITE_CAMERA_SERVER_URL || "http://localhost:5001";
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
        } catch {
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

    const abrirDetalle = async (deteccion) => {
        if (!deteccion) return;

        const pasoId =
            deteccion?.django?.paso_id ||
            deteccion?.paso_id ||
            deteccion?.id_paso ||
            deteccion?.id;

        if (!pasoId) {
            setErrorComprobante("No se encontró el ID del paso para generar el comprobante.");
            setComprobanteSeleccionado(null);
            setDetalleAbierto(true);
            return;
        }

        try {
            setCargandoComprobante(true);
            setErrorComprobante("");
            setDetalleAbierto(true);

            const data = await obtenerComprobantePaso(pasoId);
            setComprobanteSeleccionado(data);
        } catch {
            setErrorComprobante("No se pudo cargar el comprobante del paso.");
            setComprobanteSeleccionado(null);
        } finally {
            setCargandoComprobante(false);
        }
    };

    const cerrarDetalle = () => {
        setDetalleAbierto(false);
        setComprobanteSeleccionado(null);
        setErrorComprobante("");
    };

    const formatearFecha = (fecha) => {
        if (!fecha) return "Sin fecha";

        try {
            return new Date(fecha).toLocaleString();
        } catch {
            return fecha;
        }
    };

    const formatearDinero = (valor) => {
        const numero = Number(valor || 0);

        if (Number.isNaN(numero)) {
            return "$0.00";
        }

        return `$${numero.toFixed(2)}`;
    };

    const textoEstadoPago = (estado) => {
        if (estado === "pagado") return "Pagado";
        if (estado === "membresia") return "Pagado con Membresía";
        if (estado === "pendiente") return "Pendiente";
        if (estado === "fallido") return "Fallido";
        if (estado === "exonerado") return "Exonerado";
        return estado || "Sin estado";
    };

    const obtenerClaseEstadoPago = (estadoPago) => {
        if (["pagado", "membresia", "exonerado"].includes(estadoPago)) {
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
        const vehiculoEncontrado =
            deteccion?.django?.vehiculo_encontrado ??
            deteccion?.vehiculo_encontrado ??
            deteccion?.django?.deteccion ??
            deteccion?.deteccion;

        if (vehiculoEncontrado === true) {
            return "Registrado";
        }

        if (vehiculoEncontrado === false) {
            return "No registrado";
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


    const obtenerEstadoPago = (deteccion) => {
        return (
            deteccion?.estado_pago ||
            deteccion?.django?.estado_pago ||
            "pendiente"
        );
    };

    const obtenerEstadoSeguridad = (deteccion) => {
        return (
            deteccion?.estado_vehiculo ||
            deteccion?.django?.estado_seguridad ||
            "normal"
        );
    };

    const obtenerTextoSeguridad = (deteccion) => {
        const estado = obtenerEstadoSeguridad(deteccion);

        if (estado === "alerta") {
            return "ALERTA";
        }

        if (estado === "normal" || estado === "sin_novedades") {
            return "Normal";
        }

        return estado;
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
                <div className="server-warning">{errorServidor}</div>
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
                                            obtenerEstadoPago(ultimaDeteccion)
                                        )}
                                    >
                                        {textoEstadoPago(obtenerEstadoPago(ultimaDeteccion))}
                                    </strong>
                                </div>

                                <div>
                                    <span>Estado Seguridad</span>
                                    <strong
                                        className={obtenerClaseSeguridad(
                                            obtenerEstadoSeguridad(ultimaDeteccion)
                                        )}
                                    >
                                        {obtenerTextoSeguridad(ultimaDeteccion)}
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
                                        {ultimaDeteccion?.django?.seguridad?.alerta_generada
                                            ? "Sí"
                                            : "No"}
                                    </strong>
                                </div>
                            </div>

                            <div className="plate-actions">
                                <button
                                    className="btn-detail"
                                    onClick={() => abrirDetalle(ultimaDeteccion)}
                                    disabled={!ultimaDeteccion}
                                >
                                    Ver detalle
                                </button>

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
                                        <td>{textoEstadoPago(obtenerEstadoPago(item))}</td>
                                        <td>
                        <span
                            className={
                                obtenerEstadoSeguridad(item) === "alerta"
                                    ? "history-status danger"
                                    : "history-status success"
                            }
                        >
                          {obtenerTextoSeguridad(item)}
                        </span>
                                        </td>
                                        <td>{obtenerTarifaDeteccion(item)}</td>
                                        <td>{obtenerVehiculoRegistrado(item)}</td>
                                        <td>{obtenerDuplicado(item)}</td>
                                        <td>
                                            <button
                                                className="table-action-btn"
                                                onClick={() => abrirDetalle(item)}
                                            >
                                                Ver
                                            </button>
                                        </td>
                                    </tr>
                                ))
                        ) : (
                            <tr>
                                <td colSpan="10">Esperando detecciones reales...</td>
                            </tr>
                        )}
                        </tbody>
                    </table>
                </div>
            </section>
            {detalleAbierto && (
                <div className="receipt-overlay" onClick={cerrarDetalle}>
                    <div className="receipt-ticket" onClick={(e) => e.stopPropagation()}>
                        <button className="ticket-close" onClick={cerrarDetalle}>
                            ×
                        </button>

                        {cargandoComprobante ? (
                            <div className="ticket-loading">
                                <strong>Cargando comprobante...</strong>
                            </div>
                        ) : errorComprobante ? (
                            <div className="ticket-loading">
                                <strong>{errorComprobante}</strong>
                            </div>
                        ) : comprobanteSeleccionado ? (
                            <>
                                <div className="thermal-header">
                                    <h3>{comprobanteSeleccionado.peaje || "PEAJE"}</h3>
                                    <p>{comprobanteSeleccionado.empresa}</p>
                                    <p>{comprobanteSeleccionado.documento}</p>
                                </div>

                                <div className="thermal-separator"/>

                                <div className="thermal-body">
                                    <div className="thermal-line">
                                        <span>Ticket:</span>
                                        <strong>{comprobanteSeleccionado.ticket}</strong>
                                    </div>

                                    <div className="thermal-line">
                                        <span>Placa:</span>
                                        <strong>{comprobanteSeleccionado.placa}</strong>
                                    </div>

                                    <div className="thermal-line">
                                        <span>Carril:</span>
                                        <strong>{comprobanteSeleccionado.carril}</strong>
                                    </div>

                                    <div className="thermal-line">
                                        <span>Categoría:</span>
                                        <strong>{comprobanteSeleccionado.categoria}</strong>
                                    </div>

                                    <div className="thermal-line">
                                        <span>Cliente:</span>
                                        <strong>{comprobanteSeleccionado.tipo_cliente}</strong>
                                    </div>

                                    <div className="thermal-line">
                                        <span>Forma de pago:</span>
                                        <strong>{comprobanteSeleccionado.metodo_pago}</strong>
                                    </div>

                                    <div className="thermal-line">
                                        <span>Vehículo:</span>
                                        <strong>{comprobanteSeleccionado.vehiculo}</strong>
                                    </div>

                                    <div className="thermal-line">
                                        <span>Usuario:</span>
                                        <strong>{comprobanteSeleccionado.usuario}</strong>
                                    </div>

                                    <div className="thermal-line">
                                        <span>Fecha:</span>
                                        <strong>{formatearFecha(comprobanteSeleccionado.fecha_hora)}</strong>
                                    </div>

                                    <div className="thermal-line">
                                        <span>Estado pago:</span>
                                        <strong className={`ticket-status ${comprobanteSeleccionado.estado_pago}`}>
                                            {textoEstadoPago(comprobanteSeleccionado.estado_pago)}
                                        </strong>
                                    </div>

                                    <div className="thermal-line">
                                        <span>Seguridad:</span>
                                        <strong>{comprobanteSeleccionado.estado_seguridad}</strong>
                                    </div>

                                    <div className="thermal-total">
                                        <span>Valor:</span>
                                        <strong>{formatearDinero(comprobanteSeleccionado.valor)}</strong>
                                    </div>

                                    <div className="thermal-observation">
                                        <span>Observación:</span>
                                        <p>{comprobanteSeleccionado.observacion}</p>
                                    </div>
                                </div>

                                <div className="thermal-separator"/>

                                <div className="thermal-qr">
                                    <QRCodeCanvas
                                        value={comprobanteSeleccionado.codigo_qr || comprobanteSeleccionado.ticket}
                                        size={150}
                                        level="M"
                                        includeMargin
                                    />
                                </div>

                                <div className="thermal-footer">
                                    <p>Gracias por utilizar el sistema de peaje automatizado.</p>
                                    <small>Documento generado electrónicamente</small>
                                </div>
                            </>
                        ) : null}
                    </div>
                </div>

            )}
        </div>
    );
}

export default ReconocimientoPlacas;