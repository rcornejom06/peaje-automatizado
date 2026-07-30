import {useEffect, useState} from "react";
import {
    obtenerHistorialAuditoria,
    obtenerResumenAuditoria,
} from "../../api/auditoriaService.js";
import "../Styles/Auditoria.css";
import ModuleHeader from "../../components/ModuleHeader/ModuleHeader.jsx";

// Fecha local (no UTC) en formato YYYY-MM-DD, para que el filtro por
// defecto sea "hoy" segun la hora del navegador del usuario, no la de UTC.
const obtenerFechaHoyLocal = () => {
    const ahora = new Date();
    const offsetMs = ahora.getTimezoneOffset() * 60000;
    const local = new Date(ahora.getTime() - offsetMs);
    return local.toISOString().slice(0, 10);
};

// Patrón de validación para los campos de texto de búsqueda (módulo y acción)
const REGEX_TEXTO_FILTRO = /^[A-Za-zÁÉÍÓÚÜáéíóúüÑñ0-9\s]*$/;

// Filtra caracteres mientras el usuario escribe (evita espacios repetidos y símbolos)
const filtrarTextoFiltro = (valor) =>
    String(valor)
        .replace(/[^A-Za-zÁÉÍÓÚÜáéíóúüÑñ0-9\s]/g, "")
        .replace(/\s{2,}/g, " ")
        .replace(/^\s+/, "");

