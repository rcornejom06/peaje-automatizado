import { useEffect, useState } from "react";
import {
  actualizarMiPerfil,
  activarUsuario,
  crearOperador,
  desactivarUsuario,
  obtenerMiPerfil,
  obtenerPerfiles,
} from "../../api/usuariosService.js";
import "../Styles/Usuarios.css";

// Patrones de validación por tipo de dato
const REGEX_USERNAME = /^[A-Za-z0-9._-]{4,20}$/;
const REGEX_EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const REGEX_NOMBRE = /^[A-Za-zÁÉÍÓÚÜáéíóúüÑñ]+(?: [A-Za-zÁÉÍÓÚÜáéíóúüÑñ]+)*$/;
const REGEX_TELEFONO = /^\d{7,10}$/;
const REGEX_CEDULA = /^\d{10}$/;

// Filtra caracteres mientras el usuario escribe (evita espacios y símbolos no permitidos)
const filtrarUsername = (valor) =>
  String(valor).replace(/[^A-Za-z0-9._-]/g, "");

const filtrarEmail = (valor) => String(valor).replace(/\s/g, "");

const filtrarPassword = (valor) => String(valor).replace(/\s/g, "");

const filtrarNombre = (valor) =>
  String(valor)
    .replace(/[^A-Za-zÁÉÍÓÚÜáéíóúüÑñ\s]/g, "")
    .replace(/\s{2,}/g, " ")
    .replace(/^\s+/, "");

const filtrarSoloDigitos = (valor) => String(valor).replace(/[^0-9]/g, "");

