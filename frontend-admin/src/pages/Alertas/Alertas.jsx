import { useEffect, useState } from "react";
import {
  obtenerAlertas,
  marcarAlertaRevisada,
  derivarAlertaAutoridad,
  cerrarAlerta,
  descartarAlerta,
  obtenerSolicitudesReactivacion,
  aprobarSolicitudReactivacion,
  rechazarSolicitudReactivacion,
} from "../../api/seguridadService.js";
import "../Styles/Alertas.css";
import ModuleHeader from "../../components/ModuleHeader/ModuleHeader";

function Alertas() {
  const [vistaActiva, setVistaActiva] = useState("alertas");

  const [alertas, setAlertas] = useState([]);
  const [solicitudesReactivacion, setSolicitudesReactivacion] = useState([]);

  const [cargando, setCargando] = useState(true);
  const [cargandoSolicitudes, setCargandoSolicitudes] = useState(true);

  const [procesandoSolicitudId, setProcesandoSolicitudId] = useState(null);

  const [error, setError] = useState("");
  const [mensaje, setMensaje] = useState("");

  const normalizarLista = (data, campoAlternativo) => {
    if (Array.isArray(data)) return data;
    if (Array.isArray(data?.results)) return data.results;
    if (campoAlternativo && Array.isArray(data?.[campoAlternativo])) {
      return data[campoAlternativo];
    }
    return [];
  };

  const cargarAlertas = async () => {
    try {
      setCargando(true);
      setError("");

      const data = await obtenerAlertas();
      setAlertas(normalizarLista(data, "alertas"));
    } catch {
      setError("No se pudieron cargar las alertas.");
    } finally {
      setCargando(false);
    }
  };

  const cargarSolicitudesReactivacion = async () => {
    try {
      setCargandoSolicitudes(true);
      setError("");

      const data = await obtenerSolicitudesReactivacion();
      setSolicitudesReactivacion(normalizarLista(data, "solicitudes"));
    } catch {
      setError("No se pudieron cargar las solicitudes de reactivación.");
    } finally {
      setCargandoSolicitudes(false);
    }
  };

  const cargarTodo = async () => {
    await Promise.all([cargarAlertas(), cargarSolicitudesReactivacion()]);
  };

  useEffect(() => {
    cargarTodo();
  }, []);

  const ejecutarAccion = async (accion, id, textoExito) => {
    try {
      setError("");
      setMensaje("");

      await accion(id);

      setMensaje(textoExito);
      await cargarAlertas();
    } catch {
      setError("No se pudo ejecutar la acción seleccionada.");
    }
  };

  const obtenerClaseEstado = (estado) => {
    switch (estado) {
      case "pendiente":
        return "estado pendiente";
      case "revisada":
        return "estado revisada";
      case "derivada":
        return "estado derivada";
      case "cerrada":
        return "estado cerrada";
      case "descartada":
        return "estado descartada";
      default:
        return "estado";
    }
  };

  const obtenerClaseEstadoSolicitud = (estado) => {
    switch (estado) {
      case "pendiente":
        return "estado pendiente";
      case "aprobada":
        return "estado cerrada";
      case "rechazada":
        return "estado descartada";
      default:
        return "estado";
    }
  };

  const textoEstadoSolicitud = (estado) => {
    switch (estado) {
      case "pendiente":
        return "Pendiente";
      case "aprobada":
        return "Aprobada";
      case "rechazada":
        return "Rechazada";
      default:
        return estado || "Sin estado";
    }
  };

  const obtenerPlaca = (alerta) => {
    return (
      alerta?.vehiculo_placa ||
      alerta?.aviso_detalle?.vehiculo_placa ||
      alerta?.placa ||
      alerta?.vehiculo?.placa ||
      alerta?.vehiculo ||
      "Sin dato"
    );
  };

  const obtenerVehiculo = (alerta) => {
    return (
      alerta?.vehiculo_nombre ||
      alerta?.vehiculo_detalle?.nombre ||
      alerta?.vehiculo_detalle ||
      alerta?.aviso_detalle?.vehiculo_placa ||
      obtenerPlaca(alerta)
    );
  };

  const obtenerPeaje = (alerta) => {
    return (
      alerta?.peaje_nombre ||
      alerta?.peaje?.nombre ||
      alerta?.peaje ||
      "Sin dato"
    );
  };

  const obtenerUrlMaps = (alerta) => {
    return (
      alerta?.url_maps ||
      alerta?.ubicacion?.url_maps ||
      alerta?.ubicacion_deteccion?.url_maps ||
      alerta?.ubicaciondeteccion?.url_maps ||
      null
    );
  };

  const obtenerBaseBackend = () => {
    const apiUrl =
      import.meta.env.VITE_API_URL ||
      import.meta.env.VITE_API_BASE_URL ||
      "http://localhost:8000/api";

    return apiUrl.replace(/\/api\/?$/, "");
  };

  const normalizarUrlArchivo = (url) => {
    if (!url) return null;

    if (url.startsWith("http")) {
      return url;
    }

    if (url.startsWith("/")) {
      return `${obtenerBaseBackend()}${url}`;
    }

    return `${obtenerBaseBackend()}/${url}`;
  };

  const obtenerDocumentoRespaldo = (alerta) => {
    const documento =
      alerta?.aviso_detalle?.documento_respaldo_url ||
      alerta?.aviso?.documento_respaldo_url ||
      alerta?.documento_respaldo_url ||
      alerta?.aviso_detalle?.documento_respaldo ||
      alerta?.aviso?.documento_respaldo ||
      null;

    return normalizarUrlArchivo(documento);
  };

  const obtenerDocumentoSolicitud = (solicitud) => {
    return normalizarUrlArchivo(solicitud?.documento_respaldo);
  };

  const alertaBloqueada = (estado) => {
    return estado === "cerrada" || estado === "descartada";
  };

  const textoTipoAlerta = (tipo) => {
    if (tipo === "vehiculo_robado") return "Vehículo robado";
    if (tipo === "Vehículo con aviso interno de robo") {
      return "Vehículo robado";
    }

    return tipo || "Alerta";
  };

  const formatearFecha = (fecha) => {
    if (!fecha) return "Sin fecha";

    try {
      return new Date(fecha).toLocaleString();
    } catch {
      return fecha;
    }
  };

  const aprobarSolicitud = async (solicitud) => {
    const respuesta = window.prompt(
      `Respuesta para aprobar la reactivación del vehículo ${solicitud.placa}:`,
      "Solicitud aprobada. Vehículo recuperado y reactivado."
    );

    if (respuesta === null) return;

    const confirmar = window.confirm(
      `¿Deseas aprobar la reactivación del vehículo ${solicitud.placa}?`
    );

    if (!confirmar) return;

    try {
      setProcesandoSolicitudId(solicitud.id);
      setError("");
      setMensaje("");

      const data = await aprobarSolicitudReactivacion(
        solicitud.id,
        respuesta.trim()
      );

      setMensaje(
        data.mensaje ||
          `Vehículo ${solicitud.placa} reactivado correctamente.`
      );

      await cargarSolicitudesReactivacion();
      await cargarAlertas();
    } catch {
      setError(
        error.response?.data?.error ||
          error.response?.data?.detail ||
          "No se pudo aprobar la solicitud."
      );
    } finally {
      setProcesandoSolicitudId(null);
    }
  };

  const rechazarSolicitud = async (solicitud) => {
    const respuesta = window.prompt(
      `Motivo de rechazo para el vehículo ${solicitud.placa}:`,
      solicitud.respuesta_admin || ""
    );

    if (respuesta === null) return;

    if (!respuesta.trim()) {
      setError("Debes ingresar el motivo del rechazo.");
      return;
    }

    const confirmar = window.confirm(
      `¿Deseas rechazar la reactivación del vehículo ${solicitud.placa}?`
    );

    if (!confirmar) return;

    try {
      setProcesandoSolicitudId(solicitud.id);
      setError("");
      setMensaje("");

      const data = await rechazarSolicitudReactivacion(
        solicitud.id,
        respuesta.trim()
      );

      setMensaje(data.mensaje || "Solicitud rechazada correctamente.");

      await cargarSolicitudesReactivacion();
    } catch {
      setError(
        error.response?.data?.error ||
          error.response?.data?.detail ||
          "No se pudo rechazar la solicitud."
      );
    } finally {
      setProcesandoSolicitudId(null);
    }
  };

  const renderResumenAlertas = () => {
    return (
      <div className="alertas-summary">
        <div>
          <span>Total alertas</span>
          <strong>{alertas.length}</strong>
        </div>

        <div>
          <span>Pendientes</span>
          <strong>
            {alertas.filter((alerta) => alerta.estado === "pendiente").length}
          </strong>
        </div>

        <div>
          <span>Derivadas</span>
          <strong>
            {alertas.filter((alerta) => alerta.estado === "derivada").length}
          </strong>
        </div>

        <div>
          <span>Cerradas</span>
          <strong>
            {alertas.filter((alerta) => alerta.estado === "cerrada").length}
          </strong>
        </div>
      </div>
    );
  };

  const renderTablaAlertas = () => {
    if (cargando) {
      return (
        <div className="alertas-table-card">
          <p className="alertas-empty">Cargando alertas...</p>
        </div>
      );
    }

    return (
      <div className="alertas-table-card">
        <table>
          <thead>
            <tr>
              <th>Placa</th>
              <th>Vehículo</th>
              <th>Peaje</th>
              <th>Tipo</th>
              <th>Estado</th>
              <th>Fecha</th>
              <th>Ubicación</th>
              <th>Documento</th>
              <th>Descripción</th>
              <th>Acciones</th>
            </tr>
          </thead>

          <tbody>
            {alertas.length > 0 ? (
              alertas.map((alerta) => {
                const urlMaps = obtenerUrlMaps(alerta);
                const documentoUrl = obtenerDocumentoRespaldo(alerta);

                return (
                  <tr key={alerta.id}>
                    <td>
                      <strong className="placa-alerta">
                        {obtenerPlaca(alerta)}
                      </strong>
                    </td>

                    <td>{obtenerVehiculo(alerta)}</td>

                    <td>{obtenerPeaje(alerta)}</td>

                    <td>{textoTipoAlerta(alerta.tipo_alerta)}</td>

                    <td>
                      <span className={obtenerClaseEstado(alerta.estado)}>
                        {alerta.estado || "pendiente"}
                      </span>
                    </td>

                    <td>{formatearFecha(alerta.fecha_hora)}</td>

                    <td>
                      {urlMaps ? (
                        <a
                          className="maps-link"
                          href={urlMaps}
                          target="_blank"
                          rel="noreferrer"
                        >
                          Ver mapa
                        </a>
                      ) : (
                        "Sin ubicación"
                      )}
                    </td>

                    <td>
                      {documentoUrl ? (
                        <a
                          className="documento-link"
                          href={documentoUrl}
                          target="_blank"
                          rel="noreferrer"
                        >
                          Ver denuncia PDF
                        </a>
                      ) : (
                        <span className="sin-documento">Sin documento</span>
                      )}
                    </td>

                    <td className="descripcion-alerta">
                      {alerta.descripcion || "Sin descripción"}
                    </td>

                    <td>
                      <div className="acciones">
                        <button
                          className="btn-action"
                          onClick={() =>
                            ejecutarAccion(
                              marcarAlertaRevisada,
                              alerta.id,
                              "Alerta marcada como revisada."
                            )
                          }
                          disabled={alertaBloqueada(alerta.estado)}
                        >
                          Revisar
                        </button>

                        <button
                          className="btn-action warning"
                          onClick={() =>
                            ejecutarAccion(
                              derivarAlertaAutoridad,
                              alerta.id,
                              "Alerta derivada a autoridad."
                            )
                          }
                          disabled={alertaBloqueada(alerta.estado)}
                        >
                          Derivar
                        </button>

                        <button
                          className="btn-action success"
                          onClick={() =>
                            ejecutarAccion(
                              cerrarAlerta,
                              alerta.id,
                              "Alerta cerrada correctamente."
                            )
                          }
                          disabled={alertaBloqueada(alerta.estado)}
                        >
                          Cerrar
                        </button>

                        <button
                          className="btn-action danger"
                          onClick={() =>
                            ejecutarAccion(
                              descartarAlerta,
                              alerta.id,
                              "Alerta descartada correctamente."
                            )
                          }
                          disabled={alertaBloqueada(alerta.estado)}
                        >
                          Descartar
                        </button>
                      </div>
                    </td>
                  </tr>
                );
              })
            ) : (
              <tr>
                <td colSpan="10">No existen alertas registradas.</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    );
  };

  const renderResumenSolicitudes = () => {
    return (
      <div className="alertas-summary">
        <div>
          <span>Total solicitudes</span>
          <strong>{solicitudesReactivacion.length}</strong>
        </div>

        <div>
          <span>Pendientes</span>
          <strong>
            {
              solicitudesReactivacion.filter(
                (solicitud) => solicitud.estado === "pendiente"
              ).length
            }
          </strong>
        </div>

        <div>
          <span>Aprobadas</span>
          <strong>
            {
              solicitudesReactivacion.filter(
                (solicitud) => solicitud.estado === "aprobada"
              ).length
            }
          </strong>
        </div>

        <div>
          <span>Rechazadas</span>
          <strong>
            {
              solicitudesReactivacion.filter(
                (solicitud) => solicitud.estado === "rechazada"
              ).length
            }
          </strong>
        </div>
      </div>
    );
  };

  const renderTablaSolicitudes = () => {
    if (cargandoSolicitudes) {
      return (
        <div className="alertas-table-card">
          <p className="alertas-empty">Cargando solicitudes...</p>
        </div>
      );
    }

    return (
      <div className="alertas-table-card">
        <table>
          <thead>
            <tr>
              <th>Placa</th>
              <th>Usuario</th>
              <th>Motivo</th>
              <th>Estado</th>
              <th>Fecha solicitud</th>
              <th>Documento</th>
              <th>Respuesta admin</th>
              <th>Acciones</th>
            </tr>
          </thead>

          <tbody>
            {solicitudesReactivacion.length > 0 ? (
              solicitudesReactivacion.map((solicitud) => {
                const documentoUrl = obtenerDocumentoSolicitud(solicitud);
                const estaPendiente = solicitud.estado === "pendiente";
                const procesando = procesandoSolicitudId === solicitud.id;

                return (
                  <tr key={solicitud.id}>
                    <td>
                      <strong className="placa-alerta">
                        {solicitud.placa || "Sin placa"}
                      </strong>
                    </td>

                    <td>
                      {solicitud.usuario_username ||
                        solicitud.usuario ||
                        "Sin usuario"}
                    </td>

                    <td className="descripcion-alerta">
                      {solicitud.motivo || "Sin motivo"}
                    </td>

                    <td>
                      <span
                        className={obtenerClaseEstadoSolicitud(
                          solicitud.estado
                        )}
                      >
                        {textoEstadoSolicitud(solicitud.estado)}
                      </span>
                    </td>

                    <td>{formatearFecha(solicitud.fecha_solicitud)}</td>

                    <td>
                      {documentoUrl ? (
                        <a
                          className="documento-link"
                          href={documentoUrl}
                          target="_blank"
                          rel="noreferrer"
                        >
                          Ver respaldo
                        </a>
                      ) : (
                        <span className="sin-documento">Sin documento</span>
                      )}
                    </td>

                    <td>
                      {solicitud.respuesta_admin || (
                        <span className="sin-documento">Sin respuesta</span>
                      )}
                    </td>

                    <td>
                      {estaPendiente ? (
                        <div className="acciones">
                          <button
                            className="btn-action success"
                            onClick={() => aprobarSolicitud(solicitud)}
                            disabled={procesando}
                          >
                            Aprobar
                          </button>

                          <button
                            className="btn-action danger"
                            onClick={() => rechazarSolicitud(solicitud)}
                            disabled={procesando}
                          >
                            Rechazar
                          </button>
                        </div>
                      ) : (
                        <span className="sin-documento">Revisada</span>
                      )}
                    </td>
                  </tr>
                );
              })
            ) : (
              <tr>
                <td colSpan="8">
                  No existen solicitudes de reactivación registradas.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    );
  };

  return (
    <div className="alertas-page">
      <ModuleHeader
        icon="🚨"
        title="Alertas de seguridad"
        subtitle="Gestiona alertas de vehículos robados y solicitudes de reactivación."
        badge="Seguridad"
        status="Monitoreo activo"
        actions={
          <>
            <button
              className="module-header-secondary"
              onClick={vistaActiva === "alertas" ? cargarAlertas : cargarSolicitudesReactivacion}
            >
              Actualizar
            </button>
          </>
        }
      />

      <div className="alertas-tabs">
        <button
          type="button"
          className={vistaActiva === "alertas" ? "tab-activa" : ""}
          onClick={() => setVistaActiva("alertas")}
        >
          Alertas de seguridad
        </button>

        <button
          type="button"
          className={vistaActiva === "reactivaciones" ? "tab-activa" : ""}
          onClick={() => setVistaActiva("reactivaciones")}
        >
          Solicitudes de reactivación
          {solicitudesReactivacion.filter((s) => s.estado === "pendiente")
            .length > 0 && (
            <span className="tab-badge">
              {
                solicitudesReactivacion.filter(
                  (s) => s.estado === "pendiente"
                ).length
              }
            </span>
          )}
        </button>
      </div>

      {error && <div className="alertas-error">{error}</div>}
      {mensaje && <div className="alertas-success">{mensaje}</div>}

      {vistaActiva === "alertas" ? (
        <>
          {renderResumenAlertas()}
          {renderTablaAlertas()}
        </>
      ) : (
        <>
          {renderResumenSolicitudes()}
          {renderTablaSolicitudes()}
        </>
      )}
    </div>
  );
}

export default Alertas;