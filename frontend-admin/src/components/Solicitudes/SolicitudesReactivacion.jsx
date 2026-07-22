import {useCallback, useEffect, useMemo, useState} from "react";
import {
    aprobarSolicitudReactivacion,
    obtenerSolicitudesReactivacion,
    rechazarSolicitudReactivacion,
} from "../../api/seguridadService.js";

import "../../pages/Styles/SolicitidudesReactivacion.css";

const normalizarLista = (data) => {
    if (Array.isArray(data)) return data;
    if (Array.isArray(data?.results)) return data.results;
    return [];
};

const formatearFecha = (valor) => {
    if (!valor) return "Sin fecha";

    try {
        return new Date(valor).toLocaleString("es-EC", {
            year: "numeric",
            month: "2-digit",
            day: "2-digit",
            hour: "2-digit",
            minute: "2-digit",
        });
    } catch {
        return valor;
    }
};

const textoEstado = (estado) => {
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

const claseEstado = (estado) => {
    switch (estado) {
        case "pendiente":
            return "estado-badge estado-pendiente";
        case "aprobada":
            return "estado-badge estado-aprobada";
        case "rechazada":
            return "estado-badge estado-rechazada";
        default:
            return "estado-badge";
    }
};

const obtenerDocumentoUrl = (solicitud) => {
    const documento =
        solicitud?.documento_respaldo_url ||
        solicitud?.documento_respaldo;

    if (!documento) return null;

    if (documento.startsWith("http://") || documento.startsWith("https://")) {
        return documento;
    }

    const apiUrl = import.meta.env.VITE_API_URL || "http://localhost:8000/api";
    const backendUrl = apiUrl.replace(/\/api\/?$/, "");

    if (documento.startsWith("/")) {
        return `${backendUrl}${documento}`;
    }

    return `${backendUrl}/${documento}`;
};

export default function SolicitudesReactivacion() {
    const [solicitudes, setSolicitudes] = useState([]);
    const [cargando, setCargando] = useState(true);
    const [procesandoId, setProcesandoId] = useState(null);
    const [error, setError] = useState("");
    const [mensaje, setMensaje] = useState("");
    const [filtroEstado, setFiltroEstado] = useState("pendiente");

    const cargarSolicitudes = useCallback(async () => {
        try {
            setCargando(true);
            setError("");
            setMensaje("");

            const data = await obtenerSolicitudesReactivacion();
            setSolicitudes(normalizarLista(data));
        } catch (err) {
            setError(
                err.response?.data?.error ||
                err.response?.data?.detail ||
                "No se pudieron cargar las solicitudes de reactivación."
            );
        } finally {
            setCargando(false);
        }
    }, []);

    useEffect(() => {
        cargarSolicitudes();
    }, [cargarSolicitudes]);

    const solicitudesFiltradas = useMemo(() => {
        if (filtroEstado === "todas") {
            return solicitudes;
        }

        return solicitudes.filter((solicitud) => solicitud.estado === filtroEstado);
    }, [solicitudes, filtroEstado]);

    const pendientes = useMemo(() => {
        return solicitudes.filter((solicitud) => solicitud.estado === "pendiente")
            .length;
    }, [solicitudes]);

    const aprobar = async (solicitud) => {
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
            setProcesandoId(solicitud.id);
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

            await cargarSolicitudes();
        } catch (err) {
            setError(
                err.response?.data?.error ||
                err.response?.data?.detail ||
                "No se pudo aprobar la solicitud."
            );
        } finally {
            setProcesandoId(null);
        }
    };

    const rechazar = async (solicitud) => {
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
            setProcesandoId(solicitud.id);
            setError("");
            setMensaje("");

            const data = await rechazarSolicitudReactivacion(
                solicitud.id,
                respuesta.trim()
            );

            setMensaje(data.mensaje || "Solicitud rechazada correctamente.");

            await cargarSolicitudes();
        } catch (err) {
            setError(
                err.response?.data?.error ||
                err.response?.data?.detail ||
                "No se pudo rechazar la solicitud."
            );
        } finally {
            setProcesandoId(null);
        }
    };

    return (
        <div className="page-container">
            <div className="page-header">
                <div>
                    <h1>Solicitudes de reactivación</h1>
                    <p>
                        Revisa las solicitudes de vehículos recuperados para volver a
                        habilitar los cobros de peaje.
                    </p>
                </div>

                <button
                    type="button"
                    className="btn btn-secondary"
                    onClick={cargarSolicitudes}
                    disabled={cargando}
                >
                    {cargando ? "Actualizando..." : "Actualizar"}
                </button>
            </div>

            <div className="summary-grid">
                <div className="summary-card">
                    <span>Total solicitudes</span>
                    <strong>{solicitudes.length}</strong>
                </div>

                <div className="summary-card">
                    <span>Pendientes</span>
                    <strong>{pendientes}</strong>
                </div>
            </div>

            <div className="toolbar">
                <label htmlFor="filtroEstado">Estado</label>
                <select
                    id="filtroEstado"
                    value={filtroEstado}
                    onChange={(event) => setFiltroEstado(event.target.value)}
                >
                    <option value="pendiente">Pendientes</option>
                    <option value="aprobada">Aprobadas</option>
                    <option value="rechazada">Rechazadas</option>
                    <option value="todas">Todas</option>
                </select>
            </div>

            {error && <div className="alert alert-error">{error}</div>}
            {mensaje && <div className="alert alert-success">{mensaje}</div>}

            {cargando ? (
                <div className="empty-state">Cargando solicitudes...</div>
            ) : solicitudesFiltradas.length === 0 ? (
                <div className="empty-state">
                    No hay solicitudes de reactivación para mostrar.
                </div>
            ) : (
                <div className="table-card">
                    <table className="data-table">
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
                        {solicitudesFiltradas.map((solicitud) => {
                            const documentoUrl =
                                obtenerDocumentoUrl(solicitud);
                            const estaPendiente =
                                solicitud.estado === "pendiente";
                            const procesando =
                                procesandoId === solicitud.id;

                            return (
                                <tr key={solicitud.id}>
                                    <td>
                                        <strong>
                                            {solicitud.placa ||
                                                "Sin placa"}
                                        </strong>
                                    </td>

                                    <td>
                                        {solicitud.usuario_username ||
                                            solicitud.usuario ||
                                            "Sin usuario"}
                                    </td>

                                    <td>
                                            <span className="text-muted">
                                                {solicitud.motivo ||
                                                    "Sin motivo"}
                                            </span>
                                    </td>

                                    <td>
                                            <span
                                                className={claseEstado(
                                                    solicitud.estado
                                                )}
                                            >
                                                {textoEstado(solicitud.estado)}
                                            </span>
                                    </td>

                                    <td>
                                        {formatearFecha(
                                            solicitud.fecha_solicitud
                                        )}
                                    </td>

                                    <td>
                                        {documentoUrl ? (
                                            <a
                                                href={documentoUrl}
                                                target="_blank"
                                                rel="noreferrer"
                                            >
                                                Ver documento
                                            </a>
                                        ) : (
                                            "Sin documento"
                                        )}
                                    </td>

                                    <td>
                                        {solicitud.respuesta_admin ||
                                            "Sin respuesta"}
                                    </td>

                                    <td>
                                        {estaPendiente ? (
                                            <div className="actions">
                                                <button
                                                    type="button"
                                                    className="btn btn-success"
                                                    onClick={() =>
                                                        aprobar(solicitud)
                                                    }
                                                    disabled={procesando}
                                                >
                                                    Aprobar
                                                </button>

                                                <button
                                                    type="button"
                                                    className="btn btn-danger"
                                                    onClick={() =>
                                                        rechazar(solicitud)
                                                    }
                                                    disabled={procesando}
                                                >
                                                    Rechazar
                                                </button>
                                            </div>
                                        ) : (
                                            <span className="text-muted">
                                                    Revisada
                                                </span>
                                        )}
                                    </td>
                                </tr>
                            );
                        })}
                        </tbody>
                    </table>
                </div>
            )}
        </div>
    );
}