function Auditoria() {
    const [historial, setHistorial] = useState([]);
    const [resumen, setResumen] = useState(null);
    const [cargando, setCargando] = useState(true);
    const [error, setError] = useState("");

    const [paginaActual, setPaginaActual] = useState(1);
    const registrosPorPagina = 10;

    // Un solo campo de fecha (no un rango): fecha_inicio y fecha_fin
    // siempre se mandan iguales, para filtrar "ese dia" exactamente.
    // Arranca en el dia de hoy en vez de mostrar todo el historial.
    const [filtros, setFiltros] = useState({
        fecha_inicio: obtenerFechaHoyLocal(),
        fecha_fin: obtenerFechaHoyLocal(),
        modulo: "",
        estado: "",
        accion: "",
    });

    const cargarAuditoria = async (filtrosActuales = filtros) => {
        try {
            setCargando(true);
            setError("");

            const [historialData, resumenData] = await Promise.all([
                obtenerHistorialAuditoria(filtrosActuales),
                obtenerResumenAuditoria(),
            ]);

            if (Array.isArray(historialData)) {
                setHistorial(historialData);
            } else if (historialData.results) {
                setHistorial(historialData.results);
            } else {
                setHistorial([]);
            }

            setPaginaActual(1);
            setResumen(resumenData);
        } catch {
            setError("No se pudo cargar el historial de auditoría.");
        } finally {
            setCargando(false);
        }
    };

    useEffect(() => {
        cargarAuditoria();
    }, []);

    const handleChange = (e) => {
        const {name, value} = e.target;
        let valorLimpio = value;

        if (name === "modulo" || name === "accion") {
            valorLimpio = filtrarTextoFiltro(value);
        }

        setFiltros({
            ...filtros,
            [name]: valorLimpio,
        });
    };

    const validarFiltros = () => {
        if (
            filtros.fecha_inicio &&
            filtros.fecha_fin &&
            filtros.fecha_inicio > filtros.fecha_fin
        ) {
            return "La fecha 'Desde' no puede ser posterior a la fecha 'Hasta'.";
        }

        return "";
    };

    const handleAplicarFiltros = () => {
        const errorValidacion = validarFiltros();

        if (errorValidacion) {
            setError(errorValidacion);
            return;
        }

        cargarAuditoria();
    };

    const limpiarFiltros = async () => {
        const filtrosLimpios = {
            fecha_inicio: "",
            fecha_fin: "",
            modulo: "",
            estado: "",
            accion: "",
        };

        setFiltros(filtrosLimpios);
        await cargarAuditoria(filtrosLimpios);
    };

    const obtenerClaseEstado = (estado) => {
        switch (estado) {
            case "exitoso":
                return "estado exitoso";
            case "fallido":
                return "estado fallido";
            case "pendiente":
                return "estado pendiente";
            default:
                return "estado";
        }
    };

    const totalPaginas = Math.ceil(historial.length / registrosPorPagina);

    const indiceInicial = (paginaActual - 1) * registrosPorPagina;
    const indiceFinal = indiceInicial + registrosPorPagina;

    const historialPaginado = historial.slice(indiceInicial, indiceFinal);

    const irPaginaAnterior = () => {
        setPaginaActual((pagina) => Math.max(pagina - 1, 1));
    };

    const irPaginaSiguiente = () => {
        setPaginaActual((pagina) => Math.min(pagina + 1, totalPaginas));
    };

    if (cargando) {
        return (
            <div className="auditoria-page">
                <h2>Auditoría</h2>
                <p>Cargando historial...</p>
            </div>
        );
    }

    return (
        <div className="auditoria-page">
            <ModuleHeader
                icon="🧾"
                title="Auditoría"
                subtitle="Revisa acciones, eventos y trazabilidad del sistema administrativo."
                badge="Trazabilidad"
                status="Registro activo"
                actions={
                    <>
                        <button
                            className="module-header-primary"
                            onClick={() => cargarAuditoria()}
                        >
                            Actualizar
                        </button>
                    </>
                }
            />

            {error && <div className="auditoria-error">{error}</div>}

            <div className="auditoria-summary">
                <div>
                    <span>Total registros</span>
                    <strong>{resumen?.total ?? historial.length}</strong>
                </div>

                <div>
                    <span>Exitosos</span>
                    <strong>{resumen?.exitosos ?? 0}</strong>
                </div>

                <div>
                    <span>Fallidos</span>
                    <strong>{resumen?.fallidos ?? 0}</strong>
                </div>

                <div>
                    <span>Pendientes</span>
                    <strong>{resumen?.pendientes ?? 0}</strong>
                </div>
            </div>

            <div className="auditoria-filtros">
                <div className="form-group">
                    <label>Desde</label>
                    <input
                        type="date"
                        name="fecha_inicio"
                        value={filtros.fecha_inicio}
                        onChange={handleChange}
                        max={filtros.fecha_fin || undefined}
                    />
                </div>

                <div className="form-group">
                    <label>Hasta</label>
                    <input
                        type="date"
                        name="fecha_fin"
                        value={filtros.fecha_fin}
                        onChange={handleChange}
                        min={filtros.fecha_inicio || undefined}
                    />
                </div>



                <div className="form-group">
                    <label>Módulo</label>
                    <input
                        type="text"
                        name="modulo"
                        placeholder="Peajes, Seguridad..."
                        value={filtros.modulo}
                        onChange={handleChange}
                        maxLength={50}
                    />
                </div>

                <div className="form-group">
                    <label>Estado</label>
                    <select
                        name="estado"
                        value={filtros.estado}
                        onChange={handleChange}
                    >
                        <option value="">Todos</option>
                        <option value="exitoso">Exitoso</option>
                        <option value="fallido">Fallido</option>
                        <option value="pendiente">Pendiente</option>
                    </select>
                </div>

                <div className="form-group">
                    <label>Acción</label>
                    <input
                        type="text"
                        name="accion"
                        placeholder="Registro, alerta, cierre..."
                        value={filtros.accion}
                        onChange={handleChange}
                        maxLength={50}
                    />
                </div>

                <div className="auditoria-actions">
                    <button className="btn-primary" onClick={handleAplicarFiltros}>
                        Aplicar filtros
                    </button>

                    <button className="btn-secondary" onClick={limpiarFiltros}>
                        Limpiar
                    </button>
                </div>
            </div>

            <div className="auditoria-table-card">
                <table>
                    <thead>
                    <tr>
                        <th>Fecha / Hora</th>
                        <th>Usuario</th>
                        <th>Acción</th>
                        <th>Módulo</th>
                        <th>Descripción</th>
                        <th>IP</th>
                        <th>Dispositivo</th>
                        <th>Estado</th>
                    </tr>
                    </thead>

                    <tbody>
                    {historialPaginado.length > 0 ? (
                        historialPaginado.map((item) => (
                            <tr key={item.id}>
                                <td>
                                    {item.fecha_hora
                                        ? new Date(item.fecha_hora).toLocaleString()
                                        : "Sin fecha"}
                                </td>

                                <td>
                                    {item.usuario_nombre ||
                                        item.usuario_username ||
                                        "Sistema"}
                                </td>

                                <td>{item.accion}</td>

                                <td>{item.modulo}</td>

                                <td className="descripcion-auditoria">
                                    {item.descripcion || "Sin descripción"}
                                </td>

                                <td>{item.direccion_ip || "Sin IP"}</td>

                                <td>{item.dispositivo || "API"}</td>

                                <td>
                    <span className={obtenerClaseEstado(item.estado)}>
                      {item.estado}
                    </span>
                                </td>
                            </tr>
                        ))
                    ) : (
                        <tr>
                            <td colSpan="8">No existen registros de auditoría.</td>
                        </tr>
                    )}
                    </tbody>
                </table>
            </div>

            {historial.length > registrosPorPagina && (
                <div className="auditoria-pagination">
                    <div>
                        Mostrando{" "}
                        <strong>
                            {indiceInicial + 1} - {Math.min(indiceFinal, historial.length)}
                        </strong>{" "}
                        de <strong>{historial.length}</strong> registros
                    </div>

                    <div className="auditoria-pagination-buttons">
                        <button
                            className="btn-secondary"
                            onClick={irPaginaAnterior}
                            disabled={paginaActual === 1}
                        >
                            Anterior
                        </button>

                        <span>
              Página <strong>{paginaActual}</strong> de{" "}
                            <strong>{totalPaginas}</strong>
            </span>

                        <button
                            className="btn-primary"
                            onClick={irPaginaSiguiente}
                            disabled={paginaActual === totalPaginas}
                        >
                            Siguiente
                        </button>
                    </div>
                </div>
            )}
        </div>
    );
}

export default Auditoria;
