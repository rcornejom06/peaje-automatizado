import { useEffect, useState } from "react";
import {
  obtenerHistorialAuditoria,
  obtenerResumenAuditoria,
} from "../../api/auditoriaService.js";
import "../Styles/Auditoria.css";

function Auditoria() {
  const [historial, setHistorial] = useState([]);
  const [resumen, setResumen] = useState(null);
  const [cargando, setCargando] = useState(true);
  const [error, setError] = useState("");

  const [filtros, setFiltros] = useState({
    fecha_inicio: "",
    fecha_fin: "",
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

      setResumen(resumenData);
    } catch (error) {
      setError("No se pudo cargar el historial de auditoría.");
    } finally {
      setCargando(false);
    }
  };

  useEffect(() => {
    cargarAuditoria();
  }, []);

  const handleChange = (e) => {
    setFiltros({
      ...filtros,
      [e.target.name]: e.target.value,
    });
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
      <div className="auditoria-header">
        <div>
          <h2>Auditoría del Sistema</h2>
          <p>Historial de acciones realizadas por usuarios, operadores y procesos automáticos.</p>
        </div>

        <button className="btn-primary" onClick={() => cargarAuditoria()}>
          Actualizar
        </button>
      </div>

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
          <label>Fecha inicio</label>
          <input
            type="date"
            name="fecha_inicio"
            value={filtros.fecha_inicio}
            onChange={handleChange}
          />
        </div>

        <div className="form-group">
          <label>Fecha fin</label>
          <input
            type="date"
            name="fecha_fin"
            value={filtros.fecha_fin}
            onChange={handleChange}
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
          />
        </div>

        <div className="auditoria-actions">
          <button className="btn-primary" onClick={() => cargarAuditoria()}>
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
            {historial.length > 0 ? (
              historial.map((item) => (
                <tr key={item.id}>
                  <td>
                    {item.fecha_hora
                      ? new Date(item.fecha_hora).toLocaleString()
                      : "Sin fecha"}
                  </td>

                  <td>{item.usuario_nombre || item.usuario_username || "Sistema"}</td>

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
    </div>
  );
}

export default Auditoria;