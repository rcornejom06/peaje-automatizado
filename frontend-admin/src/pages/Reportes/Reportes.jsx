import {useEffect, useState} from "react";
import * as XLSX from "xlsx";
import {
    obtenerResumen,
    obtenerRecaudacion,
    obtenerPasosPorPeaje,
    obtenerAlertasReporte,
    obtenerVehiculosDetectados,
    obtenerUsoMembresias,
} from "../../api/reportesService";
import "../Styles/Reportes.css";
import ModuleHeader from "../../components/ModuleHeader/ModuleHeader";


function Reportes() {
    const [tab, setTab] = useState("recaudacion");
    const [cargando, setCargando] = useState(false);
    const [error, setError] = useState("");

    const [filtros, setFiltros] = useState({
        fecha_inicio: "",
        fecha_fin: "",
    });

    const [resumen, setResumen] = useState(null);
    const [recaudacion, setRecaudacion] = useState(null);
    const [pasosPorPeaje, setPasosPorPeaje] = useState([]);
    const [alertas, setAlertas] = useState(null);
    const [vehiculosDetectados, setVehiculosDetectados] = useState(null);
    const [usoMembresias, setUsoMembresias] = useState(null);

    const cargarReportes = async (filtrosActuales = filtros) => {
        try {
            setCargando(true);
            setError("");

            const [
                resumenData,
                recaudacionData,
                pasosData,
                alertasData,
                vehiculosData,
                usoMembresiasData,
            ] = await Promise.all([
                obtenerResumen(filtrosActuales),
                obtenerRecaudacion(filtrosActuales),
                obtenerPasosPorPeaje(filtrosActuales),
                obtenerAlertasReporte(filtrosActuales),
                obtenerVehiculosDetectados(filtrosActuales),
                obtenerUsoMembresias(filtrosActuales),
            ]);

            setResumen(resumenData);
            setRecaudacion(recaudacionData);
            setPasosPorPeaje(Array.isArray(pasosData) ? pasosData : []);
            setAlertas(alertasData);
            setVehiculosDetectados(vehiculosData);
            setUsoMembresias(usoMembresiasData);
        } finally {
            setCargando(false);
        }
    };

    useEffect(() => {
        cargarReportes();
    }, []);

    const handleFiltroChange = (e) => {
        setFiltros({
            ...filtros,
            [e.target.name]: e.target.value,
        });
    };

    const limpiarFiltros = async () => {
        const filtrosLimpios = {
            fecha_inicio: "",
            fecha_fin: "",
        };

        setFiltros(filtrosLimpios);
        await cargarReportes(filtrosLimpios);
    };
    const valorSeguro = (valor, defecto = "") => {
        if (valor === null || valor === undefined || valor === "") {
            return defecto;
        }

        return valor;
    };

    const formatearFechaExcel = (fecha) => {
        if (!fecha) return "Sin fecha";

        try {
            return new Date(fecha).toLocaleString();
        } catch {
            return fecha;
        }
    };

    const nombreArchivoFecha = () => {
        const ahora = new Date();

        const yyyy = ahora.getFullYear();
        const mm = String(ahora.getMonth() + 1).padStart(2, "0");
        const dd = String(ahora.getDate()).padStart(2, "0");
        const hh = String(ahora.getHours()).padStart(2, "0");
        const mi = String(ahora.getMinutes()).padStart(2, "0");

        return `${yyyy}-${mm}-${dd}_${hh}-${mi}`;
    };

    const agregarHoja = (workbook, nombre, data) => {
        const filas = Array.isArray(data) && data.length > 0
            ? data
            : [{Mensaje: "Sin datos disponibles"}];

        const worksheet = XLSX.utils.json_to_sheet(filas);

        const nombreSeguro = nombre
            .replace(/[\\/?*[\]:]/g, "")
            .substring(0, 31);

        XLSX.utils.book_append_sheet(workbook, worksheet, nombreSeguro);
    };

    const descargarReporteExcel = () => {
        const workbook = XLSX.utils.book_new();


        agregarHoja(workbook, "Recaudación", [
            {
                "Recaudación por peajes": valorSeguro(recaudacion?.recaudacion_peajes, 0),
                "Recaudación por membresías": valorSeguro(
                    recaudacion?.recaudacion_membresias,
                    0
                ),
                "Total recaudado": valorSeguro(recaudacion?.recaudacion_total, 0),
                "Recargas billetera": valorSeguro(recaudacion?.recargas_billetera, 0),
                "Pagos por billetera": valorSeguro(recaudacion?.pagos_por_billetera, 0),
                "Usos de membresía": valorSeguro(recaudacion?.usos_membresia, 0),
                "Transacciones aprobadas": valorSeguro(
                    recaudacion?.transacciones_aprobadas,
                    0
                ),
                "Transacciones fallidas": valorSeguro(
                    recaudacion?.transacciones_fallidas,
                    0
                ),
                Nota: valorSeguro(recaudacion?.nota, ""),
            },
        ]);

        agregarHoja(
            workbook,
            "Pasos por peaje",
            pasosPorPeaje.map((item) => ({
                Peaje: item.peaje_nombre || item.peaje__nombre || "Sin peaje",
                Ciudad: item.peaje_ciudad || item.peaje__ciudad || "Sin ciudad",
                "Total pasos": valorSeguro(item.total_pasos, 0),
                "Vehículos distintos": valorSeguro(item.vehiculos_distintos, 0),
                Pagados: valorSeguro(item.pagados, 0),
                Membresía: valorSeguro(item.membresia, 0),
                Pendientes: valorSeguro(item.pendientes, 0),
                Fallidos: valorSeguro(item.fallidos, 0),
                Alertas: valorSeguro(item.alertas, 0),
            }))
        );


        agregarHoja(
            workbook,
            "Últimas alertas",
            alertas?.ultimas_alertas?.map((item) => ({
                ID: item.id,
                Placa: item.placa || "Sin placa",
                Peaje: item.peaje || "Sin peaje",
                Tipo: item.tipo_alerta,
                Estado: item.estado,
                Fecha: formatearFechaExcel(item.fecha_hora),
            })) || []
        );

        agregarHoja(workbook, "Vehículos detectados", [
            {
                "Total detecciones": valorSeguro(
                    vehiculosDetectados?.total_detecciones,
                    0
                ),
                "Vehículos distintos": valorSeguro(
                    vehiculosDetectados?.vehiculos_distintos,
                    0
                ),
            },
        ]);


        agregarHoja(workbook, "Uso membresías", [
            {
                "Pasos cubiertos por membresía": valorSeguro(
                    usoMembresias?.total_pasos_cubiertos_por_membresia,
                    0
                ),
                "Membresías activas": valorSeguro(
                    usoMembresias?.membresias_activas,
                    0
                ),
            },
        ]);


        XLSX.writeFile(
            workbook,
            `reporte_general_peaje_${nombreArchivoFecha()}.xlsx`
        );
    };

    const formatoDinero = (valor) => {
        const numero = Number(valor || 0);
        return `$${numero.toFixed(2)}`;
    };

    return (
        <div className="reportes-page">
            <ModuleHeader
                icon="📈"
                title="Reportes del sistema"
                subtitle="Genera reportes operativos, financieros y de uso del sistema."
                badge="Analítica"
                status="Datos actualizados"
                actions={
                    <>
                        <button className="btn-primary" onClick={descargarReporteExcel}>
                            Descargar reporte completo
                        </button>
                        <button
                            className="btn-secondary"
                            onClick={() => cargarReportes()}
                        >
                            Actualizar reportes
                        </button>

                    </>

                }

            />

            {error && <div className="reportes-error">{error}</div>}

            <div className="filtros-card">
                <div className="form-group">
                    <label>Fecha inicio</label>
                    <input
                        type="date"
                        name="fecha_inicio"
                        value={filtros.fecha_inicio}
                        onChange={handleFiltroChange}
                    />
                </div>


                <div className="filtros-actions">
                    <button className="btn-primary" onClick={() => cargarReportes()}>
                        Aplicar filtros
                    </button>

                    <button className="btn-secondary" onClick={limpiarFiltros}>
                        Limpiar
                    </button>
                </div>
            </div>

            {cargando && <p>Cargando reportes...</p>}

            <div className="tabs">


                <button
                    className={tab === "recaudacion" ? "active" : ""}
                    onClick={() => setTab("recaudacion")}
                >
                    Recaudación
                </button>

                <button
                    className={tab === "pasos" ? "active" : ""}
                    onClick={() => setTab("pasos")}
                >
                    Pasos por peaje
                </button>

                <button
                    className={tab === "alertas" ? "active" : ""}
                    onClick={() => setTab("alertas")}
                >
                    Alertas
                </button>

                <button
                    className={tab === "vehiculos" ? "active" : ""}
                    onClick={() => setTab("vehiculos")}
                >
                    Vehículos detectados
                </button>

                <button
                    className={tab === "membresias" ? "active" : ""}
                    onClick={() => setTab("membresias")}
                >
                    Uso de membresías
                </button>
            </div>


            {tab === "recaudacion" && (
                <div className="report-section">
                    <h3>Reporte de recaudación</h3>

                    <div className="stats-grid">
                        <div className="stat-card money">
                            <span>Recaudación por peajes</span>
                            <strong>{formatoDinero(recaudacion?.recaudacion_peajes)}</strong>
                        </div>

                        <div className="stat-card money">
                            <span>Recaudación por membresías</span>
                            <strong>{formatoDinero(recaudacion?.recaudacion_membresias)}</strong>
                        </div>

                        <div className="stat-card money">
                            <span>Total recaudado</span>
                            <strong>{formatoDinero(recaudacion?.recaudacion_total)}</strong>
                        </div>

                        <div className="stat-card money">
                            <span>Recargas billetera</span>
                            <strong>{formatoDinero(recaudacion?.recargas_billetera)}</strong>
                        </div>

                        <div className="stat-card money">
                            <span>Pagos por billetera</span>
                            <strong>{formatoDinero(recaudacion?.pagos_por_billetera)}</strong>
                        </div>

                        <div className="stat-card">
                            <span>Usos de membresía</span>
                            <strong>{recaudacion?.usos_membresia ?? 0}</strong>
                        </div>

                        <div className="stat-card success">
                            <span>Transacciones aprobadas</span>
                            <strong>{recaudacion?.transacciones_aprobadas ?? 0}</strong>
                        </div>

                        <div className="stat-card danger">
                            <span>Transacciones fallidas</span>
                            <strong>{recaudacion?.transacciones_fallidas ?? 0}</strong>
                        </div>
                    </div>

                    {recaudacion?.nota && (
                        <div className="nota-card">{recaudacion.nota}</div>
                    )}
                </div>
            )}

            {tab === "pasos" && (
                <div className="report-section">
                    <h3>Pasos por peaje</h3>

                    <div className="table-card">
                        <table>
                            <thead>
                            <tr>
                                <th>Peaje</th>
                                <th>Ciudad</th>
                                <th>Total pasos</th>
                                <th>Vehículos distintos</th>
                                <th>Pagados</th>
                                <th>Membresía</th>
                                <th>Pendientes</th>
                                <th>Fallidos</th>
                                <th>Alertas</th>
                            </tr>
                            </thead>

                            <tbody>
                            {pasosPorPeaje.length > 0 ? (
                                pasosPorPeaje.map((item) => (
                                    <tr key={item.peaje_id || item.peaje__id}>
                                        <td>{item.peaje_nombre || item.peaje__nombre || "Sin peaje"}</td>
                                        <td>{item.peaje_ciudad || item.peaje__ciudad || "Sin ciudad"}</td>
                                        <td>{item.total_pasos}</td>
                                        <td>{item.vehiculos_distintos}</td>
                                        <td>{item.pagados ?? 0}</td>
                                        <td>{item.membresia ?? 0}</td>
                                        <td>{item.pendientes ?? 0}</td>
                                        <td>{item.fallidos ?? 0}</td>
                                        <td>{item.alertas ?? 0}</td>
                                    </tr>
                                ))
                            ) : (
                                <tr>
                                    <td colSpan="9">No existen registros de pasos por peaje.</td>
                                </tr>
                            )}
                            </tbody>
                        </table>
                    </div>
                </div>
            )}

            {tab === "alertas" && (
                <div className="report-section">
                    <h3>Reporte de alertas</h3>

                    <div className="stats-grid">
                        <div className="stat-card danger">
                            <span>Total alertas</span>
                            <strong>{alertas?.total_alertas ?? 0}</strong>
                        </div>
                    </div>

                    <h4>Alertas por estado</h4>

                    <div className="table-card">
                        <table>
                            <thead>
                            <tr>
                                <th>Estado</th>
                                <th>Total</th>
                            </tr>
                            </thead>

                            <tbody>
                            {alertas?.por_estado?.length > 0 ? (
                                alertas.por_estado.map((item) => (
                                    <tr key={item.estado}>
                                        <td>{item.estado}</td>
                                        <td>{item.total}</td>
                                    </tr>
                                ))
                            ) : (
                                <tr>
                                    <td colSpan="2">No existen alertas por estado.</td>
                                </tr>
                            )}
                            </tbody>
                        </table>
                    </div>

                    <h4>Alertas por peaje</h4>

                    <div className="table-card">
                        <table>
                            <thead>
                            <tr>
                                <th>Peaje</th>
                                <th>Total alertas</th>
                            </tr>
                            </thead>

                            <tbody>
                            {alertas?.por_peaje?.length > 0 ? (
                                alertas.por_peaje.map((item) => (
                                    <tr key={item.peaje__id || item.peaje_id}>
                                        <td>{item.peaje__nombre || item.peaje_nombre || "Sin peaje"}</td>
                                        <td>{item.total_alertas}</td>
                                    </tr>
                                ))
                            ) : (
                                <tr>
                                    <td colSpan="2">No existen alertas por peaje.</td>
                                </tr>
                            )}
                            </tbody>
                        </table>
                    </div>

                    <h4>Últimas alertas</h4>

                    <div className="table-card">
                        <table>
                            <thead>
                            <tr>
                                <th>ID</th>
                                <th>Placa</th>
                                <th>Peaje</th>
                                <th>Tipo</th>
                                <th>Estado</th>
                                <th>Fecha</th>
                            </tr>
                            </thead>

                            <tbody>
                            {alertas?.ultimas_alertas?.length > 0 ? (
                                alertas.ultimas_alertas.map((item) => (
                                    <tr key={item.id}>
                                        <td>{item.id}</td>
                                        <td>{item.placa || "Sin placa"}</td>
                                        <td>{item.peaje || "Sin peaje"}</td>
                                        <td>{item.tipo_alerta}</td>
                                        <td>{item.estado}</td>
                                        <td>
                                            {item.fecha_hora
                                                ? new Date(item.fecha_hora).toLocaleString()
                                                : "Sin fecha"}
                                        </td>
                                    </tr>
                                ))
                            ) : (
                                <tr>
                                    <td colSpan="6">No existen últimas alertas.</td>
                                </tr>
                            )}
                            </tbody>
                        </table>
                    </div>
                </div>
            )}

            {tab === "vehiculos" && (
                <div className="report-section">
                    <h3>Vehículos detectados</h3>

                    <div className="stats-grid">
                        <div className="stat-card">
                            <span>Total detecciones</span>
                            <strong>{vehiculosDetectados?.total_detecciones ?? 0}</strong>
                        </div>

                        <div className="stat-card">
                            <span>Vehículos distintos</span>
                            <strong>{vehiculosDetectados?.vehiculos_distintos ?? 0}</strong>
                        </div>
                    </div>

                    <h4>Top vehículos detectados</h4>

                    <div className="table-card">
                        <table>
                            <thead>
                            <tr>
                                <th>Placa</th>
                                <th>Total detecciones</th>
                            </tr>
                            </thead>

                            <tbody>
                            {vehiculosDetectados?.top_vehiculos_detectados?.length > 0 ? (
                                vehiculosDetectados.top_vehiculos_detectados.map((item) => (
                                    <tr key={item.placa_detectada}>
                                        <td>{item.placa_detectada}</td>
                                        <td>{item.total_detecciones}</td>
                                    </tr>
                                ))
                            ) : (
                                <tr>
                                    <td colSpan="2">No existen vehículos detectados.</td>
                                </tr>
                            )}
                            </tbody>
                        </table>
                    </div>

                    <h4>Últimas detecciones</h4>

                    <div className="table-card">
                        <table>
                            <thead>
                            <tr>
                                <th>ID</th>
                                <th>Placa</th>
                                <th>Vehículo</th>
                                <th>Peaje</th>
                                <th>Cámara</th>
                                <th>Pago</th>
                                <th>Seguridad</th>
                                <th>Tarifa</th>
                                <th>Fecha</th>
                            </tr>
                            </thead>

                            <tbody>
                            {vehiculosDetectados?.ultimas_detecciones?.length > 0 ? (
                                vehiculosDetectados.ultimas_detecciones.map((item) => (
                                    <tr key={item.id}>
                                        <td>{item.id}</td>
                                        <td>{item.placa_detectada}</td>
                                        <td>{item.vehiculo || "No registrado"}</td>
                                        <td>{item.peaje || "Sin peaje"}</td>
                                        <td>{item.camara || "Sin cámara"}</td>
                                        <td>{item.estado_pago}</td>
                                        <td>{item.estado_seguridad}</td>
                                        <td>{formatoDinero(item.tarifa_aplicada)}</td>
                                        <td>
                                            {item.fecha_hora
                                                ? new Date(item.fecha_hora).toLocaleString()
                                                : "Sin fecha"}
                                        </td>
                                    </tr>
                                ))
                            ) : (
                                <tr>
                                    <td colSpan="9">No existen últimas detecciones.</td>
                                </tr>
                            )}
                            </tbody>
                        </table>
                    </div>
                </div>
            )}

            {tab === "membresias" && (
                <div className="report-section">
                    <h3>Uso de membresías</h3>

                    <div className="stats-grid">
                        <div className="stat-card">
                            <span>Pasos cubiertos por membresía</span>
                            <strong>
                                {usoMembresias?.total_pasos_cubiertos_por_membresia ?? 0}
                            </strong>
                        </div>

                        <div className="stat-card">
                            <span>Membresías activas</span>
                            <strong>{usoMembresias?.membresias_activas ?? 0}</strong>
                        </div>

                        <div className="stat-card">
                            <span>Pases restantes</span>
                            <strong>{usoMembresias?.pases_restantes_totales ?? 0}</strong>
                        </div>
                    </div>

                    <h4>Uso por plan</h4>

                    <div className="table-card">
                        <table>
                            <thead>
                            <tr>
                                <th>Plan</th>
                                <th>Total usos</th>
                            </tr>
                            </thead>

                            <tbody>
                            {usoMembresias?.uso_por_plan?.length > 0 ? (
                                usoMembresias.uso_por_plan.map((item, index) => (
                                    <tr key={index}>
                                        <td>
                                            {item.membresia_utilizada__plan__nombre || "Sin plan"}
                                        </td>
                                        <td>{item.total_usos}</td>
                                    </tr>
                                ))
                            ) : (
                                <tr>
                                    <td colSpan="2">No existen usos de membresía.</td>
                                </tr>
                            )}
                            </tbody>
                        </table>
                    </div>

                    <h4>Membresías activas</h4>

                    <div className="table-card">
                        <table>
                            <thead>
                            <tr>
                                <th>ID</th>
                                <th>Usuario</th>
                                <th>Plan</th>
                                <th>Estado</th>
                                <th>Pases restantes</th>
                                <th>Inicio</th>
                                <th>Fin</th>
                            </tr>
                            </thead>

                            <tbody>
                            {usoMembresias?.membresias?.length > 0 ? (
                                usoMembresias.membresias.map((item) => (
                                    <tr key={item.id}>
                                        <td>{item.id}</td>
                                        <td>{item.usuario}</td>
                                        <td>{item.plan}</td>
                                        <td>{item.estado}</td>
                                        <td>{item.pases_restantes}</td>
                                        <td>{item.fecha_inicio}</td>
                                        <td>
                                            {item.pases_restantes > 0
                                                ? `Agotamiento de pases (${item.pases_restantes} restantes)`
                                                : "Pases agotados"}
                                        </td>
                                    </tr>
                                ))
                            ) : (
                                <tr>
                                    <td colSpan="7">No existen membresías activas.</td>
                                </tr>
                            )}
                            </tbody>
                        </table>
                    </div>
                </div>
            )}
        </div>
    );
}

export default Reportes;
