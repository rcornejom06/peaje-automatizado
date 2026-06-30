import { useState } from "react";
import {
  aprobarVehiculo,
  buscarVehiculoRevision,
  rechazarVehiculo,
} from "../../api/vehiculosService.js";

const estadoTexto = {
  en_revision: "En revisión",
  aprobado: "Aprobado",
  rechazado: "Rechazado",
};

const estadoClase = {
  en_revision: "bg-yellow-100 text-yellow-800 border-yellow-300",
  aprobado: "bg-green-100 text-green-800 border-green-300",
  rechazado: "bg-red-100 text-red-800 border-red-300",
};

export default function RevisionVehiculos() {
  const [placa, setPlaca] = useState("");
  const [vehiculo, setVehiculo] = useState(null);
  const [motivo, setMotivo] = useState("");
  const [cargando, setCargando] = useState(false);
  const [mensaje, setMensaje] = useState("");
  const [error, setError] = useState("");

  const limpiarMensajes = () => {
    setMensaje("");
    setError("");
  };

  const buscar = async (e) => {
    e.preventDefault();
    limpiarMensajes();

    const placaLimpia = placa.trim().toUpperCase();

    if (!placaLimpia) {
      setError("Ingrese una placa para buscar.");
      return;
    }

    try {
      setCargando(true);
      const data = await buscarVehiculoRevision(placaLimpia);
      setVehiculo(data);
      setMotivo("");
    } catch (err) {
      setVehiculo(null);
      setError(
        err.response?.data?.error ||
          err.response?.data?.detail ||
          "No se pudo buscar el vehículo."
      );
    } finally {
      setCargando(false);
    }
  };

  const aprobar = async () => {
    if (!vehiculo?.id) return;

    const confirmar = window.confirm(
      `¿Desea aprobar el vehículo con placa ${vehiculo.placa}?`
    );

    if (!confirmar) return;

    limpiarMensajes();

    try {
      setCargando(true);
      const data = await aprobarVehiculo(vehiculo.id, motivo);
      setVehiculo(data.vehiculo);
      setMensaje(data.mensaje || "Vehículo aprobado correctamente.");
      setMotivo("");
    } catch (err) {
      setError(
        err.response?.data?.error ||
          err.response?.data?.detail ||
          "No se pudo aprobar el vehículo."
      );
    } finally {
      setCargando(false);
    }
  };

  const rechazar = async () => {
    if (!vehiculo?.id) return;

    if (!motivo.trim()) {
      setError("Debe ingresar un motivo para rechazar el vehículo.");
      return;
    }

    const confirmar = window.confirm(
      `¿Desea rechazar el vehículo con placa ${vehiculo.placa}?`
    );

    if (!confirmar) return;

    limpiarMensajes();

    try {
      setCargando(true);
      const data = await rechazarVehiculo(vehiculo.id, motivo);
      setVehiculo(data.vehiculo);
      setMensaje(data.mensaje || "Vehículo rechazado correctamente.");
      setMotivo("");
    } catch (err) {
      setError(
        err.response?.data?.error ||
          err.response?.data?.detail ||
          "No se pudo rechazar el vehículo."
      );
    } finally {
      setCargando(false);
    }
  };

  const usuarioDetalle = vehiculo?.usuario_detalle || {};
  const categoriaDetalle =
    vehiculo?.categoria_detalle || vehiculo?.categoria_info || {};

  const documentoUrl =
    vehiculo?.documento_respaldo_url || vehiculo?.documento_respaldo || null;

  return (
    <div className="p-6 space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-800">
          Revisión de vehículos
        </h1>
        <p className="text-gray-500">
          Busque un vehículo por placa, revise el documento de respaldo y
          apruebe o rechace la solicitud.
        </p>
      </div>

      <form
        onSubmit={buscar}
        className="bg-white rounded-xl shadow-sm border p-5 flex flex-col md:flex-row gap-3"
      >
        <input
          type="text"
          value={placa}
          onChange={(e) => setPlaca(e.target.value.toUpperCase())}
          placeholder="Ejemplo: AAC0123"
          className="flex-1 border rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
        />

        <button
          type="submit"
          disabled={cargando}
          className="bg-blue-600 hover:bg-blue-700 text-white px-5 py-2 rounded-lg disabled:opacity-60"
        >
          {cargando ? "Buscando..." : "Buscar placa"}
        </button>
      </form>

      {mensaje && (
        <div className="bg-green-50 border border-green-300 text-green-700 px-4 py-3 rounded-lg">
          {mensaje}
        </div>
      )}

      {error && (
        <div className="bg-red-50 border border-red-300 text-red-700 px-4 py-3 rounded-lg">
          {error}
        </div>
      )}

      {vehiculo && (
        <div className="bg-white rounded-xl shadow-sm border p-6 space-y-6">
          <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-3">
            <div>
              <h2 className="text-xl font-bold text-gray-800">
                {vehiculo.placa}
              </h2>
              <p className="text-gray-500">
                {vehiculo.marca} {vehiculo.modelo}
              </p>
            </div>

            <span
              className={`inline-flex px-3 py-1 rounded-full border text-sm font-semibold ${
                estadoClase[vehiculo.estado_revision] ||
                "bg-gray-100 text-gray-700 border-gray-300"
              }`}
            >
              {estadoTexto[vehiculo.estado_revision] || "En revisión"}
            </span>
          </div>

          <div className="grid md:grid-cols-2 gap-5">
            <div className="border rounded-lg p-4">
              <h3 className="font-semibold text-gray-700 mb-3">
                Datos del vehículo
              </h3>

              <div className="space-y-2 text-sm">
                <p>
                  <strong>Placa:</strong> {vehiculo.placa}
                </p>
                <p>
                  <strong>Marca:</strong> {vehiculo.marca || "Sin dato"}
                </p>
                <p>
                  <strong>Modelo:</strong> {vehiculo.modelo || "Sin dato"}
                </p>
                <p>
                  <strong>Color:</strong> {vehiculo.color || "Sin dato"}
                </p>
                <p>
                  <strong>Año:</strong> {vehiculo.anio || "Sin dato"}
                </p>
                <p>
                  <strong>Categoría:</strong>{" "}
                  {vehiculo.categoria_nombre ||
                    categoriaDetalle.nombre ||
                    vehiculo.categoria ||
                    "Sin dato"}
                </p>
              </div>
            </div>

            <div className="border rounded-lg p-4">
              <h3 className="font-semibold text-gray-700 mb-3">
                Datos del usuario registrado
              </h3>

              <div className="space-y-2 text-sm">
                <p>
                  <strong>Usuario:</strong>{" "}
                  {usuarioDetalle.username ||
                    vehiculo.usuario_username ||
                    "Sin dato"}
                </p>
                <p>
                  <strong>Nombres:</strong>{" "}
                  {usuarioDetalle.first_name || "Sin dato"}
                </p>
                <p>
                  <strong>Apellidos:</strong>{" "}
                  {usuarioDetalle.last_name || "Sin dato"}
                </p>
                <p>
                  <strong>Correo:</strong> {usuarioDetalle.email || "Sin dato"}
                </p>
                <p>
                  <strong>ID usuario:</strong>{" "}
                  {typeof vehiculo.usuario === "number"
                    ? vehiculo.usuario
                    : usuarioDetalle.id || "Sin dato"}
                </p>
              </div>
            </div>
          </div>

          <div className="border rounded-lg p-4 bg-blue-50">
            <h3 className="font-semibold text-gray-700 mb-2">
              Documento de respaldo
            </h3>

            {documentoUrl ? (
              <div className="space-y-3">
                <p className="text-sm text-gray-600">
                  Revise el documento adjuntado por el usuario antes de aprobar
                  o rechazar el vehículo.
                </p>

                <a
                  href={documentoUrl}
                  target="_blank"
                  rel="noreferrer"
                  className="inline-flex bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg"
                >
                  Ver documento
                </a>
              </div>
            ) : (
              <p className="text-sm text-red-600 font-semibold">
                Este vehículo no tiene documento de respaldo adjunto.
              </p>
            )}
          </div>

          {vehiculo.motivo_revision && (
            <div className="bg-gray-50 border rounded-lg p-4">
              <h3 className="font-semibold text-gray-700 mb-2">
                Último motivo de revisión
              </h3>
              <p className="text-sm text-gray-600">
                {vehiculo.motivo_revision}
              </p>
            </div>
          )}

          <div>
            <label className="block text-sm font-semibold text-gray-700 mb-2">
              Motivo / observación administrativa
            </label>
            <textarea
              value={motivo}
              onChange={(e) => setMotivo(e.target.value)}
              rows={4}
              placeholder="Ejemplo: Documento de matrícula validado correctamente."
              className="w-full border rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          <div className="flex flex-col md:flex-row gap-3">
            <button
              onClick={aprobar}
              disabled={cargando || !documentoUrl}
              className="bg-green-600 hover:bg-green-700 text-white px-5 py-2 rounded-lg disabled:opacity-60"
            >
              Aprobar vehículo
            </button>

            <button
              onClick={rechazar}
              disabled={cargando}
              className="bg-red-600 hover:bg-red-700 text-white px-5 py-2 rounded-lg disabled:opacity-60"
            >
              Rechazar vehículo
            </button>
          </div>
        </div>
      )}
    </div>
  );
}