import {useEffect, useMemo, useState} from "react";
import {
    aprobarVehiculo,
    obtenerVehiculos,
    rechazarVehiculo,
    obtenerDocumentoBlob,
} from "../../api/vehiculosService";
import "../Styles/Vehiculos.css";

const estadosRevision = {
    en_revision: "En revisión",
    aprobado: "Aprobado",
    rechazado: "Rechazado",
};

function Vehiculos() {
    const [vehiculos, setVehiculos] = useState([]);
    const [busqueda, setBusqueda] = useState("");
    const [cargando, setCargando] = useState(true);
    const [procesandoId, setProcesandoId] = useState(null);
    const [vehiculoSeleccionado, setVehiculoSeleccionado] = useState(null);
    const [error, setError] = useState("");
    const [mensaje, setMensaje] = useState("");
    const [documentoBlobUrl, setDocumentoBlobUrl] = useState(null);
    const [cargandoDocumento, setCargandoDocumento] = useState(false);
    const [errorDocumento, setErrorDocumento] = useState("");

    const cargarVehiculos = async () => {
        try {
            setCargando(true);
            setError("");
            setMensaje("");

            const data = await obtenerVehiculos();

            if (Array.isArray(data)) {
                setVehiculos(data);
            } else if (data.results) {
                setVehiculos(data.results);
            } else {
                setVehiculos([]);
            }
        } catch (error) {
            console.error("Error cargando vehículos:", error);

            setError(
                error.response?.data?.detail ||
                error.response?.data?.error ||
                error.message ||
                "No se pudieron cargar los vehículos."
            );
        } finally {
            setCargando(false);
        }
    };

    useEffect(() => {
        cargarVehiculos();
    }, []);

    useEffect(() => {
        let urlActual = null;

        const cargarDocumento = async () => {
            const url = obtenerDocumentoUrl(vehiculoSeleccionado);

            if (!vehiculoSeleccionado || !url) {
                setDocumentoBlobUrl(null);
                return;
            }

            try {
                setCargandoDocumento(true);
                setErrorDocumento("");

                const blob = await obtenerDocumentoBlob(url);
                urlActual = URL.createObjectURL(blob);
                setDocumentoBlobUrl(urlActual);
            } catch (error) {
                console.error("Error cargando documento:", error);
                setErrorDocumento("No se pudo cargar el documento.");
                setDocumentoBlobUrl(null);
            } finally {
                setCargandoDocumento(false);
            }
        };

        cargarDocumento();

        return () => {
            if (urlActual) {
                URL.revokeObjectURL(urlActual);
            }
        };
    }, [vehiculoSeleccionado]);

    const vehiculosFiltrados = useMemo(() => {
        const texto = busqueda.toLowerCase().trim();

        if (!texto) {
            return vehiculos;
        }

        return vehiculos.filter((vehiculo) => {
            const placa = vehiculo.placa?.toLowerCase() || "";
            const marca = vehiculo.marca?.toLowerCase() || "";
            const modelo = vehiculo.modelo?.toLowerCase() || "";
            const usuario = vehiculo.usuario_username?.toLowerCase() || "";
            const categoria = vehiculo.categoria_nombre?.toLowerCase() || "";
            const estadoRevision = vehiculo.estado_revision?.toLowerCase() || "";

            return (
                placa.includes(texto) ||
                marca.includes(texto) ||
                modelo.includes(texto) ||
                usuario.includes(texto) ||
                categoria.includes(texto) ||
                estadoRevision.includes(texto)
            );
        });
    }, [busqueda, vehiculos]);

    const obtenerDocumentoUrl = (vehiculo) => {
        return vehiculo?.documento_respaldo_url || vehiculo?.documento_respaldo || "";
    };

    const obtenerEstadoRevision = (vehiculo) => {
        return vehiculo?.estado_revision || "en_revision";
    };

    const textoEstadoRevision = (vehiculo) => {
        const estado = obtenerEstadoRevision(vehiculo);
        return estadosRevision[estado] || estado;
    };

    const obtenerUsuario = (vehiculo) => {
        if (vehiculo?.usuario_detalle?.username) {
            return vehiculo.usuario_detalle.username;
        }

        if (vehiculo?.usuario_username) {
            return vehiculo.usuario_username;
        }

        return vehiculo?.usuario || "Sin usuario";
    };

    const obtenerNombreUsuario = (vehiculo) => {
        const usuario = vehiculo?.usuario_detalle;

        if (!usuario) {
            return "Sin dato";
        }

        const nombres = `${usuario.first_name || ""} ${usuario.last_name || ""}`.trim();

        return nombres || usuario.username || "Sin dato";
    };

    const obtenerCorreoUsuario = (vehiculo) => {
        return vehiculo?.usuario_detalle?.email || vehiculo?.usuario_email || "Sin dato";
    };

    const obtenerTelefonoUsuario = (vehiculo) => {
        return (
            vehiculo?.perfil_usuario?.telefono ||
            vehiculo?.usuario_detalle?.telefono ||
            vehiculo?.telefono ||
            "Sin dato"
        );
    };

    const obtenerCedulaUsuario = (vehiculo) => {
        return (
            vehiculo?.perfil_usuario?.cedula ||
            vehiculo?.usuario_detalle?.cedula ||
            vehiculo?.cedula ||
            "Sin dato"
        );
    };

    const abrirModalDocumento = (vehiculo) => {
        console.log("Vehículo seleccionado:", vehiculo);

        setVehiculoSeleccionado(vehiculo);
        setError("");
        setMensaje("");
    };

    const cerrarModalDocumento = () => {
        setVehiculoSeleccionado(null);
    };

    const aprobar = async (vehiculo) => {
        const motivo = window.prompt(
            `Motivo de aprobación para ${vehiculo.placa}:`,
            "Documento de respaldo validado correctamente."
        );

        if (motivo === null) return;

        const confirmar = window.confirm(
            `¿Desea aprobar el vehículo ${vehiculo.placa}?`
        );

        if (!confirmar) return;

        try {
            setProcesandoId(vehiculo.id);
            setError("");
            setMensaje("");

            const data = await aprobarVehiculo(vehiculo.id, motivo);

            setMensaje(data.mensaje || "Vehículo aprobado correctamente.");
            cerrarModalDocumento();
            await cargarVehiculos();
        } catch (error) {
            setError(
                error.response?.data?.error ||
                error.response?.data?.detail ||
                "No se pudo aprobar el vehículo."
            );
        } finally {
            setProcesandoId(null);
        }
    };

    const rechazar = async (vehiculo) => {
        const motivo = window.prompt(
            `Motivo de rechazo para ${vehiculo.placa}:`,
            vehiculo.motivo_revision || ""
        );

        if (motivo === null) return;

        if (!motivo.trim()) {
            setError("Debe ingresar un motivo para rechazar el vehículo.");
            return;
        }

        const confirmar = window.confirm(
            `¿Desea rechazar el vehículo ${vehiculo.placa}?`
        );

        if (!confirmar) return;

        try {
            setProcesandoId(vehiculo.id);
            setError("");
            setMensaje("");

            const data = await rechazarVehiculo(vehiculo.id, motivo);

            setMensaje(data.mensaje || "Vehículo rechazado correctamente.");
            cerrarModalDocumento();
            await cargarVehiculos();
        } catch (error) {
            setError(
                error.response?.data?.error ||
                error.response?.data?.detail ||
                "No se pudo rechazar el vehículo."
            );
        } finally {
            setProcesandoId(null);
        }
    };

    if (cargando) {
        return (
            <div className="vehiculos-page">
                <h2>Vehículos</h2>
                <p>Cargando vehículos...</p>
            </div>
        );
    }

    return (
        <div className="vehiculos-page">
            <div className="vehiculos-header">
                <div>
                    <h2>Vehículos registrados</h2>
                    <p>
                        Consulta, revisión, aprobación y rechazo de vehículos registrados por
                        los usuarios desde la app móvil.
                    </p>
                </div>

                <button className="btn-secondary" onClick={cargarVehiculos}>
                    Actualizar
                </button>
            </div>

            {mensaje && <div className="vehiculos-success">{mensaje}</div>}
            {error && <div className="vehiculos-error">{error}</div>}

            <div className="vehiculos-toolbar">
                <input
                    type="text"
                    value={busqueda}
                    onChange={(e) => setBusqueda(e.target.value)}
                    placeholder="Buscar por placa, marca, modelo, usuario, categoría o estado..."
                />
            </div>

            <div className="vehiculos-table-card">
                <table>
                    <thead>
                    <tr>
                        <th>Placa</th>
                        <th>Usuario</th>
                        <th>Marca</th>
                        <th>Modelo</th>
                        <th>Color</th>
                        <th>Año</th>
                        <th>Categoría</th>
                        <th>Tarifa</th>
                        <th>Estado revisión</th>
                        <th>Documento</th>
                        <th>Motivo</th>
                        <th>Acciones</th>
                    </tr>
                    </thead>

                    <tbody>
                    {vehiculosFiltrados.length > 0 ? (
                        vehiculosFiltrados.map((vehiculo) => {
                            const documentoUrl = obtenerDocumentoUrl(vehiculo);
                            const estadoRevision = obtenerEstadoRevision(vehiculo);
                            const procesando = procesandoId === vehiculo.id;

                            return (
                                <tr key={vehiculo.id}>
                                    <td>
                                        <strong>{vehiculo.placa}</strong>
                                    </td>
                                    <td>{obtenerUsuario(vehiculo)}</td>
                                    <td>{vehiculo.marca || "Sin dato"}</td>
                                    <td>{vehiculo.modelo || "Sin dato"}</td>
                                    <td>{vehiculo.color || "Sin dato"}</td>
                                    <td>{vehiculo.anio || "Sin dato"}</td>
                                    <td>{vehiculo.categoria_nombre || vehiculo.categoria}</td>
                                    <td>
                                        {vehiculo.categoria_tarifa
                                            ? `$${vehiculo.categoria_tarifa}`
                                            : "Sin tarifa"}
                                    </td>
                                    <td>
                      <span className={`estado-revision ${estadoRevision}`}>
                        {textoEstadoRevision(vehiculo)}
                      </span>
                                    </td>
                                    <td>
                                        {documentoUrl ? (
                                            <button
                                                type="button"
                                                onClick={() => abrirModalDocumento(vehiculo)}
                                                className="link-documento-btn"
                                            >
                                                Ver documento
                                            </button>
                                        ) : (
                                            <button
                                                type="button"
                                                onClick={() => abrirModalDocumento(vehiculo)}
                                                className="link-documento-btn sin-doc-btn"
                                            >
                                                Sin documento
                                            </button>
                                        )}
                                    </td>
                                    <td className="motivo-cell">
                                        {vehiculo.motivo_revision || "Sin motivo"}
                                    </td>
                                    <td>
                                        <div className="acciones-vehiculo">
                                            <button
                                                type="button"
                                                disabled={procesando || !documentoUrl}
                                                onClick={() => aprobar(vehiculo)}
                                                className="btn-aprobar"
                                            >
                                                Aprobar
                                            </button>

                                            <button
                                                type="button"
                                                disabled={procesando}
                                                onClick={() => rechazar(vehiculo)}
                                                className="btn-rechazar"
                                            >
                                                Rechazar
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                            );
                        })
                    ) : (
                        <tr>
                            <td colSpan="13">No existen vehículos registrados.</td>
                        </tr>
                    )}
                    </tbody>
                </table>
            </div>

            {vehiculoSeleccionado && (
                <div className="vehiculo-modal-overlay" onClick={cerrarModalDocumento}>
                    <div
                        className="vehiculo-modal"
                        onClick={(event) => event.stopPropagation()}
                    >
                        <div className="vehiculo-modal-header">
                            <div>
                                <h3>Validación del vehículo</h3>
                                <p>
                                    Placa: <strong>{vehiculoSeleccionado.placa}</strong>
                                </p>
                            </div>

                            <button
                                type="button"
                                className="vehiculo-modal-close"
                                onClick={cerrarModalDocumento}
                            >
                                ×
                            </button>
                        </div>

                        <div className="vehiculo-modal-grid">
                            <section className="vehiculo-modal-section">
                                <h4>Datos del usuario</h4>
                                <p>
                                    <strong>Usuario:</strong> {obtenerUsuario(vehiculoSeleccionado)}
                                </p>
                                <p>
                                    <strong>Nombre:</strong>{" "}
                                    {obtenerNombreUsuario(vehiculoSeleccionado)}
                                </p>
                                <p>
                                    <strong>Correo:</strong>{" "}
                                    {obtenerCorreoUsuario(vehiculoSeleccionado)}
                                </p>
                                <p>
                                    <strong>Teléfono:</strong>{" "}
                                    {obtenerTelefonoUsuario(vehiculoSeleccionado)}
                                </p>
                                <p>
                                    <strong>Cédula:</strong>{" "}
                                    {obtenerCedulaUsuario(vehiculoSeleccionado)}
                                </p>
                            </section>

                            <section className="vehiculo-modal-section">
                                <h4>Datos del vehículo</h4>
                                <p>
                                    <strong>Placa:</strong> {vehiculoSeleccionado.placa}
                                </p>
                                <p>
                                    <strong>Marca:</strong>{" "}
                                    {vehiculoSeleccionado.marca || "Sin dato"}
                                </p>
                                <p>
                                    <strong>Modelo:</strong>{" "}
                                    {vehiculoSeleccionado.modelo || "Sin dato"}
                                </p>
                                <p>
                                    <strong>Color:</strong>{" "}
                                    {vehiculoSeleccionado.color || "Sin dato"}
                                </p>
                                <p>
                                    <strong>Año:</strong>{" "}
                                    {vehiculoSeleccionado.anio || "Sin dato"}
                                </p>
                                <p>
                                    <strong>Categoría:</strong>{" "}
                                    {vehiculoSeleccionado.categoria_nombre ||
                                        vehiculoSeleccionado.categoria ||
                                        "Sin dato"}
                                </p>
                                <p>
                                    <strong>Estado:</strong>{" "}
                                    {textoEstadoRevision(vehiculoSeleccionado)}
                                </p>
                            </section>
                        </div>

                        <section className="vehiculo-modal-section">
                            <h4>Documento de respaldo</h4>

                            {!obtenerDocumentoUrl(vehiculoSeleccionado) ? (
                                <div className="documento-vacio">
                                    Este vehículo no tiene documento de respaldo adjunto.
                                </div>
                            ) : cargandoDocumento ? (
                                <div className="documento-vacio" style={{background: "#F1F5F9", color: "#475569"}}>
                                    Cargando documento...
                                </div>
                            ) : errorDocumento ? (
                                <div className="documento-vacio">{errorDocumento}</div>
                            ) : documentoBlobUrl ? (
                                <iframe
                                    src={documentoBlobUrl}
                                    title="Documento de respaldo"
                                    className="documento-preview"
                                />
                            ) : (
                                <div className="documento-vacio" style={{background: "#F1F5F9", color: "#475569"}}>
                                    Preparando vista previa del documento...
                                </div>
                            )}

                            {documentoBlobUrl && !cargandoDocumento && (
                                <a
                                    href={documentoBlobUrl}
                                    target="_blank"
                                    rel="noreferrer"
                                    className="documento-abrir"
                                >
                                    Abrir documento en otra pestaña
                                </a>
                            )}
                        </section>

                        <section className="vehiculo-modal-section">
                            <h4>Revisión administrativa</h4>

                            <p>
                                <strong>Motivo actual:</strong>{" "}
                                {vehiculoSeleccionado.motivo_revision || "Sin motivo"}
                            </p>

                            <div className="vehiculo-modal-actions">
                                <button
                                    type="button"
                                    disabled={
                                        procesandoId === vehiculoSeleccionado.id ||
                                        !obtenerDocumentoUrl(vehiculoSeleccionado)
                                    }
                                    onClick={() => aprobar(vehiculoSeleccionado)}
                                    className="btn-aprobar"
                                >
                                    Aprobar vehículo
                                </button>

                                <button
                                    type="button"
                                    disabled={procesandoId === vehiculoSeleccionado.id}
                                    onClick={() => rechazar(vehiculoSeleccionado)}
                                    className="btn-rechazar"
                                >
                                    Rechazar vehículo
                                </button>

                            </div>
                        </section>
                    </div>
                </div>
            )}
        </div>
    );
}

export default Vehiculos;