function Usuarios() {
  const [perfiles, setPerfiles] = useState([]);
  const [miPerfil, setMiPerfil] = useState(null);

  const [mostrarFormularioOperador, setMostrarFormularioOperador] =
    useState(false);
  const [mostrarFormularioPerfil, setMostrarFormularioPerfil] = useState(false);

  const [cargando, setCargando] = useState(true);
  const [guardandoOperador, setGuardandoOperador] = useState(false);
  const [guardandoPerfil, setGuardandoPerfil] = useState(false);
  const [procesandoUsuarioId, setProcesandoUsuarioId] = useState(null);

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

    if (data.message) {
      return data.message;
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
    let valorLimpio = value;

    switch (name) {
      case "username":
        valorLimpio = filtrarUsername(value);
        break;
      case "email":
        valorLimpio = filtrarEmail(value);
        break;
      case "password":
        valorLimpio = filtrarPassword(value);
        break;
      case "first_name":
      case "last_name":
        valorLimpio = filtrarNombre(value);
        break;
      case "telefono":
      case "cedula":
        valorLimpio = filtrarSoloDigitos(value);
        break;
      default:
        valorLimpio = value;
    }

    setFormOperador((prev) => ({
      ...prev,
      [name]: valorLimpio,
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

    if (!REGEX_USERNAME.test(formOperador.username.trim())) {
      setError(
        "El usuario debe tener entre 4 y 20 caracteres: letras, números, puntos, guiones o guion bajo, sin espacios."
      );
      return;
    }

    if (!formOperador.email.trim()) {
      setError("Ingresa el correo del operador.");
      return;
    }

    if (!REGEX_EMAIL.test(formOperador.email.trim())) {
      setError("Ingresa un correo electrónico válido, sin espacios.");
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

    if (
      formOperador.first_name.trim() &&
      !REGEX_NOMBRE.test(formOperador.first_name.trim())
    ) {
      setError("Los nombres solo pueden contener letras y espacios.");
      return;
    }

    if (
      formOperador.last_name.trim() &&
      !REGEX_NOMBRE.test(formOperador.last_name.trim())
    ) {
      setError("Los apellidos solo pueden contener letras y espacios.");
      return;
    }

    if (
      formOperador.telefono.trim() &&
      !REGEX_TELEFONO.test(formOperador.telefono.trim())
    ) {
      setError("El teléfono debe tener entre 7 y 10 dígitos numéricos, sin espacios.");
      return;
    }

    if (
      formOperador.cedula.trim() &&
      !REGEX_CEDULA.test(formOperador.cedula.trim())
    ) {
      setError("La cédula debe tener 10 dígitos numéricos, sin espacios ni letras.");
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
      setMostrarFormularioPerfil(false);
      await cargarDatos();
    } catch (error) {
      setError(extraerMensajeError(error));
    } finally {
      setGuardandoPerfil(false);
    }
  };

  const handleCambiarEstadoUsuario = async (perfil) => {
    if (!esAdministrador()) {
      setError("No tienes permisos para cambiar el estado de usuarios.");
      return;
    }

    const esMiPerfil = perfil?.id === miPerfil?.id;

    if (esMiPerfil) {
      setError("No puedes desactivar tu propio perfil.");
      return;
    }

    const usuario = perfil?.usuario_detalle;
    const nombre = nombreUsuario(perfil);
    const estaActivo = perfil?.estado === true;

    const confirmar = window.confirm(
      estaActivo
        ? `¿Deseas desactivar al usuario ${nombre}?`
        : `¿Deseas activar al usuario ${nombre}?`
    );

    if (!confirmar) return;

    setError("");
    setMensaje("");
    setProcesandoUsuarioId(perfil.id);

    try {
      if (estaActivo) {
        await desactivarUsuario(perfil.id);
        setMensaje(`Usuario ${nombre} desactivado correctamente.`);
      } else {
        await activarUsuario(perfil.id);
        setMensaje(`Usuario ${nombre} activado correctamente.`);
      }

      await cargarDatos();
    } catch (error) {
      setError(extraerMensajeError(error));
    } finally {
      setProcesandoUsuarioId(null);
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

  const usernameUsuario = (perfil) => {
    return perfil?.usuario_detalle?.username || "sin_usuario";
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

  const textoRol = (rol) => {
    if (rol === "administrador") return "Administrador";
    if (rol === "operador") return "Operador";
    if (rol === "usuario") return "Usuario";
    return rol || "Sin rol";
  };

  const renderMiPerfil = () => {
    const usuario = miPerfil?.usuario_detalle || {};
    const nombre = nombreUsuario(miPerfil);

    return (
      <section className="usuarios-card">
        <div className="usuarios-card-header usuarios-profile-header">
          <div>
            <h3>Mi perfil</h3>
            <p>Consulta y actualiza la información de tu cuenta.</p>
          </div>

          <div className="usuarios-profile-actions">
            <span className="usuarios-role-badge">
              {textoRol(miPerfil?.rol)}
            </span>

            <button
              type="button"
              className="usuarios-btn-primary"
              onClick={() =>
                setMostrarFormularioPerfil((actual) => !actual)
              }
            >
              {mostrarFormularioPerfil ? "Cancelar edición" : "Editar perfil"}
            </button>
          </div>
        </div>

        {!mostrarFormularioPerfil && (
          <div className="usuarios-profile-summary">
            <div className="usuarios-profile-avatar">
              {nombre.charAt(0).toUpperCase()}
            </div>

            <div className="usuarios-profile-info">
              <strong>{nombre}</strong>
              <span>@{usuario.username || "sin_usuario"}</span>
              <span>{usuario.email || "Sin correo"}</span>
            </div>

            <div className="usuarios-profile-data">
              <span>
                <strong>Teléfono:</strong> {miPerfil?.telefono || "Sin teléfono"}
              </span>
              <span>
                <strong>Cédula:</strong> {miPerfil?.cedula || "Sin cédula"}
              </span>
              <span>
                <strong>Estado:</strong>{" "}
                {miPerfil?.estado ? "Activo" : "Inactivo"}
              </span>
            </div>
          </div>
        )}

        {mostrarFormularioPerfil && (
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
                type="button"
                className="usuarios-btn-secondary"
                onClick={() => setMostrarFormularioPerfil(false)}
              >
                Cancelar
              </button>

              <button
                type="submit"
                className="usuarios-btn-primary"
                disabled={guardandoPerfil}
              >
                {guardandoPerfil ? "Guardando..." : "Guardar cambios"}
              </button>
            </div>
          </form>
        )}
      </section>
    );
  };

  return (
    <div className="usuarios-page">
      <section className="usuarios-hero">
        <div>
          <span className="usuarios-kicker">VíaSmart</span>
          <h2>Gestión de usuarios</h2>
          <p>
            Administra operadores, usuarios del sistema y actualiza la
            información de tu perfil personal.
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
                      maxLength={20}
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
                      maxLength={100}
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
                      maxLength={50}
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
                      maxLength={60}
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
                      maxLength={60}
                    />
                  </div>

                  <div className="usuarios-field">
                    <label>Teléfono</label>
                    <input
                      type="text"
                      name="telefono"
                      inputMode="numeric"
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
                      inputMode="numeric"
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
                    {guardandoOperador ? "Creando..." : "Crear operador"}
                  </button>
                </div>
              </form>
            </section>
          )}

          {renderMiPerfil()}

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
                    {esAdministrador() && <th>Acciones</th>}
                  </tr>
                </thead>

                <tbody>
                  {perfiles.length === 0 ? (
                    <tr>
                      <td
                        colSpan={esAdministrador() ? 7 : 6}
                        className="usuarios-empty"
                      >
                        No hay usuarios registrados.
                      </td>
                    </tr>
                  ) : (
                    perfiles.map((perfil) => {
                      const esMiPerfil = perfil?.id === miPerfil?.id;
                      const estaActivo = perfil?.estado === true;
                      const procesando =
                        procesandoUsuarioId === perfil?.id;

                      return (
                        <tr key={perfil.id}>
                          <td>
                            <div className="usuarios-user-cell">
                              <div className="usuarios-avatar">
                                {nombreUsuario(perfil)
                                  .charAt(0)
                                  .toUpperCase()}
                              </div>

                              <div>
                                <strong>{nombreUsuario(perfil)}</strong>
                                <span>@{usernameUsuario(perfil)}</span>
                              </div>
                            </div>
                          </td>

                          <td>{correoUsuario(perfil)}</td>

                          <td>
                            <span className={`usuarios-tag ${perfil.rol}`}>
                              {textoRol(perfil.rol)}
                            </span>
                          </td>

                          <td>{perfil.telefono || "Sin teléfono"}</td>

                          <td>
                            <span
                              className={
                                estaActivo
                                  ? "usuarios-status active"
                                  : "usuarios-status inactive"
                              }
                            >
                              {estaActivo ? "Activo" : "Inactivo"}
                            </span>
                          </td>

                          <td>{formatearFecha(perfil.fecha_creacion)}</td>

                          {esAdministrador() && (
                            <td>
                              <button
                                type="button"
                                className={
                                  estaActivo
                                    ? "usuarios-btn-danger"
                                    : "usuarios-btn-success"
                                }
                                disabled={procesando || esMiPerfil}
                                onClick={() =>
                                  handleCambiarEstadoUsuario(perfil)
                                }
                                title={
                                  esMiPerfil
                                    ? "No puedes desactivar tu propio perfil"
                                    : ""
                                }
                              >
                                {procesando
                                  ? "Procesando..."
                                  : estaActivo
                                  ? "Desactivar"
                                  : "Activar"}
                              </button>
                            </td>
                          )}
                        </tr>
                      );
                    })
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
