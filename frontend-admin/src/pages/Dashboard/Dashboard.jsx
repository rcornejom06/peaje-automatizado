import { useEffect, useState } from "react";
import {
  obtenerResumen,
  obtenerRecaudacion,
  obtenerAlertas,
} from "../../api/reportesService";
import "../Styles/Dashboard.css";

function Dashboard() {
  const [resumen, setResumen] = useState(null);
  const [recaudacion, setRecaudacion] = useState(null);
  const [alertas, setAlertas] = useState(null);
  const [cargando, setCargando] = useState(true);
  const [error, setError] = useState("");

  const cargarDatos = async () => {
    try {
      setCargando(true);
      setError("");

      const [resumenData, recaudacionData, alertasData] = await Promise.all([
        obtenerResumen(),
        obtenerRecaudacion(),
        obtenerAlertas(),
      ]);

      setResumen(resumenData);
      setRecaudacion(recaudacionData);
      setAlertas(alertasData);
        // eslint-disable-next-line no-unused-vars
    } catch (error) {
      setError("No se pudieron cargar los datos del dashboard.");
    } finally {
      setCargando(false);
    }
  };

  useEffect(() => {
    cargarDatos();
  }, []);

  if (cargando) {
    return (
      <div className="dashboard-page">
        <h2>Dashboard</h2>
        <p>Cargando información...</p>
      </div>
    );
  }

  if (error) {
    return (
      <div className="dashboard-page">
        <h2>Dashboard</h2>
        <div className="dashboard-error">{error}</div>
        <button className="dashboard-retry" onClick={cargarDatos}>
          Reintentar
        </button>
      </div>
    );
  }

  return (
    <div className="dashboard-page">
      <div className="dashboard-header">
        <div>
          <h2>Dashboard</h2>
          <p>Resumen general del sistema inteligente de peaje.</p>
        </div>

        <button className="dashboard-refresh" onClick={cargarDatos}>
          Actualizar
        </button>
      </div>

      <div className="stats-grid">
        <div className="stat-card">
          <span>Total de pasos</span>
          <strong>{resumen?.total_pasos ?? 0}</strong>
        </div>

        <div className="stat-card">
          <span>Vehículos detectados</span>
          <strong>{resumen?.total_vehiculos_detectados ?? 0}</strong>
        </div>

        <div className="stat-card">
          <span>Total de alertas</span>
          <strong>{resumen?.total_alertas ?? 0}</strong>
        </div>

        <div className="stat-card">
          <span>Pasos con membresía</span>
          <strong>{resumen?.pasos_cubiertos_por_membresia ?? 0}</strong>
        </div>
      </div>

      <div className="dashboard-section">
        <h3>Recaudación</h3>

        <div className="stats-grid">
          <div className="stat-card money">
            <span>Recaudación por peajes</span>
            <strong>${recaudacion?.recaudacion_peajes ?? "0.00"}</strong>
          </div>

          <div className="stat-card money">
            <span>Recaudación por membresías</span>
            <strong>${recaudacion?.recaudacion_membresias ?? "0.00"}</strong>
          </div>

          <div className="stat-card money">
            <span>Recaudación total</span>
            <strong>${recaudacion?.recaudacion_total ?? "0.00"}</strong>
          </div>

          <div className="stat-card money">
            <span>Recargas de billetera</span>
            <strong>${recaudacion?.recargas_billetera ?? "0.00"}</strong>
          </div>
        </div>
      </div>

      <div className="dashboard-section">
        <h3>Alertas por estado</h3>

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
                  <td colSpan="2">No existen alertas registradas.</td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      <div className="dashboard-section">
        <h3>Alertas por peaje</h3>

        <div className="table-card">
          <table>
            <thead>
              <tr>
                <th>Peaje</th>
                <th>Total de alertas</th>
              </tr>
            </thead>
            <tbody>
              {alertas?.por_peaje?.length > 0 ? (
                alertas.por_peaje.map((item) => (
                  <tr key={item.peaje__id}>
                    <td>{item.peaje__nombre}</td>
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
      </div>
    </div>
  );
}

export default Dashboard;