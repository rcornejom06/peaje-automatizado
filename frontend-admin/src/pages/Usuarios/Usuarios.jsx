import {useEffect, useMemo, useState} from "react";
import {obtenerPerfiles} from "../../api/usuariosService";
import "../Styles/Usuarios.css";
//import {FiRefreshCw} from "react-icons/fi";
import ModuleHeader from "../../components/ModuleHeader/ModuleHeader";

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

        const nombre = `${usuario.first_name || ""} ${
            usuario.last_name || ""
        }`.trim();

        return nombre || "Sin nombre";
    };

    const obtenerIniciales = (usuario) => {
        if (!usuario) return "?";

        const nombre = usuario.first_name || "";
        const apellido = usuario.last_name || "";

        if (nombre && apellido) {
            return `${nombre[0]}${apellido[0]}`.toUpperCase();
        }

        if (usuario.username) {
            return usuario.username.substring(0, 2).toUpperCase();
        }

        return "?";
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
            <ModuleHeader
                icon="👤"
                title="Usuarios"
                subtitle="Consulta usuarios registrados, roles, estados y datos de contacto."
                badge="Administración"
                status="Activo"
                actions={
                <>
                <button
                    className="module-header-secondary"
                    onClick={cargarPerfiles}
                >
                    Actualizar
                </button>

                </>
                }

            />

            {error && <div className="usuarios-error">{error}</div>}

            <div className="usuarios-toolbar">
                <input
                    type="text"
                    value={busqueda}
                    onChange={(e) => setBusqueda(e.target.value)}
                    placeholder="Buscar por usuario, nombre, correo, teléfono o cédula..."
                />

                <select value={rolFiltro} onChange={(e) => setRolFiltro(e.target.value)}>
                    <option value="">Todos los roles</option>
                    <option value="usuario">Usuario</option>
                    <option value="operador">Operador</option>
                    <option value="administrador">Administrador</option>
                </select>
            </div>

            <div className="usuarios-resumen">
                <div className="resumen-card total">
                    <small>Total</small>
                    <strong>{perfiles.length}</strong>
                    <span>Usuarios registrados</span>
                </div>

                <div className="resumen-card admin">
                    <small>Administradores</small>
                    <strong>
                        {perfiles.filter((p) => p.rol === "administrador").length}
                    </strong>
                    <span>Acceso completo</span>
                </div>

                <div className="resumen-card operador">
                    <small>Operadores</small>
                    <strong>
                        {perfiles.filter((p) => p.rol === "operador").length}
                    </strong>
                    <span>Control de peajes</span>
                </div>

                <div className="resumen-card usuario">
                    <small>Clientes</small>
                    <strong>{perfiles.filter((p) => p.rol === "usuario").length}</strong>
                    <span>Usuarios finales</span>
                </div>
            </div>

            <div className="usuarios-table-card">
                <table>
                    <thead>
                    <tr>
                        <th>Usuario</th>
                        <th>Contacto</th>
                        <th>Documento</th>
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
                                    <td>
                                        <div className="usuario-info">
                                            <div className="avatar">
                                                {obtenerIniciales(usuario)}
                                            </div>

                                            <div>
                                                <strong>{obtenerNombreCompleto(usuario)}</strong>
                                                <span>@{usuario.username}</span>
                                            </div>
                                        </div>
                                    </td>

                                    <td>
                                        <div className="contacto">
                                            <div>{usuario.email || "-"}</div>
                                            <small>{perfil.telefono || "-"}</small>
                                        </div>
                                    </td>

                                    <td>{perfil.cedula || "-"}</td>

                                    <td>
                      <span className={`rol ${perfil.rol}`}>
                        {perfil.rol}
                      </span>
                                    </td>

                                    <td>
                      <span
                          className={
                              perfil.estado ? "estado activo" : "estado inactivo"
                          }
                      >
                        {perfil.estado ? "Activo" : "Inactivo"}
                      </span>
                                    </td>

                                    <td>{usuario.is_staff ? "Sí" : "No"}</td>
                                </tr>
                            );
                        })
                    ) : (
                        <tr>
                            <td colSpan="6">
                                No existen usuarios que coincidan con la búsqueda.
                            </td>
                        </tr>
                    )}
                    </tbody>
                </table>
            </div>
        </div>
    );
}

export default Usuarios;