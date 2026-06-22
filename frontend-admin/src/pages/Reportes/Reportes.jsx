import { useEffect, useState } from "react";
import {
  obtenerRecaudacion,
  obtenerPasosPorPeaje,
  obtenerAlertas,
  obtenerVehiculosDetectados,
  obtenerUsoMembresias,
} from "../../api/reportesService";
import "../Styles/Reportes.css";

function Reportes() {
  const [tab, setTab] = useState("recaudacion");
  const [cargando, setCargando] = useState(false);
  const [error, setError] = useState("");

  const [filtros, setFiltros] = useState({
    fecha_inicio: "",
    fecha_fin: "",
  });

  const [recaudacion, setRecaudacion] = useState(null);
  const [pasosPorPeaje, setPasosPorPeaje] = useState([]);
  const [alertas, setAlertas] = useState(null);
  const [vehiculosDetectados, setVehiculosDetectados] = useState(null);
  const [usoMembresias, setUsoMembresias] = useState(null);

  const cargarReportes = async () => {
    try {
      setCargando(true);
      setError("");

      const [
        recaudacionData,
        pasosData,
        alertasData,
        vehiculosData,
        usoMembresiasData,
      ] = await Promise.all([
        obtenerRecaudacion(filtros),
        obtenerPasosPorPeaje(filtros),
        obtenerAlertas(filtros),
        obtenerVehiculosDetectados(filtros),
        obtenerUsoMembresias(filtros),
      ]);

      setRecaudacion(recaudacionData);
      setPasosPorPeaje(Array.isArray(pasosData) ? pasosData : []);
      setAlertas(alertasData);
      setVehiculosDetectados(vehiculosData);
      setUsoMembresias(usoMembresiasData);
    } catch (error) {
      setError("No se pudieron cargar los reportes.");
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

    try {
      setCargando(true);
      setError("");

      const [
        recaudacionData,
        pasosData,
        alertasData,
        vehiculosData,
        usoMembresiasData,
      ] = await Promise.all([
        obtenerRecaudacion(filtrosLimpios),
        obtenerPasosPorPeaje(filtrosLimpios),
        obtenerAlertas(filtrosLimpios),
        obtenerVehiculosDetectados(filtrosLimpios),
        obtenerUsoMembresias(filtrosLimpios),
      ]);

      setRecaudacion(recaudacionData);
      setPasosPorPeaje(Array.isArray(pasosData) ? pasosData : []);
      setAlertas(alertasData);
      setVehiculosDetectados(vehiculosData);
      setUsoMembresias(usoMembresiasData);
    } catch (error) {
      setError("No se pudieron cargar los reportes.");
    } finally {
      setCargando(false);
    }
  };

  return (
    <div className="reportes-page">
      <div className="reportes-header">
        <div>
          <h2>Reportes</h2>
          <p>Indicadores y estadísticas del sistema de peaje automatizado.</p>
        </div>

        <button className="btn-secondary" onClick={cargarReportes}>
          Actualizar
        </button>
      </div>

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

        <div className="form-group">
          <label>Fecha fin</label>
          <input
            type="date"
            name="fecha_fin"
            value={filtros.fecha_fin}
            onChange={handleFiltroChange}
          />
        </div>

        <div className="filtros-actions">
          <button className="btn-primary" onClick={cargarReportes}>
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
              <strong>${recaudacion?.recaudacion_peajes ?? "0.00"}</strong>
            </div>

            <div className="stat-card money">
              <span>Recaudación por membresías</span>
              <strong>${recaudacion?.recaudacion_membresias ?? "0.00"}</strong>
            </div>

            <div className="stat-card money">
              <span>Total recaudado</span>
              <strong>${recaudacion?.recaudacion_total ?? "0.00"}</strong>
            </div>

            <div className="stat-card money">
              <span>Recargas billetera</span>
              <strong>${recaudacion?.recargas_billetera ?? "0.00"}</strong>
            </div>
          </div>

          {recaudacion?.nota && (
            <div className="nota-card">
              {recaudacion.nota}
            </div>
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
                </tr>
              </thead>

              <tbody>
                {pasosPorPeaje.length > 0 ? (
                  pasosPorPeaje.map((item) => (
                    <tr key={item.peaje__id}>
                      <td>{item.peaje__nombre}</td>
                      <td>{item.peaje__ciudad}</td>
                      <td>{item.total_pasos}</td>
                      <td>{item.vehiculos_distintos}</td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan="4">No existen registros de pasos por peaje.</td>
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
            <div className="stat-card">
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
                        {item.membresia_utilizada__plan__nombre ||
                          "Sin plan"}
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
        </div>
      )}
    </div>
  );
}

export default Reportes;