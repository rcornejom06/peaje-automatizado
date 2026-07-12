import { useEffect, useState } from "react";
import {
  actualizarMiPerfil,
  crearOperador,
  obtenerMiPerfil,
  obtenerPerfiles,
} from "../../api/usuariosService.js";
import "../Styles/Usuarios.css";

function Usuarios() {
  const [perfiles, setPerfiles] = useState([]);
  const [miPerfil, setMiPerfil] = useState(null);

  const [mostrarFormularioOperador, setMostrarFormularioOperador] =
    useState(false);

  const [cargando, setCargando] = useState(true);
  const [guardandoOperador, setGuardandoOperador] = useState(false);
  const [guardandoPerfil, setGuardandoPerfil] = useState(false);

  const [mensaje, setMensaje] = useState("");
  const [error, setError] = useState("");

  const [formOperador, setFormOperador] = useState({
    username: "",
    email: "",
    password: "",
    first_name: "",
    last_name: "",
    telefono: "",
    cedula: "",
  });

  const [formPerfil, setFormPerfil] = useState({
    first_name: "",
    last_name: "",
    email: "",
    telefono: "",
    cedula: "",
  });

  const normalizarLista = (data) => {
    if (Array.isArray(data)) return data;
    if (Array.isArray(data?.results)) return data.results;
    if (Array.isArray(data?.perfiles)) return data.perfiles;
    return [];
  };

  const extraerMensajeError = (error) => {
    const data = error?.response?.data;

    if (!data) {
      return "Ocurrió un error inesperado.";
    }

    if (typeof data === "string") {
      return data;
    }

    if (data.error) {
      return data.error;
    }

    if (data.detail) {
      return data.detail;
    }

    if (data.mensaje) {
      return data.mensaje;
    }

    const primeraClave = Object.keys(data)[0];

    if (primeraClave) {
      const valor = data[primeraClave];

      if (Array.isArray(valor)) {
        return `${primeraClave}: ${valor.join(", ")}`;
      }

      if (typeof valor === "string") {
        return `${primeraClave}: ${valor}`;
      }
    }

    return "No se pudo completar la acción.";
  };

  const cargarDatos = async () => {
    setCargando(true);
    setError("");
    setMensaje("");

    try {
      const [perfilesData, miPerfilData] = await Promise.all([
        obtenerPerfiles(),
        obtenerMiPerfil(),
      ]);

      const lista = normalizarLista(perfilesData);

      setPerfiles(lista);
      setMiPerfil(miPerfilData);

      const usuario = miPerfilData?.usuario_detalle || {};

      setFormPerfil({
        first_name: usuario.first_name || "",
        last_name: usuario.last_name || "",
        email: usuario.email || "",
        telefono: miPerfilData?.telefono || "",
        cedula: miPerfilData?.cedula || "",
      });
    } catch (error) {
      setError(extraerMensajeError(error));
    } finally {
      setCargando(false);
    }
  };

  useEffect(() => {
    cargarDatos();
  }, []);

  const esAdministrador = () => {
    const usuario = miPerfil?.usuario_detalle;

    return (
      miPerfil?.rol === "administrador" ||
      usuario?.is_staff === true ||
      usuario?.is_superuser === true
    );
  };

  const limpiarFormularioOperador = () => {
    setFormOperador({
      username: "",
      email: "",
      password: "",
      first_name: "",
      last_name: "",
      telefono: "",
      cedula: "",
    });
  };

  const handleChangeOperador = (e) => {
    const { name, value } = e.target;

    setFormOperador((prev) => ({
      ...prev,
      [name]: value,
    }));
  };

  const handleChangePerfil = (e) => {
    const { name, value } = e.target;

    setFormPerfil((prev) => ({
      ...prev,
      [name]: value,
    }));
  };

  const handleCrearOperador = async (e) => {
    e.preventDefault();

    setError("");
    setMensaje("");

    if (!formOperador.username.trim()) {
      setError("Ingresa el nombre de usuario del operador.");
      return;
    }

    if (!formOperador.email.trim()) {
      setError("Ingresa el correo del operador.");
      return;
    }

    if (!formOperador.password.trim()) {
      setError("Ingresa una contraseña temporal.");
      return;
    }

    if (formOperador.password.length < 8) {
      setError("La contraseña debe tener mínimo 8 caracteres.");
      return;
    }

    setGuardandoOperador(true);

    try {
      await crearOperador({
        username: formOperador.username.trim(),
        email: formOperador.email.trim(),
        password: formOperador.password,
        first_name: formOperador.first_name.trim(),
        last_name: formOperador.last_name.trim(),
        telefono: formOperador.telefono.trim(),
        cedula: formOperador.cedula.trim(),
      });

      setMensaje("Operador creado correctamente.");
      limpiarFormularioOperador();
      setMostrarFormularioOperador(false);
      await cargarDatos();
    } catch (error) {
      setError(extraerMensajeError(error));
    } finally {
      setGuardandoOperador(false);
    }
  };

  const handleActualizarPerfil = async (e) => {
    e.preventDefault();

    setError("");
    setMensaje("");
    setGuardandoPerfil(true);

    try {
      await actualizarMiPerfil({
        first_name: formPerfil.first_name.trim(),
        last_name: formPerfil.last_name.trim(),
        email: formPerfil.email.trim(),
        telefono: formPerfil.telefono.trim(),
        cedula: formPerfil.cedula.trim(),
      });

      setMensaje("Tu perfil fue actualizado correctamente.");
      await cargarDatos();
    } catch (error) {
      setError(extraerMensajeError(error));
    } finally {
      setGuardandoPerfil(false);
    }
  };

  const nombreUsuario = (perfil) => {
    const usuario = perfil?.usuario_detalle;

    const nombreCompleto = `${usuario?.first_name || ""} ${
      usuario?.last_name || ""
    }`.trim();

    return nombreCompleto || usuario?.username || "Sin nombre";
  };

  const correoUsuario = (perfil) => {
    return perfil?.usuario_detalle?.email || "Sin correo";
  };

  const formatearFecha = (fecha) => {
    if (!fecha) return "Sin fecha";

    try {
      return new Date(fecha).toLocaleDateString("es-EC", {
        year: "numeric",
        month: "short",
        day: "2-digit",
      });
    } catch {
      return fecha;
    }
  };

  return (
    <div className="usuarios-page">
      <section className="usuarios-hero">
        <div>
          <span className="usuarios-kicker">VíaSmart</span>
          <h2>Gestión de usuarios</h2>
          <p>
            Administra operadores del sistema y actualiza la información de tu
            perfil personal.
          </p>
        </div>

        <div className="usuarios-hero-actions">
          {esAdministrador() && (
            <button
              type="button"
              className="usuarios-btn-primary"
              onClick={() =>
                setMostrarFormularioOperador((actual) => !actual)
              }
            >
              {mostrarFormularioOperador ? "Cancelar" : "+ Crear operador"}
            </button>
          )}

          <button
            type="button"
            className="usuarios-btn-secondary"
            onClick={cargarDatos}
          >
            Actualizar
          </button>
        </div>
      </section>

      {mensaje && <div className="usuarios-alert success">{mensaje}</div>}
      {error && <div className="usuarios-alert error">{error}</div>}

      {cargando ? (
        <div className="usuarios-loading">Cargando usuarios...</div>
      ) : (
        <>
          {mostrarFormularioOperador && esAdministrador() && (
            <section className="usuarios-card">
              <div className="usuarios-card-header">
                <div>
                  <h3>Crear operador</h3>
                  <p>
                    El operador podrá iniciar sesión y gestionar módulos
                    permitidos del sistema.
                  </p>
                </div>
              </div>

              <form
                className="usuarios-form"
                onSubmit={handleCrearOperador}
              >
                <div className="usuarios-grid">
                  <div className="usuarios-field">
                    <label>Usuario *</label>
                    <input
                      type="text"
                      name="username"
                      value={formOperador.username}
                      onChange={handleChangeOperador}
                      placeholder="operador1"
                    />
                  </div>

                  <div className="usuarios-field">
                    <label>Correo *</label>
                    <input
                      type="email"
                      name="email"
                      value={formOperador.email}
                      onChange={handleChangeOperador}
                      placeholder="operador@viasmart.com"
                    />
                  </div>

                  <div className="usuarios-field">
                    <label>Contraseña temporal *</label>
                    <input
                      type="password"
                      name="password"
                      value={formOperador.password}
                      onChange={handleChangeOperador}
                      placeholder="Mínimo 8 caracteres"
                    />
                  </div>

                  <div className="usuarios-field">
                    <label>Nombres</label>
                    <input
                      type="text"
                      name="first_name"
                      value={formOperador.first_name}
                      onChange={handleChangeOperador}
                      placeholder="Nombres"
                    />
                  </div>

                  <div className="usuarios-field">
                    <label>Apellidos</label>
                    <input
                      type="text"
                      name="last_name"
                      value={formOperador.last_name}
                      onChange={handleChangeOperador}
                      placeholder="Apellidos"
                    />
                  </div>

                  <div className="usuarios-field">
                    <label>Teléfono</label>
                    <input
                      type="text"
                      name="telefono"
                      value={formOperador.telefono}
                      onChange={handleChangeOperador}
                      placeholder="0999999999"
                      maxLength="10"
                    />
                  </div>

                  <div className="usuarios-field">
                    <label>Cédula</label>
                    <input
                      type="text"
                      name="cedula"
                      value={formOperador.cedula}
                      onChange={handleChangeOperador}
                      placeholder="0102030405"
                      maxLength="10"
                    />
                  </div>
                </div>

                <div className="usuarios-form-actions">
                  <button
                    type="button"
                    className="usuarios-btn-secondary"
                    onClick={() => {
                      limpiarFormularioOperador();
                      setMostrarFormularioOperador(false);
                    }}
                  >
                    Cancelar
                  </button>

                  <button
                    type="submit"
                    className="usuarios-btn-primary"
                    disabled={guardandoOperador}
                  >
                    {guardandoOperador
                      ? "Creando..."
                      : "Crear operador"}
                  </button>
                </div>
              </form>
            </section>
          )}

          <section className="usuarios-card">
            <div className="usuarios-card-header">
              <div>
                <h3>Mi perfil</h3>
                <p>Actualiza tu información personal de la cuenta.</p>
              </div>

              <span className="usuarios-role-badge">
                {miPerfil?.rol || "usuario"}
              </span>
            </div>

            <form className="usuarios-form" onSubmit={handleActualizarPerfil}>
              <div className="usuarios-grid">
                <div className="usuarios-field">
                  <label>Nombres</label>
                  <input
                    type="text"
                    name="first_name"
                    value={formPerfil.first_name}
                    onChange={handleChangePerfil}
                    placeholder="Tus nombres"
                  />
                </div>

                <div className="usuarios-field">
                  <label>Apellidos</label>
                  <input
                    type="text"
                    name="last_name"
                    value={formPerfil.last_name}
                    onChange={handleChangePerfil}
                    placeholder="Tus apellidos"
                  />
                </div>

                <div className="usuarios-field">
                  <label>Correo</label>
                  <input
                    type="email"
                    name="email"
                    value={formPerfil.email}
                    onChange={handleChangePerfil}
                    placeholder="correo@ejemplo.com"
                  />
                </div>

                <div className="usuarios-field">
                  <label>Teléfono</label>
                  <input
                    type="text"
                    name="telefono"
                    value={formPerfil.telefono}
                    onChange={handleChangePerfil}
                    placeholder="0999999999"
                    maxLength="10"
                  />
                </div>

                <div className="usuarios-field">
                  <label>Cédula</label>
                  <input
                    type="text"
                    name="cedula"
                    value={formPerfil.cedula}
                    onChange={handleChangePerfil}
                    placeholder="0102030405"
                    maxLength="10"
                  />
                </div>
              </div>

              <div className="usuarios-form-actions">
                <button
                  type="submit"
                  className="usuarios-btn-primary"
                  disabled={guardandoPerfil}
                >
                  {guardandoPerfil ? "Guardando..." : "Guardar mi perfil"}
                </button>
              </div>
            </form>
          </section>

          <section className="usuarios-card">
            <div className="usuarios-card-header">
              <div>
                <h3>Usuarios registrados</h3>
                <p>
                  Lista de perfiles disponibles según tus permisos de acceso.
                </p>
              </div>
            </div>

            <div className="usuarios-table-wrapper">
              <table className="usuarios-table">
                <thead>
                  <tr>
                    <th>Usuario</th>
                    <th>Correo</th>
                    <th>Rol</th>
                    <th>Teléfono</th>
                    <th>Estado</th>
                    <th>Creación</th>
                  </tr>
                </thead>

                <tbody>
                  {perfiles.length === 0 ? (
                    <tr>
                      <td colSpan="6" className="usuarios-empty">
                        No hay usuarios registrados.
                      </td>
                    </tr>
                  ) : (
                    perfiles.map((perfil) => (
                      <tr key={perfil.id}>
                        <td>
                          <div className="usuarios-user-cell">
                            <div className="usuarios-avatar">
                              {nombreUsuario(perfil).charAt(0).toUpperCase()}
                            </div>

                            <div>
                              <strong>{nombreUsuario(perfil)}</strong>
                              <span>
                                @{perfil?.usuario_detalle?.username ||
                                  "sin_usuario"}
                              </span>
                            </div>
                          </div>
                        </td>

                        <td>{correoUsuario(perfil)}</td>

                        <td>
                          <span className={`usuarios-tag ${perfil.rol}`}>
                            {perfil.rol}
                          </span>
                        </td>

                        <td>{perfil.telefono || "Sin teléfono"}</td>

                        <td>
                          <span
                            className={
                              perfil.estado
                                ? "usuarios-status active"
                                : "usuarios-status inactive"
                            }
                          >
                            {perfil.estado ? "Activo" : "Inactivo"}
                          </span>
                        </td>

                        <td>{formatearFecha(perfil.fecha_creacion)}</td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          </section>
        </>
      )}
    </div>
  );
}

export default Usuarios;