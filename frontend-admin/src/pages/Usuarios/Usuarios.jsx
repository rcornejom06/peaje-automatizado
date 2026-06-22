import { useEffect, useMemo, useState } from "react";
import { obtenerPerfiles } from "../../api/usuariosService";
import "../Styles/Usuarios.css";

function Usuarios() {
  const [perfiles, setPerfiles] = useState([]);
  const [busqueda, setBusqueda] = useState("");
  const [rolFiltro, setRolFiltro] = useState("");
  const [cargando, setCargando] = useState(true);
  const [error, setError] = useState("");

  const cargarPerfiles = async () => {
    try {
      setCargando(true);
      setError("");

      const data = await obtenerPerfiles();

      if (Array.isArray(data)) {
        setPerfiles(data);
      } else if (data.results) {
        setPerfiles(data.results);
      } else {
        setPerfiles([]);
      }
    } catch (error) {
      if (error.response?.status === 403) {
        setError("No tiene permisos para consultar usuarios.");
      } else {
        setError("No se pudieron cargar los usuarios.");
      }
    } finally {
      setCargando(false);
    }
  };

  useEffect(() => {
    cargarPerfiles();
  }, []);

  const perfilesFiltrados = useMemo(() => {
    const texto = busqueda.toLowerCase().trim();

    return perfiles.filter((perfil) => {
      const usuario = perfil.usuario_detalle || {};

      const username = usuario.username?.toLowerCase() || "";
      const email = usuario.email?.toLowerCase() || "";
      const firstName = usuario.first_name?.toLowerCase() || "";
      const lastName = usuario.last_name?.toLowerCase() || "";
      const telefono = perfil.telefono?.toLowerCase() || "";
      const cedula = perfil.cedula?.toLowerCase() || "";
      const rol = perfil.rol || "";

      const coincideBusqueda =
        !texto ||
        username.includes(texto) ||
        email.includes(texto) ||
        firstName.includes(texto) ||
        lastName.includes(texto) ||
        telefono.includes(texto) ||
        cedula.includes(texto);

      const coincideRol = !rolFiltro || rol === rolFiltro;

      return coincideBusqueda && coincideRol;
    });
  }, [busqueda, rolFiltro, perfiles]);

  const obtenerNombreCompleto = (usuario) => {
    if (!usuario) return "Sin nombre";

    const nombre = `${usuario.first_name || ""} ${usuario.last_name || ""}`.trim();

    return nombre || "Sin nombre";
  };

  if (cargando) {
    return (
      <div className="usuarios-page">
        <h2>Usuarios</h2>
        <p>Cargando usuarios...</p>
      </div>
    );
  }

  return (
    <div className="usuarios-page">
      <div className="usuarios-header">
        <div>
          <h2>Usuarios</h2>
          <p>Consulta de usuarios, operadores y administradores registrados.</p>
        </div>

        <button className="btn-secondary" onClick={cargarPerfiles}>
          Actualizar
        </button>
      </div>

      {error && <div className="usuarios-error">{error}</div>}

      <div className="usuarios-toolbar">
        <input
          type="text"
          value={busqueda}
          onChange={(e) => setBusqueda(e.target.value)}
          placeholder="Buscar por usuario, nombre, correo, teléfono o cédula..."
        />

        <select
          value={rolFiltro}
          onChange={(e) => setRolFiltro(e.target.value)}
        >
          <option value="">Todos los roles</option>
          <option value="usuario">Usuario</option>
          <option value="operador">Operador</option>
          <option value="administrador">Administrador</option>
        </select>
      </div>

      <div className="usuarios-resumen">
        <div className="resumen-card">
          <span>Total</span>
          <strong>{perfiles.length}</strong>
        </div>

        <div className="resumen-card">
          <span>Usuarios</span>
          <strong>
            {perfiles.filter((perfil) => perfil.rol === "usuario").length}
          </strong>
        </div>

        <div className="resumen-card">
          <span>Operadores</span>
          <strong>
            {perfiles.filter((perfil) => perfil.rol === "operador").length}
          </strong>
        </div>

        <div className="resumen-card">
          <span>Administradores</span>
          <strong>
            {perfiles.filter((perfil) => perfil.rol === "administrador").length}
          </strong>
        </div>
      </div>

      <div className="usuarios-table-card">
        <table>
          <thead>
            <tr>
              <th>ID Perfil</th>
              <th>Usuario</th>
              <th>Nombre</th>
              <th>Correo</th>
              <th>Teléfono</th>
              <th>Cédula</th>
              <th>Rol</th>
              <th>Estado</th>
              <th>Staff</th>
            </tr>
          </thead>

          <tbody>
            {perfilesFiltrados.length > 0 ? (
              perfilesFiltrados.map((perfil) => {
                const usuario = perfil.usuario_detalle || {};

                return (
                  <tr key={perfil.id}>
                    <td>{perfil.id}</td>
                    <td>
                      <strong>{usuario.username || perfil.usuario}</strong>
                    </td>
                    <td>{obtenerNombreCompleto(usuario)}</td>
                    <td>{usuario.email || "Sin correo"}</td>
                    <td>{perfil.telefono || "Sin teléfono"}</td>
                    <td>{perfil.cedula || "Sin cédula"}</td>
                    <td>
                      <span className={`rol ${perfil.rol}`}>
                        {perfil.rol}
                      </span>
                    </td>
                    <td>
                      <span className={perfil.estado ? "estado activo" : "estado inactivo"}>
                        {perfil.estado ? "Activo" : "Inactivo"}
                      </span>
                    </td>
                    <td>{usuario.is_staff ? "Sí" : "No"}</td>
                  </tr>
                );
              })
            ) : (
              <tr>
                <td colSpan="9">No existen usuarios que coincidan con la búsqueda.</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}

export default Usuarios;