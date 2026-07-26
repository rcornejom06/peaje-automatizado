import {useEffect, useState} from "react";
import {
    obtenerPlanesMembresia,
    crearPlanMembresia,
    actualizarPlanMembresia,
    eliminarPlanMembresia,
    obtenerMembresias,
} from "../../api/membresiaService.js";
import "../Styles/Membresias.css";
import ModuleHeader from "../../components/ModuleHeader/ModuleHeader";


function Membresias() {
    const [planes, setPlanes] = useState([]);
    const [membresias, setMembresias] = useState([]);
    const [tab, setTab] = useState("planes");
    const [cargando, setCargando] = useState(true);
    const [error, setError] = useState("");
    const [mensaje, setMensaje] = useState("");
    const [mostrarFormulario, setMostrarFormulario] = useState(false);
    const [planEditando, setPlanEditando] = useState(null); // null = creando, id = editando

    const [formulario, setFormulario] = useState({
        nombre: "",
        descripcion: "",
        precio: "0.00",
        pases_incluidos: 30,
        descuento_porcentaje: "0.00",
        estado: "activo",
    });

    const cargarDatos = async () => {
        try {
            setCargando(true);
            setError("");
            setMensaje("");

            const [planesData, membresiasData] = await Promise.all([
                obtenerPlanesMembresia(),
                obtenerMembresias(),
            ]);

            if (Array.isArray(planesData)) {
                setPlanes(planesData);
            } else if (planesData.results) {
                setPlanes(planesData.results);
            } else {
                setPlanes([]);
            }

            if (Array.isArray(membresiasData)) {
                setMembresias(membresiasData);
            } else if (membresiasData.results) {
                setMembresias(membresiasData.results);
            } else {
                setMembresias([]);
            }
        } catch {
            setError("No se pudieron cargar las membresías.");
        } finally {
            setCargando(false);
        }
    };

    useEffect(() => {
        cargarDatos();
    }, []);

    const handleChange = (e) => {
        setFormulario({
            ...formulario,
            [e.target.name]: e.target.value,
        });
    };

    const limpiarFormulario = () => {
        setFormulario({
            nombre: "",
            descripcion: "",
            precio: "0.00",
            pases_incluidos: 30,
            descuento_porcentaje: "0.00",
            estado: "activo",
        });
        setPlanEditando(null);
    };

    const iniciarEdicion = (plan) => {
        setFormulario({
            nombre: plan.nombre || "",
            descripcion: plan.descripcion || "",
            precio: plan.precio ?? "0.00",
            pases_incluidos: plan.pases_incluidos ?? 30,
            descuento_porcentaje: plan.descuento_porcentaje ?? "0.00",
            estado: plan.estado || "activo",
        });
        setPlanEditando(plan.id);
        setMostrarFormulario(true);
        setError("");
        setMensaje("");
    };

    const cancelarFormulario = () => {
        limpiarFormulario();
        setMostrarFormulario(false);
    };

    const eliminarPlan = async (plan) => {
        const confirmar = window.confirm(
            `¿Eliminar el plan "${plan.nombre}"? Esta acción no se puede deshacer.`
        );

        if (!confirmar) return;

        try {
            setError("");
            setMensaje("");

            await eliminarPlanMembresia(plan.id);

            setMensaje("Plan de membresía eliminado correctamente.");
            await cargarDatos();
        } catch (err) {
            if (err.response?.status === 403) {
                setError("No tiene permisos para eliminar planes de membresía.");
            } else {
                setError(
                    err.response?.data?.error ||
                    err.response?.data?.detail ||
                    "No se pudo eliminar el plan."
                );
            }
        }
    };

    const handleSubmit = async (e) => {
        e.preventDefault();

        const editando = planEditando !== null;

        try {
            setError("");
            setMensaje("");

            if (editando) {
                await actualizarPlanMembresia(planEditando, formulario);
                setMensaje("Plan de membresía actualizado correctamente.");
            } else {
                await crearPlanMembresia(formulario);
                setMensaje("Plan de membresía creado correctamente.");
            }

            limpiarFormulario();
            setMostrarFormulario(false);
            await cargarDatos();
        } catch (err) {
            if (err.response?.status === 403) {
                setError(
                    editando
                        ? "No tiene permisos para editar planes de membresía."
                        : "No tiene permisos para crear planes de membresía."
                );
            } else {
                setError(
                    err.response?.data?.error ||
                    err.response?.data?.detail ||
                    "No se pudo guardar el plan. Verifique los datos ingresados."
                );
            }
        }
    };

    if (cargando) {
        return (
            <div className="membresias-page">
                <h2>Membresías</h2>
                <p>Cargando información...</p>
            </div>
        );
    }

    return (
        <div className="membresias-page">
            <ModuleHeader
                icon="🎫"
                title="Membresías y paquetes"
                subtitle="Administra planes, membresías activas y beneficios por categoría vehicular."
                badge="Membresías"
                status="Activo"

                actions={
                <>
                <button
                    className="module-header-primary"
                    onClick={mostrarFormulario ? cancelarFormulario : () => setMostrarFormulario(true)}
                >
                    {mostrarFormulario ? "Cancelar" : "+ Nuevo plan"}
                </button>

                <button className="module-header-secondary" onClick={cargarDatos}>
                    Actualizar
                </button>

                </>
                }

            />


            {error && <div className="membresias-error">{error}</div>}
            {mensaje && <div className="membresias-success">{mensaje}</div>}

            <div className="tabs">
                <button
                    className={tab === "planes" ? "active" : ""}
                    onClick={() => setTab("planes")}
                >
                    Planes
                </button>

                <button
                    className={tab === "membresias" ? "active" : ""}
                    onClick={() => setTab("membresias")}
                >
                    Membresías adquiridas
                </button>
            </div>

            {tab === "planes" && mostrarFormulario && (
                <div className="form-card">
                    <h3>{planEditando !== null ? "Editar plan de membresía" : "Crear plan de membresía"}</h3>

                    <form onSubmit={handleSubmit} className="membresia-form">
                        <div className="form-group">
                            <label>Nombre</label>
                            <input
                                type="text"
                                name="nombre"
                                value={formulario.nombre}
                                onChange={handleChange}
                                placeholder="Ej: Membresía mensual"
                                required
                            />
                        </div>

                        <div className="form-group">
                            <label>Precio</label>
                            <input
                                type="number"
                                step="0.01"
                                name="precio"
                                value={formulario.precio}
                                onChange={handleChange}
                                required
                            />
                        </div>

                        <div className="form-group">
                            <label>Pases incluidos</label>
                            <input
                                type="number"
                                name="pases_incluidos"
                                value={formulario.pases_incluidos}
                                onChange={handleChange}
                                required
                            />
                        </div>

                        <div className="form-group">
                            <label>Descuento %</label>
                            <input
                                type="number"
                                step="0.01"
                                name="descuento_porcentaje"
                                value={formulario.descuento_porcentaje}
                                onChange={handleChange}
                            />
                        </div>

                        <div className="form-group">
                            <label>Estado</label>
                            <select
                                name="estado"
                                value={formulario.estado}
                                onChange={handleChange}
                            >
                                <option value="activo">Activo</option>
                                <option value="inactivo">Inactivo</option>
                            </select>
                        </div>

                        <div className="form-group full">
                            <label>Descripción</label>
                            <textarea
                                name="descripcion"
                                value={formulario.descripcion}
                                onChange={handleChange}
                                placeholder="Descripción del plan"
                                rows="3"
                            />
                        </div>

                        <div className="form-buttons">
                            <button type="submit" className="btn-primary">
                                {planEditando !== null ? "Guardar cambios" : "Guardar plan"}
                            </button>
                        </div>
                    </form>
                </div>
            )}

            {tab === "planes" && (
                <div className="membresias-table-card">
                    <table>
                        <thead>
                        <tr>
                            <th>Nombre</th>
                            <th>Precio</th>
                            <th>Pases</th>
                            <th>Descuento</th>
                            <th>Estado</th>
                            <th>Acciones</th>
                        </tr>
                        </thead>

                        <tbody>
                        {planes.length > 0 ? (
                            planes.map((plan) => (
                                <tr key={plan.id}>
                                    <td>
                                        <strong>{plan.nombre}</strong>
                                        <br/>
                                        <span>{plan.descripcion || "Sin descripción"}</span>
                                    </td>
                                    <td>${plan.precio}</td>
                                    <td>{plan.pases_incluidos}</td>
                                    <td>{plan.descuento_porcentaje}%</td>
                                    <td>
                      <span className={`estado ${plan.estado}`}>
                        {plan.estado}
                      </span>
                                    </td>
                                    <td>
                                        <div className="table-actions">
                                            <button
                                                type="button"
                                                className="btn-editar"
                                                onClick={() => iniciarEdicion(plan)}
                                            >
                                                Editar
                                            </button>
                                            <button
                                                type="button"
                                                className="btn-eliminar"
                                                onClick={() => eliminarPlan(plan)}
                                            >
                                                Eliminar
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                            ))
                        ) : (
                            <tr>
                                <td colSpan="6">No existen planes de membresía.</td>
                            </tr>
                        )}
                        </tbody>
                    </table>
                </div>
            )}

            {tab === "membresias" && (
                <div className="membresias-table-card">
                    <table>
                        <thead>
                        <tr>
                            <th>Usuario</th>
                            <th>Plan</th>
                            <th>Inicio</th>
                            <th>Fin</th>
                            <th>Pases restantes</th>
                            <th>Estado</th>
                        </tr>
                        </thead>

                        <tbody>
                        {membresias.length > 0 ? (
                            membresias.map((membresia) => (
                                <tr key={membresia.id}>
                                    <td>
                                        {membresia.usuario_username ||
                                            membresia.usuario ||
                                            "Sin usuario"}
                                    </td>
                                    <td>
                                        {membresia.plan_nombre ||
                                            membresia.plan ||
                                            "Sin plan"}
                                    </td>
                                    <td>{membresia.fecha_inicio}</td>
                                    <td>{membresia.pases_restantes}</td>
                                    <td>
                      <span className={`estado ${membresia.estado}`}>
                        {membresia.estado}
                      </span>
                                    </td>
                                </tr>
                            ))
                        ) : (
                            <tr>
                                <td colSpan="6">No existen membresías adquiridas.</td>
                            </tr>
                        )}
                        </tbody>
                    </table>
                </div>
            )}
        </div>
    );
}

export default Membresias;
