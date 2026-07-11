import { useEffect, useState } from "react";
import { obtenerPeajes, crearPeaje } from "../../api/peajeService.js";
import ModuleHeader from "../../components/ModuleHeader/ModuleHeader";
import "../Styles/Peajes.css";

function Peajes() {
  const [peajes, setPeajes] = useState([]);
  const [cargando, setCargando] = useState(true);
  const [error, setError] = useState("");
  const [mensaje, setMensaje] = useState("");
  const [mostrarFormulario, setMostrarFormulario] = useState(false);

  const [formulario, setFormulario] = useState({
    nombre: "",
    ciudad: "",
    ubicacion: "",
    latitud: "",
    longitud: "",
    estado: "activo",
  });

  const cargarPeajes = async () => {
    try {
      setCargando(true);
      setError("");
      setMensaje("");

      const data = await obtenerPeajes();

      if (Array.isArray(data)) {
        setPeajes(data);
      } else if (data?.results) {
        setPeajes(data.results);
      } else {
        setPeajes([]);
      }
    } catch (error) {
      setError("No se pudieron cargar los peajes.");
    } finally {
      setCargando(false);
    }
  };

  useEffect(() => {
    cargarPeajes();
  }, []);

  const abrirFormulario = () => {
    setError("");
    setMensaje("");
    setMostrarFormulario(true);
  };

  const cerrarFormulario = () => {
    setMostrarFormulario(false);
    limpiarFormulario();
  };

  const handleChange = (e) => {
    setFormulario({
      ...formulario,
      [e.target.name]: e.target.value,
    });
  };

  const limpiarFormulario = () => {
    setFormulario({
      nombre: "",
      ciudad: "",
      ubicacion: "",
      latitud: "",
      longitud: "",
      estado: "activo",
    });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();

    try {
      setError("");
      setMensaje("");

      await crearPeaje({
        ...formulario,
        tarifa: "0.00",
      });

      setMensaje("Peaje creado correctamente.");
      limpiarFormulario();
      setMostrarFormulario(false);
      await cargarPeajes();
    } catch (error) {
      if (error.response?.status === 403) {
        setError(
          "No tiene permisos para crear peajes. Use una cuenta administradora."
        );
      } else {
        setError("No se pudo crear el peaje. Verifique los datos ingresados.");
      }
    }
  };

  return (
    <div className="peajes-page">
      <ModuleHeader
        icon="🛣️"
        title="Gestión de peajes"
        subtitle="Administra estaciones, ubicaciones y estado operativo de cada peaje."
        badge="Módulo de peajes"
        status="Sistema activo"
        actions={
          <>
            <button
              className="module-header-primary"
              onClick={mostrarFormulario ? cerrarFormulario : abrirFormulario}
            >
              {mostrarFormulario ? "Cancelar" : "+ Nuevo peaje"}
            </button>

            <button className="module-header-secondary" onClick={cargarPeajes}>
              Actualizar
            </button>
          </>
        }
      />

      {cargando && <p className="peajes-loading">Cargando peajes...</p>}

      {error && <div className="peajes-error">{error}</div>}

      {mensaje && <div className="peajes-success">{mensaje}</div>}

      {mostrarFormulario && (
        <div className="form-card">
          <h3>Registrar nuevo peaje</h3>

          <form onSubmit={handleSubmit} className="peaje-form">
            <div className="form-group">
              <label>Nombre</label>
              <input
                type="text"
                name="nombre"
                value={formulario.nombre}
                onChange={handleChange}
                placeholder="Ej: Peaje Milagro"
                required
              />
            </div>

            <div className="form-group">
              <label>Ciudad</label>
              <input
                type="text"
                name="ciudad"
                value={formulario.ciudad}
                onChange={handleChange}
                placeholder="Ej: Milagro"
                required
              />
            </div>

            <div className="form-group full">
              <label>Ubicación</label>
              <input
                type="text"
                name="ubicacion"
                value={formulario.ubicacion}
                onChange={handleChange}
                placeholder="Ej: Vía Milagro - Guayaquil"
                required
              />
            </div>

            <div className="form-group">
              <label>Latitud</label>
              <input
                type="text"
                name="latitud"
                value={formulario.latitud}
                onChange={handleChange}
                placeholder="-2.1345000"
                required
              />
            </div>

            <div className="form-group">
              <label>Longitud</label>
              <input
                type="text"
                name="longitud"
                value={formulario.longitud}
                onChange={handleChange}
                placeholder="-79.5948000"
                required
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
                <option value="mantenimiento">Mantenimiento</option>
              </select>
            </div>

            <div className="form-buttons">
              <button type="submit" className="btn-primary">
                Guardar peaje
              </button>

              <button
                type="button"
                className="btn-secondary"
                onClick={cerrarFormulario}
              >
                Cancelar
              </button>
            </div>
          </form>
        </div>
      )}

      <div className="peajes-info-card">
        <strong>Nota:</strong> El valor a pagar no se define en el peaje. El
        cobro se calcula automáticamente según la categoría del vehículo
        registrado.
      </div>

      <div className="peajes-table-card">
        <table>
          <thead>
            <tr>
              <th>Nombre</th>
              <th>Ciudad</th>
              <th>Ubicación</th>
              <th>Estado</th>
              <th>Coordenadas</th>
            </tr>
          </thead>

          <tbody>
            {!cargando && peajes.length > 0 ? (
              peajes.map((peaje) => (
                <tr key={peaje.id}>
                  <td>{peaje.nombre}</td>
                  <td>{peaje.ciudad}</td>
                  <td>{peaje.ubicacion}</td>
                  <td>
                    <span className={`estado ${peaje.estado}`}>
                      {peaje.estado}
                    </span>
                  </td>
                  <td>
                    {peaje.latitud}, {peaje.longitud}
                  </td>
                </tr>
              ))
            ) : !cargando ? (
              <tr>
                <td colSpan="5">No existen peajes registrados.</td>
              </tr>
            ) : null}
          </tbody>
        </table>
      </div>
    </div>
  );
}

export default Peajes;