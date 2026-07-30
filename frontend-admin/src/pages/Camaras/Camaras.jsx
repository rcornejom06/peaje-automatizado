import {useEffect, useState} from "react";
import {obtenerCamaras, crearCamara} from "../../api/camarasService";
import {obtenerPeajes} from "../../api/peajeService";
import "../Styles/Camaras.css";
import ModuleHeader from "../../components/ModuleHeader/ModuleHeader";

const fechaActual = () => new Date().toISOString().slice(0, 10);

// Patrones de validación por tipo de dato
const REGEX_CODIGO_CAMARA = /^[A-Z0-9-]{3,20}$/;
const REGEX_UBICACION = /^[A-Za-zÁÉÍÓÚÜáéíóúüÑñ0-9.,#-]+(?: [A-Za-zÁÉÍÓÚÜáéíóúüÑñ0-9.,#-]+)*$/;
const REGEX_TIPO_CAMARA = /^[A-Za-zÁÉÍÓÚÜáéíóúüÑñ0-9]+(?: [A-Za-zÁÉÍÓÚÜáéíóúüÑñ0-9]+)*$/;
const REGEX_INDICE_USB = /^\d+$/;
const REGEX_STREAM_URL = /^[A-Za-z0-9:/._\-?=&@%#~+]+$/;

// Filtra caracteres mientras el usuario escribe (evita espacios y símbolos no permitidos)
const filtrarCodigoCamara = (valor) =>
    String(valor)
        .toUpperCase()
        .replace(/[^A-Z0-9-]/g, "");

const filtrarUbicacion = (valor) =>
    String(valor)
        .replace(/[^A-Za-zÁÉÍÓÚÜáéíóúüÑñ0-9.,#-\s]/g, "")
        .replace(/\s{2,}/g, " ")
        .replace(/^\s+/, "");

const filtrarTipoCamara = (valor) =>
    String(valor)
        .replace(/[^A-Za-zÁÉÍÓÚÜáéíóúüÑñ0-9\s]/g, "")
        .replace(/\s{2,}/g, " ")
        .replace(/^\s+/, "");

const filtrarIndiceUsb = (valor) => String(valor).replace(/[^0-9]/g, "");

const filtrarStreamUrl = (valor) =>
    String(valor).replace(/[^A-Za-z0-9:/._\-?=&@%#~+]/g, "");

const normalizarLista = (data) => {
    if (Array.isArray(data)) return data;
    if (Array.isArray(data?.results)) return data.results;
    return [];
};

function Camaras() {
    const [camaras, setCamaras] = useState([]);
    const [peajes, setPeajes] = useState([]);
    const [cargando, setCargando] = useState(true);
    const [guardando, setGuardando] = useState(false);
    const [error, setError] = useState("");
    const [mensaje, setMensaje] = useState("");
    const [mostrarFormulario, setMostrarFormulario] = useState(false);

    const [formulario, setFormulario] = useState({
        codigo: "",
        peaje: "",
        ubicacion: "",
        tipo_camara: "ANPR",
        tipo_fuente: "usb",
        stream_url: "0",
        procesar_anpr: true,
        estado: "activa",
        fecha_instalacion: fechaActual(),
    });

    const cargarDatos = async () => {
        try {
            setCargando(true);
            setError("");
            setMensaje("");

            const [camarasData, peajesData] = await Promise.all([
                obtenerCamaras(),
                obtenerPeajes(),
            ]);

            setCamaras(normalizarLista(camarasData));
            setPeajes(normalizarLista(peajesData));
        } catch (error) {
            setError(
                error.response?.data?.detail ||
                error.response?.data?.error ||
                "No se pudieron cargar las cámaras."
            );
        } finally {
            setCargando(false);
        }
    };

    useEffect(() => {
        const iniciar = async () => {
            await cargarDatos();
        };

        iniciar();
    }, []);

    const handleChange = (e) => {
        const {name, type, checked, value} = e.target;

        let valorLimpio = value;

        switch (name) {
            case "codigo":
                valorLimpio = filtrarCodigoCamara(value);
                break;
            case "ubicacion":
                valorLimpio = filtrarUbicacion(value);
                break;
            case "tipo_camara":
                valorLimpio = filtrarTipoCamara(value);
                break;
            default:
                valorLimpio = value;
        }

        setFormulario((actual) => {
            let valorCampo = type === "checkbox" ? checked : valorLimpio;

            if (name === "stream_url") {
                valorCampo =
                    actual.tipo_fuente === "usb"
                        ? filtrarIndiceUsb(value)
                        : filtrarStreamUrl(value);
            }

            const nuevoFormulario = {
                ...actual,
                [name]: valorCampo,
            };

            if (name === "tipo_fuente") {
                if (value === "usb") {
                    nuevoFormulario.stream_url =
                        filtrarIndiceUsb(actual.stream_url) || "0";
                } else if (actual.stream_url === "0") {
                    nuevoFormulario.stream_url = "";
                }
            }

            return nuevoFormulario;
        });
    };

    const limpiarFormulario = () => {
        setFormulario({
            codigo: "",
            peaje: "",
            ubicacion: "",
            tipo_camara: "ANPR",
            tipo_fuente: "usb",
            stream_url: "0",
            procesar_anpr: true,
            estado: "activa",
            fecha_instalacion: fechaActual(),
        });
    };

    const construirPayload = () => {
        const streamUrl = formulario.stream_url?.toString().trim();

        return {
            codigo: formulario.codigo.trim(),
            peaje: Number(formulario.peaje),
            ubicacion: formulario.ubicacion.trim(),
            tipo_camara: formulario.tipo_camara.trim() || "ANPR",
            tipo_fuente: formulario.tipo_fuente,
            stream_url: formulario.tipo_fuente === "usb" ? streamUrl || "0" : streamUrl,
            procesar_anpr: Boolean(formulario.procesar_anpr),
            estado: formulario.estado,
            fecha_instalacion: formulario.fecha_instalacion || null,
        };
    };

    const handleSubmit = async (e) => {
        e.preventDefault();

        if (!formulario.codigo.trim()) {
            setError("Ingrese el código de la cámara.");
            return;
        }

        if (!REGEX_CODIGO_CAMARA.test(formulario.codigo.trim().toUpperCase())) {
            setError("El código debe tener entre 3 y 20 letras, números o guiones, sin espacios.");
            return;
        }

        if (!formulario.peaje) {
            setError("Debe seleccionar el peaje donde estará instalada la cámara.");
            return;
        }

        if (!formulario.ubicacion.trim()) {
            setError("Ingrese la ubicación de la cámara.");
            return;
        }

        if (!REGEX_UBICACION.test(formulario.ubicacion.trim())) {
            setError("La ubicación contiene caracteres no permitidos.");
            return;
        }

        if (!formulario.tipo_camara.trim()) {
            setError("Ingrese el tipo de cámara.");
            return;
        }

        if (!REGEX_TIPO_CAMARA.test(formulario.tipo_camara.trim())) {
            setError("El tipo de cámara solo puede contener letras, números y espacios.");
            return;
        }

        if (formulario.tipo_fuente === "usb") {
            if (!REGEX_INDICE_USB.test(formulario.stream_url.trim())) {
                setError("Para una cámara USB, el índice debe ser numérico. Ejemplo: 0, 1 o 2.");
                return;
            }
        } else {
            if (!formulario.stream_url.trim()) {
                setError("Debe ingresar la URL o ruta de la fuente de video.");
                return;
            }

            if (!REGEX_STREAM_URL.test(formulario.stream_url.trim())) {
                setError("La URL o ruta de video contiene caracteres no permitidos (sin espacios).");
                return;
            }
        }

        try {
            setGuardando(true);
            setError("");
            setMensaje("");

            await crearCamara(construirPayload());

            setMensaje("Cámara creada correctamente.");
            limpiarFormulario();
            setMostrarFormulario(false);
            await cargarDatos();
        } catch (error) {
            const data = error.response?.data;

            if (error.response?.status === 403) {
                setError("No tiene permisos para crear cámaras. Use una cuenta administradora.");
            } else if (typeof data === "object" && data !== null) {
                const mensajes = Object.values(data).flat().join(" ");
                setError(mensajes || "No se pudo crear la cámara. Verifique los datos ingresados.");
            } else {
                setError("No se pudo crear la cámara. Verifique los datos ingresados.");
            }
        } finally {
            setGuardando(false);
        }
    };

    const obtenerNombrePeaje = (id) => {
        const peaje = peajes.find((item) => Number(item.id) === Number(id));
        return peaje ? peaje.nombre : id;
    };

    const textoFuente = (fuente) => {
        if (fuente === "usb") return "USB";
        if (fuente === "rtsp") return "RTSP";
        if (fuente === "http") return "HTTP";
        if (fuente === "video") return "Video";
        return fuente || "Sin fuente";
    };

    if (cargando) {
        return (
            <div className="camaras-page">
                <h2>Gestión de Cámaras</h2>
                <p>Cargando cámaras...</p>
            </div>
        );
    }

    return (
        <div className="camaras-page">
            <ModuleHeader
                icon="📷"
                title="Gestión de cámaras"
                subtitle="Controla las cámaras instaladas en los carriles y su estado de operación."
                badge="Módulo de cámaras"
                status="Cámaras activas"
                actions={
                    <>
                        <button className="module-header-primary" onClick={() => setMostrarFormulario(!mostrarFormulario)}>
                            + Nueva cámara
                        </button>

                        <button className="module-header-secondary" onClick={cargarDatos}>
                            Actualizar
                        </button>
                    </>
                }
            />

            {error && <div className="camaras-error">{error}</div>}
            {mensaje && <div className="camaras-success">{mensaje}</div>}

            {mostrarFormulario && (
                <div className="form-card">
                    <h3>Registrar nueva cámara</h3>

                    <form onSubmit={handleSubmit} className="camara-form">
                        <div className="form-group">
                            <label>Código</label>
                            <input
                                type="text"
                                name="codigo"
                                value={formulario.codigo}
                                onChange={handleChange}
                                placeholder="Ej: CAM-USB-01"
                                maxLength={20}
                                required
                            />
                        </div>

                        <div className="form-group">
                            <label>Peaje</label>
                            <select
                                name="peaje"
                                value={formulario.peaje}
                                onChange={handleChange}
                                required
                            >
                                <option value="">Seleccione un peaje</option>
                                {peajes.map((peaje) => (
                                    <option key={peaje.id} value={peaje.id}>
                                        {peaje.nombre} - {peaje.ciudad}
                                    </option>
                                ))}
                            </select>
                        </div>

                        <div className="form-group">
                            <label>Ubicación</label>
                            <input
                                type="text"
                                name="ubicacion"
                                value={formulario.ubicacion}
                                onChange={handleChange}
                                placeholder="Ej: Carril 1"
                                maxLength={100}
                                required
                            />
                        </div>

                        <div className="form-group">
                            <label>Tipo de cámara</label>
                            <input
                                type="text"
                                name="tipo_camara"
                                value={formulario.tipo_camara}
                                onChange={handleChange}
                                placeholder="ANPR"
                                maxLength={50}
                                required
                            />
                        </div>

                        <div className="form-group">
                            <label>Fuente de video</label>
                            <select
                                name="tipo_fuente"
                                value={formulario.tipo_fuente}
                                onChange={handleChange}
                            >
                                <option value="usb">USB / Webcam</option>
                                <option value="rtsp">RTSP</option>
                                <option value="http">HTTP</option>
                                <option value="video">Archivo de video</option>
                            </select>
                        </div>

                        <div className="form-group">
                            <label>
                                {formulario.tipo_fuente === "usb"
                                    ? "Índice USB"
                                    : "URL o ruta de video"}
                            </label>
                            <input
                                type="text"
                                name="stream_url"
                                inputMode={formulario.tipo_fuente === "usb" ? "numeric" : "text"}
                                value={formulario.stream_url}
                                onChange={handleChange}
                                placeholder={formulario.tipo_fuente === "usb" ? "0" : "rtsp://..."}
                                maxLength={formulario.tipo_fuente === "usb" ? 2 : 300}
                                required={formulario.tipo_fuente !== "usb"}
                            />
                        </div>

                        <div className="form-group checkbox-group">
                            <label>
                                <input
                                    type="checkbox"
                                    name="procesar_anpr"
                                    checked={formulario.procesar_anpr}
                                    onChange={handleChange}
                                />
                                Procesar reconocimiento de placas ANPR
                            </label>
                        </div>

                        <div className="form-group">
                            <label>Estado</label>
                            <select
                                name="estado"
                                value={formulario.estado}
                                onChange={handleChange}
                            >
                                <option value="activa">Activa</option>
                                <option value="inactiva">Inactiva</option>
                                <option value="mantenimiento">Mantenimiento</option>
                            </select>
                        </div>

                        <div className="form-group">
                            <label>Fecha de instalación</label>
                            <input
                                type="date"
                                name="fecha_instalacion"
                                value={formulario.fecha_instalacion}
                                onChange={handleChange}
                            />
                        </div>

                        <div className="form-buttons">
                            <button type="submit" className="btn-primary" disabled={guardando}>
                                {guardando ? "Guardando..." : "Guardar cámara"}
                            </button>
                        </div>
                    </form>
                </div>
            )}

            <div className="camaras-table-card">
                <table>
                    <thead>
                    <tr>
                        <th>Código</th>
                        <th>Peaje</th>
                        <th>Ubicación</th>
                        <th>Tipo</th>
                        <th>Fuente</th>
                        <th>Stream</th>
                        <th>ANPR</th>
                        <th>Estado</th>
                        <th>Instalación</th>
                    </tr>
                    </thead>

                    <tbody>
                    {camaras.length > 0 ? (
                        camaras.map((camara) => (
                            <tr key={camara.id}>
                                <td>{camara.codigo}</td>
                                <td>{camara.peaje_nombre || obtenerNombrePeaje(camara.peaje)}</td>
                                <td>{camara.ubicacion}</td>
                                <td>{camara.tipo_camara}</td>
                                <td>{textoFuente(camara.tipo_fuente)}</td>
                                <td>{camara.stream_url || "Sin dato"}</td>
                                <td>{camara.procesar_anpr ? "Sí" : "No"}</td>
                                <td>
                                    <span className={`estado estado-${camara.estado}`}>
                                        {camara.estado}
                                    </span>
                                </td>
                                <td>{camara.fecha_instalacion || "Sin fecha"}</td>
                            </tr>
                        ))
                    ) : (
                        <tr>
                            <td colSpan="9">No existen cámaras registradas.</td>
                        </tr>
                    )}
                    </tbody>
                </table>
            </div>
        </div>
    );
}

export default Camaras;
