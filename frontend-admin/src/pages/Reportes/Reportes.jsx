import { useEffect, useState } from "react";
import {
  obtenerResumen,
  obtenerRecaudacion,
  obtenerPasosPorPeaje,
  obtenerAlertasReporte,
  obtenerVehiculosDetectados,
  obtenerUsoMembresias,
} from "../../api/reportesService";
import "../Styles/Reportes.css";

function Reportes() {
  const [tab, setTab] = useState("resumen");
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
    await cargarReportes(filtrosLimpios);
  };

  const formatoDinero = (valor) => {
    const numero = Number(valor || 0);
    return `$${numero.toFixed(2)}`;
  };

  return (
    <div className="reportes-page">
      <div className="reportes-header">
        <div>
          <h2>Reportes</h2>
          <p>Indicadores y estadísticas del sistema de peaje automatizado.</p>
        </div>

        <button className="btn-secondary" onClick={() => cargarReportes()}>
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
          className={tab === "resumen" ? "active" : ""}
          onClick={() => setTab("resumen")}
        >
          Resumen
        </button>

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

      {tab === "resumen" && (
        <div className="report-section">
          <h3>Resumen general</h3>

          <div className="stats-grid">
            <div className="stat-card">
              <span>Total pasos</span>
              <strong>{resumen?.total_pasos ?? 0}</strong>
            </div>

            <div className="stat-card">
              <span>Vehículos detectados</span>
              <strong>{resumen?.total_vehiculos_detectados ?? 0}</strong>
            </div>

            <div className="stat-card danger">
              <span>Alertas generadas</span>
              <strong>{resumen?.total_alertas ?? 0}</strong>
            </div>

            <div className="stat-card money">
              <span>Recaudación total</span>
              <strong>{formatoDinero(resumen?.recaudacion_total)}</strong>
            </div>

            <div className="stat-card success">
              <span>Pagados</span>
              <strong>{resumen?.pasos_pagados ?? 0}</strong>
            </div>

            <div className="stat-card">
              <span>Con membresía</span>
              <strong>{resumen?.pasos_cubiertos_por_membresia ?? 0}</strong>
            </div>

            <div className="stat-card warning">
              <span>Pendientes</span>
              <strong>{resumen?.pasos_pendientes ?? 0}</strong>
            </div>

            <div className="stat-card danger">
              <span>Pasos con alerta</span>
              <strong>{resumen?.pasos_con_alerta ?? 0}</strong>
            </div>
          </div>
        </div>
      )}

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
                      <td>{item.fecha_fin}</td>
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
