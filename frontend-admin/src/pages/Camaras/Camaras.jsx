import { useEffect, useState } from "react";
import { obtenerCamaras, crearCamara } from "../../api/camarasService";
import { obtenerPeajes } from "../../api/peajeService.js";
import "../Styles/Camaras.css";

function Camaras() {
  const [camaras, setCamaras] = useState([]);
  const [peajes, setPeajes] = useState([]);
  const [cargando, setCargando] = useState(true);
  const [error, setError] = useState("");
  const [mensaje, setMensaje] = useState("");
  const [mostrarFormulario, setMostrarFormulario] = useState(false);

  const [formulario, setFormulario] = useState({
    codigo: "",
    peaje: "",
    ubicacion: "",
    tipo_camara: "ANPR",
    estado: "activa",
    fecha_instalacion: "",
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

      if (Array.isArray(camarasData)) {
        setCamaras(camarasData);
      } else if (camarasData.results) {
        setCamaras(camarasData.results);
      } else {
        setCamaras([]);
      }

      if (Array.isArray(peajesData)) {
        setPeajes(peajesData);
      } else if (peajesData.results) {
        setPeajes(peajesData.results);
      } else {
        setPeajes([]);
      }
    } catch (error) {
      setError("No se pudieron cargar las cámaras.");
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
      codigo: "",
      peaje: "",
      ubicacion: "",
      tipo_camara: "ANPR",
      estado: "activa",
      fecha_instalacion: "",
    });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();

    try {
      setError("");
      setMensaje("");

      await crearCamara(formulario);

      setMensaje("Cámara creada correctamente.");
      limpiarFormulario();
      setMostrarFormulario(false);
      await cargarDatos();
    } catch (error) {
      if (error.response?.status === 403) {
        setError("No tiene permisos para crear cámaras. Use una cuenta administradora.");
      } else {
        setError("No se pudo crear la cámara. Verifique los datos ingresados.");
      }
    }
  };

  const obtenerNombrePeaje = (id) => {
    const peaje = peajes.find((item) => Number(item.id) === Number(id));
    return peaje ? peaje.nombre : id;
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
      <div className="camaras-header">
        <div>
          <h2>Gestión de Cámaras</h2>
          <p>Listado y administración de cámaras asociadas a peajes.</p>
        </div>

        <div className="camaras-actions">
          <button className="btn-secondary" onClick={cargarDatos}>
            Actualizar
          </button>

          <button
            className="btn-primary"
            onClick={() => setMostrarFormulario(!mostrarFormulario)}
          >
            {mostrarFormulario ? "Cancelar" : "Nueva cámara"}
          </button>
        </div>
      </div>

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
                placeholder="Ej: CAM-001"
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
              <button type="submit" className="btn-primary">
                Guardar cámara
              </button>
            </div>
          </form>
        </div>
      )}

      <div className="camaras-table-card">
        <table>
          <thead>
            <tr>
              <th>ID</th>
              <th>Código</th>
              <th>Peaje</th>
              <th>Ubicación</th>
              <th>Tipo</th>
              <th>Estado</th>
              <th>Instalación</th>
            </tr>
          </thead>

          <tbody>
            {camaras.length > 0 ? (
              camaras.map((camara) => (
                <tr key={camara.id}>
                  <td>{camara.id}</td>
                  <td>{camara.codigo}</td>
                  <td>{camara.peaje_nombre || obtenerNombrePeaje(camara.peaje)}</td>
                  <td>{camara.ubicacion}</td>
                  <td>{camara.tipo_camara}</td>
                  <td>
                    <span className={`estado ${camara.estado}`}>
                      {camara.estado}
                    </span>
                  </td>
                  <td>{camara.fecha_instalacion || "Sin fecha"}</td>
                </tr>
              ))
            ) : (
              <tr>
                <td colSpan="7">No existen cámaras registradas.</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}

export default Camaras;