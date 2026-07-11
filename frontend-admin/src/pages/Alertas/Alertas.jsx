import {useEffect, useState} from "react";
import {
    obtenerAlertas,
    marcarAlertaRevisada,
    derivarAlertaAutoridad,
    cerrarAlerta,
    descartarAlerta,
} from "../../api/seguridadService.js";
import "../Styles/Alertas.css";
import ModuleHeader from "../../components/ModuleHeader/ModuleHeader";

function Alertas() {
    const [alertas, setAlertas] = useState([]);
    const [cargando, setCargando] = useState(true);
    const [error, setError] = useState("");
    const [mensaje, setMensaje] = useState("");

    const cargarAlertas = async () => {
        try {
            setCargando(true);
            setError("");
            setMensaje("");

            const data = await obtenerAlertas();

            if (Array.isArray(data)) {
                setAlertas(data);
            } else if (data.results) {
                setAlertas(data.results);
            } else {
                setAlertas([]);
            }
        } catch (error) {
            setError("No se pudieron cargar las alertas.");
        } finally {
            setCargando(false);
        }
    };

    useEffect(() => {
        cargarAlertas();
    }, []);

    const ejecutarAccion = async (accion, id, textoExito) => {
        try {
            setError("");
            setMensaje("");

            await accion(id);

            setMensaje(textoExito);
            await cargarAlertas();
        } catch (error) {
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

    const obtenerPlaca = (alerta) => {
        return (
            alerta.vehiculo_placa ||
            alerta.placa ||
            alerta.vehiculo?.placa ||
            alerta.vehiculo ||
            "Sin dato"
        );
    };

    const obtenerVehiculo = (alerta) => {
        return (
            alerta.vehiculo_nombre ||
            alerta.vehiculo_detalle ||
            alerta.vehiculo ||
            obtenerPlaca(alerta)
        );
    };

    const obtenerPeaje = (alerta) => {
        return (
            alerta.peaje_nombre ||
            alerta.peaje?.nombre ||
            alerta.peaje ||
            "Sin dato"
        );
    };

    const obtenerUrlMaps = (alerta) => {
        return (
            alerta.url_maps ||
            alerta.ubicacion?.url_maps ||
            alerta.ubicacion_deteccion?.url_maps ||
            alerta.ubicaciondeteccion?.url_maps ||
            null
        );
    };

    const alertaBloqueada = (estado) => {
        return estado === "cerrada" || estado === "descartada";
    };

    if (cargando) {
        return (
            <div className="alertas-page">
                <h2>Alertas de Seguridad</h2>
                <p>Cargando alertas...</p>
            </div>
        );
    }

    return (
        <div className="alertas-page">

            <ModuleHeader
                icon="🚨"
                title="Alertas de seguridad"
                subtitle="Gestiona alertas generadas por vehículos reportados o eventos sospechosos."
                badge="Seguridad"
                status="Monitoreo activo"
                actions={
                <>
                <button
                    className="module-header-secondary"
                    onClick={cargarAlertas}
                >
                    Actualizar
                </button>
                </>
                }
            />



            {error && <div className="alertas-error">{error}</div>}
            {mensaje && <div className="alertas-success">{mensaje}</div>}

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
                        <th>Descripción</th>
                        <th>Acciones</th>
                    </tr>
                    </thead>

                    <tbody>
                    {alertas.length > 0 ? (
                        alertas.map((alerta) => {
                            const urlMaps = obtenerUrlMaps(alerta);

                            return (
                                <tr key={alerta.id}>

                                    <td>
                                        <strong className="placa-alerta">
                                            {obtenerPlaca(alerta)}
                                        </strong>
                                    </td>

                                    <td>{obtenerVehiculo(alerta)}</td>

                                    <td>{obtenerPeaje(alerta)}</td>

                                    <td>
                                        {alerta.tipo_alerta === "vehiculo_robado"
                                            ? "Vehículo robado"
                                            : alerta.tipo_alerta || "Alerta"}
                                    </td>

                                    <td>
                      <span className={obtenerClaseEstado(alerta.estado)}>
                        {alerta.estado || "pendiente"}
                      </span>
                                    </td>

                                    <td>
                                        {alerta.fecha_hora
                                            ? new Date(alerta.fecha_hora).toLocaleString()
                                            : "Sin fecha"}
                                    </td>

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
        </div>
    );
}

export default Alertas;