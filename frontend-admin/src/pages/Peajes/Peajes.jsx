import { useEffect, useState } from "react";
import {
  obtenerPeajes,
  crearPeaje,
  actualizarPeaje,
  obtenerCategoriasVehiculo,
  obtenerViasConcesionadas,
  crearViaConcesionada,
  actualizarViaConcesionada,
} from "../../api/peajeService.js";
import ModuleHeader from "../../components/ModuleHeader/ModuleHeader";
import "../Styles/Peajes.css";

function Peajes() {
  const [peajes, setPeajes] = useState([]);
  const [categorias, setCategorias] = useState([]);
  const [viasConcesionadas, setViasConcesionadas] = useState([]);

  const [cargando, setCargando] = useState(true);
  const [guardando, setGuardando] = useState(false);
  const [guardandoVia, setGuardandoVia] = useState(false);

  const [error, setError] = useState("");
  const [mensaje, setMensaje] = useState("");

  const [mostrarFormulario, setMostrarFormulario] = useState(false);
  const [mostrarDetalle, setMostrarDetalle] = useState(false);
  const [mostrarVias, setMostrarVias] = useState(false);

  const [peajeSeleccionado, setPeajeSeleccionado] = useState(null);
  const [peajeEditandoId, setPeajeEditandoId] = useState(null);
  const [viaEditandoId, setViaEditandoId] = useState(null);

  const [formulario, setFormulario] = useState({
    nombre: "",
    ciudad: "",
    ubicacion: "",
    latitud: "",
    longitud: "",
    via_concesionada: "",
    orden_en_via: "0",
    estado: "activo",
  });

  const [tarifasCategoria, setTarifasCategoria] = useState({});

  const [formularioVia, setFormularioVia] = useState({
    nombre: "",
    codigo: "",
    descripcion: "",
    tiempo_validez_minutos: "120",
    cobro_unico_por_trayecto: true,
    estado: true,
  });

  const normalizarLista = (data) => {
    if (Array.isArray(data)) return data;
    if (Array.isArray(data?.results)) return data.results;
    return [];
  };

  const limpiarDecimal = (valor) => {
    return String(valor || "").trim().replace(",", ".");
  };

  const formatearDinero = (valor) => {
    const numero = Number(valor);

    if (Number.isNaN(numero)) {
      return "$0.00";
    }

    return `$${numero.toFixed(2)}`;
  };

  const obtenerTarifasPeaje = (peaje) => {
    if (Array.isArray(peaje?.tarifas_categoria)) {
      return peaje.tarifas_categoria;
    }

    if (Array.isArray(peaje?.tarifas)) {
      return peaje.tarifas;
    }

    return [];
  };

  const obtenerCategoriaIdTarifa = (tarifa) => {
    if (tarifa?.categoria && typeof tarifa.categoria === "object") {
      return tarifa.categoria.id;
    }

    if (tarifa?.categoria) {
      return tarifa.categoria;
    }

    if (tarifa?.categoria_id) {
      return tarifa.categoria_id;
    }

    return null;
  };

  const inicializarTarifas = (listaCategorias, peaje = null) => {
    const tarifasExistentes = obtenerTarifasPeaje(peaje);
    const nuevasTarifas = {};

    listaCategorias.forEach((categoria) => {
      const tarifaEncontrada = tarifasExistentes.find((tarifa) => {
        return Number(obtenerCategoriaIdTarifa(tarifa)) === Number(categoria.id);
      });

      nuevasTarifas[categoria.id] = tarifaEncontrada
        ? String(tarifaEncontrada.valor)
        : "";
    });

    setTarifasCategoria(nuevasTarifas);
  };

  const cargarDatos = async () => {
    try {
      setCargando(true);
      setError("");
      setMensaje("");

      const [dataPeajes, dataCategorias, dataVias] = await Promise.all([
        obtenerPeajes(),
        obtenerCategoriasVehiculo(),
        obtenerViasConcesionadas(),
      ]);

      const listaPeajes = normalizarLista(dataPeajes);
      const listaCategorias = normalizarLista(dataCategorias);
      const listaVias = normalizarLista(dataVias);

      const categoriasActivas = listaCategorias.filter((categoria) => {
        return (
          categoria.estado === true ||
          categoria.estado === "true" ||
          categoria.estado === 1
        );
      });

      setPeajes(listaPeajes);
      setCategorias(categoriasActivas);
      setViasConcesionadas(listaVias);

      if (Object.keys(tarifasCategoria).length === 0) {
        inicializarTarifas(categoriasActivas);
      }
    } catch (error) {
      console.error("Error cargando datos:", error);
      setError("No se pudieron cargar los peajes, categorías o vías concesionadas.");
    } finally {
      setCargando(false);
    }
  };

  useEffect(() => {
    cargarDatos();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const limpiarFormularioPeaje = () => {
    setFormulario({
      nombre: "",
      ciudad: "",
      ubicacion: "",
      latitud: "",
      longitud: "",
      via_concesionada: "",
      orden_en_via: "0",
      estado: "activo",
    });

    setPeajeEditandoId(null);
    inicializarTarifas(categorias);
  };

  const abrirFormularioCrear = () => {
    setError("");
    setMensaje("");
    setPeajeEditandoId(null);
    limpiarFormularioPeaje();
    setMostrarFormulario(true);
  };

  const cerrarFormulario = () => {
    setMostrarFormulario(false);
    limpiarFormularioPeaje();
  };

  const abrirDetalles = (peaje) => {
    setPeajeSeleccionado(peaje);
    setMostrarDetalle(true);
  };

  const cerrarDetalles = () => {
    setPeajeSeleccionado(null);
    setMostrarDetalle(false);
  };

  const editarPeaje = (peaje) => {
    setError("");
    setMensaje("");
    setPeajeEditandoId(peaje.id);

    setFormulario({
      nombre: peaje.nombre || "",
      ciudad: peaje.ciudad || "",
      ubicacion: peaje.ubicacion || "",
      latitud: peaje.latitud || "",
      longitud: peaje.longitud || "",
      via_concesionada: peaje.via_concesionada
        ? String(peaje.via_concesionada)
        : "",
      orden_en_via:
        peaje.orden_en_via !== null && peaje.orden_en_via !== undefined
          ? String(peaje.orden_en_via)
          : "0",
      estado: peaje.estado || "activo",
    });

    inicializarTarifas(categorias, peaje);
    setMostrarFormulario(true);
  };

  const handleChange = (e) => {
    setFormulario({
      ...formulario,
      [e.target.name]: e.target.value,
    });
  };

  const handleTarifaChange = (categoriaId, valor) => {
    setTarifasCategoria({
      ...tarifasCategoria,
      [categoriaId]: valor,
    });
  };

  const validarFormularioPeaje = () => {
    if (!formulario.nombre.trim()) return "Ingrese el nombre del peaje.";
    if (!formulario.ciudad.trim()) return "Ingrese la ciudad del peaje.";
    if (!formulario.ubicacion.trim()) return "Ingrese la ubicación del peaje.";
    if (!formulario.latitud.trim()) return "Ingrese la latitud del peaje.";
    if (!formulario.longitud.trim()) return "Ingrese la longitud del peaje.";

    const orden = Number(formulario.orden_en_via || 0);

    if (Number.isNaN(orden) || orden < 0) {
      return "El orden en la vía debe ser un número mayor o igual a 0.";
    }

    if (categorias.length === 0) {
      return "No existen categorías activas para configurar tarifas.";
    }

    for (const categoria of categorias) {
      const valor = limpiarDecimal(tarifasCategoria[categoria.id]);

      if (!valor) {
        return `Ingrese la tarifa para la categoría ${categoria.nombre}.`;
      }

      const numero = Number(valor);

      if (Number.isNaN(numero) || numero <= 0) {
        return `La tarifa de ${categoria.nombre} debe ser mayor a 0.`;
      }
    }

    return "";
  };

  const construirTarifas = () => {
    return categorias.map((categoria) => ({
      categoria: categoria.id,
      valor: limpiarDecimal(tarifasCategoria[categoria.id]),
      estado: true,
    }));
  };

  const handleSubmitPeaje = async (e) => {
    e.preventDefault();

    try {
      setError("");
      setMensaje("");

      const errorValidacion = validarFormularioPeaje();

      if (errorValidacion) {
        setError(errorValidacion);
        return;
      }

      setGuardando(true);

      const payload = {
        nombre: formulario.nombre.trim(),
        ciudad: formulario.ciudad.trim(),
        ubicacion: formulario.ubicacion.trim(),
        latitud: limpiarDecimal(formulario.latitud),
        longitud: limpiarDecimal(formulario.longitud),
        tarifa: "0.00",
        via_concesionada: formulario.via_concesionada
          ? Number(formulario.via_concesionada)
          : null,
        orden_en_via: Number(formulario.orden_en_via || 0),
        estado: formulario.estado,
        tarifas: construirTarifas(),
      };

      if (peajeEditandoId) {
        await actualizarPeaje(peajeEditandoId, payload);
        setMensaje("Peaje actualizado correctamente.");
      } else {
        await crearPeaje(payload);
        setMensaje("Peaje creado correctamente.");
      }

      setMostrarFormulario(false);
      limpiarFormularioPeaje();
      await cargarDatos();
    } catch (error) {
      const detalleError = error.response?.data || error.message || error;

      console.error(
        "Error guardando peaje:",
        JSON.stringify(detalleError, null, 2)
      );

      if (error.response?.status === 403) {
        setError(
          "No tiene permisos para guardar peajes. Use una cuenta administradora."
        );
      } else if (error.response?.data) {
        setError(
          `No se pudo guardar el peaje: ${JSON.stringify(error.response.data)}`
        );
      } else {
        setError("No se pudo guardar el peaje. Verifique los datos.");
      }
    } finally {
      setGuardando(false);
    }
  };

  const limpiarFormularioVia = () => {
    setViaEditandoId(null);
    setFormularioVia({
      nombre: "",
      codigo: "",
      descripcion: "",
      tiempo_validez_minutos: "120",
      cobro_unico_por_trayecto: true,
      estado: true,
    });
  };

  const abrirGestorVias = () => {
    setError("");
    setMensaje("");
    limpiarFormularioVia();
    setMostrarVias(true);
  };

  const cerrarGestorVias = () => {
    setMostrarVias(false);
    limpiarFormularioVia();
  };

  const editarVia = (via) => {
    setViaEditandoId(via.id);

    setFormularioVia({
      nombre: via.nombre || "",
      codigo: via.codigo || "",
      descripcion: via.descripcion || "",
      tiempo_validez_minutos: String(via.tiempo_validez_minutos || 120),
      cobro_unico_por_trayecto: via.cobro_unico_por_trayecto !== false,
      estado: via.estado !== false,
    });
  };

  const handleViaChange = (e) => {
    const { name, value, type, checked } = e.target;

    setFormularioVia({
      ...formularioVia,
      [name]: type === "checkbox" ? checked : value,
    });
  };

  const validarFormularioVia = () => {
    if (!formularioVia.nombre.trim()) {
      return "Ingrese el nombre de la vía concesionada.";
    }

    if (!formularioVia.codigo.trim()) {
      return "Ingrese el código de la vía concesionada.";
    }

    const tiempo = Number(formularioVia.tiempo_validez_minutos);

    if (Number.isNaN(tiempo) || tiempo <= 0) {
      return "El tiempo de validez debe ser mayor a 0 minutos.";
    }

    return "";
  };

  const handleSubmitVia = async (e) => {
    e.preventDefault();

    try {
      setError("");
      setMensaje("");

      const errorValidacion = validarFormularioVia();

      if (errorValidacion) {
        setError(errorValidacion);
        return;
      }

      setGuardandoVia(true);

      const payload = {
        nombre: formularioVia.nombre.trim(),
        codigo: formularioVia.codigo.trim().toUpperCase(),
        descripcion: formularioVia.descripcion.trim(),
        tiempo_validez_minutos: Number(formularioVia.tiempo_validez_minutos),
        cobro_unico_por_trayecto: formularioVia.cobro_unico_por_trayecto,
        estado: formularioVia.estado,
      };

      if (viaEditandoId) {
        await actualizarViaConcesionada(viaEditandoId, payload);
        setMensaje("Vía concesionada actualizada correctamente.");
      } else {
        await crearViaConcesionada(payload);
        setMensaje("Vía concesionada creada correctamente.");
      }

      limpiarFormularioVia();
      await cargarDatos();
    } catch (error) {
      console.error("Error guardando vía concesionada:", error.response?.data || error);

      if (error.response?.status === 403) {
        setError(
          "No tiene permisos para guardar vías concesionadas. Use una cuenta administradora."
        );
      } else if (error.response?.data) {
        setError(
          `No se pudo guardar la vía concesionada: ${JSON.stringify(
            error.response.data
          )}`
        );
      } else {
        setError("No se pudo guardar la vía concesionada.");
      }
    } finally {
      setGuardandoVia(false);
    }
  };

  const renderTarifasDetalle = (peaje) => {
    const tarifas = obtenerTarifasPeaje(peaje).filter(
      (tarifa) => tarifa.estado !== false
    );

    if (tarifas.length === 0) {
      return (
        <div className="tarifa-vacia-detalle">
          Sin tarifas configuradas.
        </div>
      );
    }

    return (
      <div className="detalle-tarifas-list">
        {tarifas.map((tarifa, index) => (
          <div className="detalle-tarifa-row" key={tarifa.id || index}>
            <span>{tarifa.categoria_nombre || "Categoría sin nombre"}</span>
            <strong>{formatearDinero(tarifa.valor)}</strong>
          </div>
        ))}
      </div>
    );
  };

  const renderViaTabla = (peaje) => {
    if (!peaje.via_concesionada_nombre) {
      return <span className="via-empty">Sin vía</span>;
    }

    return (
      <span className="via-chip">
        {peaje.via_concesionada_nombre}
      </span>
    );
  };

  return (
    <div className="peajes-page">
      <ModuleHeader
        icon="🛣️"
        title="Gestión de peajes"
        subtitle="Administra estaciones, vías concesionadas y tarifas por categoría."
        badge="Módulo de peajes"
        status="Sistema activo"
        actions={
          <>
            <button
              type="button"
              className="module-header-primary"
              onClick={abrirFormularioCrear}
            >
              + Nuevo peaje
            </button>

            <button
              type="button"
              className="module-header-secondary"
              onClick={abrirGestorVias}
            >
              Vías concesionadas
            </button>

            <button
              type="button"
              className="module-header-secondary"
              onClick={cargarDatos}
            >
              Actualizar
            </button>
          </>
        }
      />

      {cargando && <p className="peajes-loading">Cargando peajes...</p>}

      {error && <div className="peajes-error">{error}</div>}

      {mensaje && <div className="peajes-success">{mensaje}</div>}

      <div className="peajes-info-card">
        <strong>Nota:</strong> Las tarifas no se muestran en la tabla. Para
        visualizarlas usa <strong>Ver detalles</strong>. Las vías concesionadas
        permiten exonerar un segundo cobro si el vehículo ya pagó en otro peaje
        de la misma vía dentro del tiempo configurado.
      </div>

      {mostrarFormulario && (
        <div className="modal-overlay" onClick={cerrarFormulario}>
          <div
            className="modal-card peaje-modal"
            onClick={(event) => event.stopPropagation()}
          >
            <div className="modal-header">
              <div>
                <h3>
                  {peajeEditandoId ? "Editar peaje" : "Registrar nuevo peaje"}
                </h3>
                <p>
                  Define los datos generales, la vía concesionada y las tarifas
                  por categoría.
                </p>
              </div>

              <button
                type="button"
                className="modal-close"
                onClick={cerrarFormulario}
              >
                ×
              </button>
            </div>

            <form onSubmit={handleSubmitPeaje} className="peaje-form modal-form">
              <div className="form-group">
                <label>Nombre</label>
                <input
                  type="text"
                  name="nombre"
                  value={formulario.nombre}
                  onChange={handleChange}
                  placeholder="Ej: Peaje Milagro"
                  required
                />
              </div>

              <div className="form-group">
                <label>Ciudad</label>
                <input
                  type="text"
                  name="ciudad"
                  value={formulario.ciudad}
                  onChange={handleChange}
                  placeholder="Ej: Milagro"
                  required
                />
              </div>

              <div className="form-group full">
                <label>Ubicación</label>
                <input
                  type="text"
                  name="ubicacion"
                  value={formulario.ubicacion}
                  onChange={handleChange}
                  placeholder="Ej: Vía Milagro - Guayaquil"
                  required
                />
              </div>

              <div className="form-group">
                <label>Latitud</label>
                <input
                  type="text"
                  name="latitud"
                  value={formulario.latitud}
                  onChange={handleChange}
                  placeholder="-2.1345000"
                  required
                />
              </div>

              <div className="form-group">
                <label>Longitud</label>
                <input
                  type="text"
                  name="longitud"
                  value={formulario.longitud}
                  onChange={handleChange}
                  placeholder="-79.5948000"
                  required
                />
              </div>

              <div className="form-group">
                <label>Estado</label>
                <select
                  name="estado"
                  value={formulario.estado}
                  onChange={handleChange}
                >
                  <option value="activo">Activo</option>
                  <option value="inactivo">Inactivo</option>
                  <option value="mantenimiento">Mantenimiento</option>
                </select>
              </div>

              <div className="form-group">
                <label>Vía concesionada</label>
                <select
                  name="via_concesionada"
                  value={formulario.via_concesionada}
                  onChange={handleChange}
                >
                  <option value="">Sin vía concesionada</option>
                  {viasConcesionadas
                    .filter((via) => via.estado !== false)
                    .map((via) => (
                      <option key={via.id} value={via.id}>
                        {via.nombre} ({via.codigo})
                      </option>
                    ))}
                </select>
              </div>

              <div className="form-group">
                <label>Orden en la vía</label>
                <input
                  type="number"
                  name="orden_en_via"
                  min="0"
                  value={formulario.orden_en_via}
                  onChange={handleChange}
                  placeholder="Ej: 1"
                />
              </div>

              <div className="tarifas-section">
                <div className="tarifas-header">
                  <div>
                    <h4>Tarifas por categoría</h4>
                    <p>
                      Estos valores se usarán para descontar el pago cuando el
                      vehículo pase por este peaje.
                    </p>
                  </div>
                </div>

                {categorias.length === 0 ? (
                  <div className="tarifa-vacia-detalle">
                    No existen categorías activas para configurar.
                  </div>
                ) : (
                  <div className="tarifas-grid">
                    {categorias.map((categoria) => (
                      <div key={categoria.id} className="tarifa-item">
                        <div className="tarifa-info">
                          <strong>{categoria.nombre}</strong>
                          <span>
                            {categoria.tipo} · {categoria.numero_ejes} ejes
                          </span>
                        </div>

                        <div className="tarifa-input">
                          <span>$</span>
                          <input
                            type="number"
                            min="0.01"
                            step="0.01"
                            value={tarifasCategoria[categoria.id] || ""}
                            onChange={(e) =>
                              handleTarifaChange(categoria.id, e.target.value)
                            }
                            placeholder="0.00"
                            required
                          />
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>

              <div className="form-buttons">
                <button
                  type="button"
                  className="btn-secondary"
                  onClick={cerrarFormulario}
                  disabled={guardando}
                >
                  Cancelar
                </button>

                <button
                  type="submit"
                  className="btn-primary"
                  disabled={guardando}
                >
                  {guardando
                    ? "Guardando..."
                    : peajeEditandoId
                      ? "Guardar cambios"
                      : "Guardar peaje"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {mostrarVias && (
        <div className="modal-overlay" onClick={cerrarGestorVias}>
          <div
            className="modal-card vias-modal"
            onClick={(event) => event.stopPropagation()}
          >
            <div className="modal-header">
              <div>
                <h3>Vías concesionadas</h3>
                <p>
                  Crea las vías y luego asígnalas a los peajes correspondientes.
                </p>
              </div>

              <button
                type="button"
                className="modal-close"
                onClick={cerrarGestorVias}
              >
                ×
              </button>
            </div>

            <form onSubmit={handleSubmitVia} className="peaje-form vias-form">
              <div className="form-group">
                <label>Nombre</label>
                <input
                  type="text"
                  name="nombre"
                  value={formularioVia.nombre}
                  onChange={handleViaChange}
                  placeholder="Ej: Guayaquil - Salinas"
                  required
                />
              </div>

              <div className="form-group">
                <label>Código</label>
                <input
                  type="text"
                  name="codigo"
                  value={formularioVia.codigo}
                  onChange={handleViaChange}
                  placeholder="Ej: GYE-SAL"
                  required
                />
              </div>

              <div className="form-group full">
                <label>Descripción</label>
                <textarea
                  name="descripcion"
                  value={formularioVia.descripcion}
                  onChange={handleViaChange}
                  placeholder="Descripción opcional de la vía concesionada"
                />
              </div>

              <div className="form-group">
                <label>Tiempo de validez en minutos</label>
                <input
                  type="number"
                  min="1"
                  name="tiempo_validez_minutos"
                  value={formularioVia.tiempo_validez_minutos}
                  onChange={handleViaChange}
                  required
                />
              </div>

              <div className="form-group check-group">
                <label className="check-option">
                  <input
                    type="checkbox"
                    name="cobro_unico_por_trayecto"
                    checked={formularioVia.cobro_unico_por_trayecto}
                    onChange={handleViaChange}
                  />
                  Cobro único por trayecto
                </label>

                <label className="check-option">
                  <input
                    type="checkbox"
                    name="estado"
                    checked={formularioVia.estado}
                    onChange={handleViaChange}
                  />
                  Vía activa
                </label>
              </div>

              <div className="form-buttons">
                <button
                  type="button"
                  className="btn-secondary"
                  onClick={limpiarFormularioVia}
                  disabled={guardandoVia}
                >
                  Limpiar
                </button>

                <button
                  type="submit"
                  className="btn-primary"
                  disabled={guardandoVia}
                >
                  {guardandoVia
                    ? "Guardando..."
                    : viaEditandoId
                      ? "Actualizar vía"
                      : "Crear vía"}
                </button>
              </div>
            </form>

            <div className="vias-list">
              {viasConcesionadas.length > 0 ? (
                viasConcesionadas.map((via) => (
                  <div className="via-item" key={via.id}>
                    <div>
                      <strong>{via.nombre}</strong>
                      <span>
                        Código: {via.codigo} · Validez:{" "}
                        {via.tiempo_validez_minutos} minutos ·{" "}
                        {via.cobro_unico_por_trayecto
                          ? "Cobro único activo"
                          : "Cobro único inactivo"}
                      </span>
                      {via.descripcion && <p>{via.descripcion}</p>}
                    </div>

                    <div className="via-actions">
                      <span className={via.estado ? "via-status active" : "via-status inactive"}>
                        {via.estado ? "Activa" : "Inactiva"}
                      </span>

                      <button
                        type="button"
                        className="btn-editar-peaje"
                        onClick={() => editarVia(via)}
                      >
                        Editar
                      </button>
                    </div>
                  </div>
                ))
              ) : (
                <div className="via-empty-card">
                  No existen vías concesionadas registradas.
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      {mostrarDetalle && peajeSeleccionado && (
        <div className="modal-overlay" onClick={cerrarDetalles}>
          <div
            className="modal-card detalle-modal"
            onClick={(event) => event.stopPropagation()}
          >
            <div className="modal-header">
              <div>
                <h3>{peajeSeleccionado.nombre}</h3>
                <p>Detalle completo del peaje y sus tarifas configuradas.</p>
              </div>

              <button
                type="button"
                className="modal-close"
                onClick={cerrarDetalles}
              >
                ×
              </button>
            </div>

            <div className="detalle-grid">
              <div className="detalle-item">
                <span>Ciudad</span>
                <strong>{peajeSeleccionado.ciudad || "Sin dato"}</strong>
              </div>

              <div className="detalle-item">
                <span>Estado</span>
                <strong className={`estado ${peajeSeleccionado.estado}`}>
                  {peajeSeleccionado.estado}
                </strong>
              </div>

              <div className="detalle-item detalle-full">
                <span>Ubicación</span>
                <strong>{peajeSeleccionado.ubicacion || "Sin dato"}</strong>
              </div>

              <div className="detalle-item">
                <span>Latitud</span>
                <strong>{peajeSeleccionado.latitud || "Sin dato"}</strong>
              </div>

              <div className="detalle-item">
                <span>Longitud</span>
                <strong>{peajeSeleccionado.longitud || "Sin dato"}</strong>
              </div>

              <div className="detalle-item detalle-full">
                <span>Vía concesionada</span>
                <strong>
                  {peajeSeleccionado.via_concesionada_nombre
                    ? `${peajeSeleccionado.via_concesionada_nombre} (${peajeSeleccionado.via_concesionada_codigo})`
                    : "Sin vía concesionada"}
                </strong>
              </div>

              <div className="detalle-item">
                <span>Orden en vía</span>
                <strong>{peajeSeleccionado.orden_en_via ?? 0}</strong>
              </div>
            </div>

            <div className="detalle-tarifas">
              <h4>Tarifas por categoría</h4>
              {renderTarifasDetalle(peajeSeleccionado)}
            </div>

            <div className="detalle-actions">
              <button
                type="button"
                className="btn-secondary"
                onClick={() => {
                  cerrarDetalles();
                  editarPeaje(peajeSeleccionado);
                }}
              >
                Editar peaje
              </button>

              <button
                type="button"
                className="btn-primary"
                onClick={cerrarDetalles}
              >
                Cerrar
              </button>
            </div>
          </div>
        </div>
      )}

      <div className="peajes-table-card">
        <table>
          <thead>
            <tr>
              <th>Nombre</th>
              <th>Ciudad</th>
              <th>Ubicación</th>
              <th>Vía concesionada</th>
              <th>Estado</th>
              <th>Coordenadas</th>
              <th>Acciones</th>
            </tr>
          </thead>

          <tbody>
            {!cargando && peajes.length > 0 ? (
              peajes.map((peaje) => (
                <tr key={peaje.id}>
                  <td>{peaje.nombre}</td>
                  <td>{peaje.ciudad}</td>
                  <td>{peaje.ubicacion}</td>
                  <td>{renderViaTabla(peaje)}</td>
                  <td>
                    <span className={`estado ${peaje.estado}`}>
                      {peaje.estado}
                    </span>
                  </td>
                  <td>
                    {peaje.latitud}, {peaje.longitud}
                  </td>
                  <td>
                    <div className="acciones-peaje">
                      <button
                        type="button"
                        className="btn-ver-detalle"
                        onClick={() => abrirDetalles(peaje)}
                      >
                        Ver detalles
                      </button>

                      <button
                        type="button"
                        className="btn-editar-peaje"
                        onClick={() => editarPeaje(peaje)}
                      >
                        Editar
                      </button>
                    </div>
                  </td>
                </tr>
              ))
            ) : !cargando ? (
              <tr>
                <td colSpan="7">No existen peajes registrados.</td>
              </tr>
            ) : null}
          </tbody>
        </table>
      </div>
    </div>
  );
}

export default Peajes;