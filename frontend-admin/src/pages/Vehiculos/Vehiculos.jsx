import { useEffect, useMemo, useState } from "react";
import { obtenerVehiculos } from "../../api/vehiculosService";
import "../Styles/Vehiculos.css";

function Vehiculos() {
  const [vehiculos, setVehiculos] = useState([]);
  const [busqueda, setBusqueda] = useState("");
  const [cargando, setCargando] = useState(true);
  const [error, setError] = useState("");

  const cargarVehiculos = async () => {
    try {
      setCargando(true);
      setError("");

      const data = await obtenerVehiculos();

      if (Array.isArray(data)) {
        setVehiculos(data);
      } else if (data.results) {
        setVehiculos(data.results);
      } else {
        setVehiculos([]);
      }
    } catch (error) {
      setError("No se pudieron cargar los vehículos.");
    } finally {
      setCargando(false);
    }
  };

  useEffect(() => {
    cargarVehiculos();
  }, []);

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

      return (
        placa.includes(texto) ||
        marca.includes(texto) ||
        modelo.includes(texto) ||
        usuario.includes(texto) ||
        categoria.includes(texto)
      );
    });
  }, [busqueda, vehiculos]);

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
            Consulta de vehículos registrados por los usuarios desde la app móvil.
          </p>
        </div>

        <button className="btn-secondary" onClick={cargarVehiculos}>
          Actualizar
        </button>
      </div>

      {error && <div className="vehiculos-error">{error}</div>}

      <div className="vehiculos-toolbar">
        <input
          type="text"
          value={busqueda}
          onChange={(e) => setBusqueda(e.target.value)}
          placeholder="Buscar por placa, marca, modelo, usuario o categoría..."
        />
      </div>

      <div className="vehiculos-table-card">
        <table>
          <thead>
            <tr>
              <th>ID</th>
              <th>Placa</th>
              <th>Usuario</th>
              <th>Marca</th>
              <th>Modelo</th>
              <th>Color</th>
              <th>Año</th>
              <th>Categoría</th>
              <th>Tarifa</th>
              <th>Estado</th>
            </tr>
          </thead>

          <tbody>
            {vehiculosFiltrados.length > 0 ? (
              vehiculosFiltrados.map((vehiculo) => (
                <tr key={vehiculo.id}>
                  <td>{vehiculo.id}</td>
                  <td>
                    <strong>{vehiculo.placa}</strong>
                  </td>
                  <td>{vehiculo.usuario_username || vehiculo.usuario}</td>
                  <td>{vehiculo.marca}</td>
                  <td>{vehiculo.modelo}</td>
                  <td>{vehiculo.color || "Sin dato"}</td>
                  <td>{vehiculo.anio || "Sin dato"}</td>
                  <td>{vehiculo.categoria_nombre || vehiculo.categoria}</td>
                  <td>
                    {vehiculo.categoria_tarifa
                      ? `$${vehiculo.categoria_tarifa}`
                      : "Sin tarifa"}
                  </td>
                  <td>
                    <span className={`estado ${vehiculo.estado}`}>
                      {vehiculo.estado}
                    </span>
                  </td>
                </tr>
              ))
            ) : (
              <tr>
                <td colSpan="10">No existen vehículos registrados.</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}

export default Vehiculos;