import { useEffect, useState } from "react";
import {
  obtenerAlertas,
  marcarAlertaRevisada,
  derivarAlertaAutoridad,
  cerrarAlerta,
  descartarAlerta,
} from "../../api/seguidadService.js";
import "../Styles/Alertas.css";

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
      <div className="alertas-header">
        <div>
          <h2>Alertas de Seguridad</h2>
          <p>Monitoreo de alertas generadas por detección de placas.</p>
        </div>

        <button className="btn-primary" onClick={cargarAlertas}>
          Actualizar
        </button>
      </div>

      {error && <div className="alertas-error">{error}</div>}
      {mensaje && <div className="alertas-success">{mensaje}</div>}

      <div className="alertas-table-card">
        <table>
          <thead>
            <tr>
              <th>ID</th>
              <th>Vehículo</th>
              <th>Peaje</th>
              <th>Tipo</th>
              <th>Estado</th>
              <th>Fecha</th>
              <th>Acciones</th>
            </tr>
          </thead>

          <tbody>
            {alertas.length > 0 ? (
              alertas.map((alerta) => (
                <tr key={alerta.id}>
                  <td>{alerta.id}</td>
                  <td>
                    {alerta.vehiculo_placa ||
                      alerta.placa ||
                      alerta.vehiculo ||
                      "Sin dato"}
                  </td>
                  <td>
                    {alerta.peaje_nombre ||
                      alerta.peaje ||
                      "Sin dato"}
                  </td>
                  <td>{alerta.tipo_alerta || "Alerta"}</td>
                  <td>
                    <span className={obtenerClaseEstado(alerta.estado)}>
                      {alerta.estado}
                    </span>
                  </td>
                  <td>
                    {alerta.fecha_hora
                      ? new Date(alerta.fecha_hora).toLocaleString()
                      : "Sin fecha"}
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
                        disabled={
                          alerta.estado === "cerrada" ||
                          alerta.estado === "descartada"
                        }
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
                        disabled={
                          alerta.estado === "cerrada" ||
                          alerta.estado === "descartada"
                        }
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
                        disabled={
                          alerta.estado === "cerrada" ||
                          alerta.estado === "descartada"
                        }
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
                        disabled={
                          alerta.estado === "cerrada" ||
                          alerta.estado === "descartada"
                        }
                      >
                        Descartar
                      </button>
                    </div>
                  </td>
                </tr>
              ))
            ) : (
              <tr>
                <td colSpan="7">No existen alertas registradas.</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}

export default Alertas;