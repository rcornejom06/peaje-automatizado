import api from "./axios";

export const obtenerVehiculos = async () => {
  const response = await api.get("/vehiculos/vehiculos/");
  return response.data;
};

export const aprobarVehiculo = async (vehiculoId, motivoRevision) => {
  const response = await api.patch(
    `/vehiculos/vehiculos/${vehiculoId}/aprobar/`,
    {
      motivo_revision:
        motivoRevision || "Documento de respaldo validado correctamente.",
    }
  );

  return response.data;
};

export const rechazarVehiculo = async (vehiculoId, motivoRevision) => {
  const response = await api.patch(
    `/vehiculos/vehiculos/${vehiculoId}/rechazar/`,
    {
      motivo_revision:
        motivoRevision || "Documento de respaldo no validado.",
    }
  );

  return response.data;
};

export const cambiarEstadoRevisionVehiculo = async ({
  vehiculoId,
  estadoRevision,
  motivoRevision,
}) => {
  const response = await api.patch(
    `/vehiculos/vehiculos/${vehiculoId}/cambiar-estado-revision/`,
    {
      estado_revision: estadoRevision,
      motivo_revision: motivoRevision,
    }
  );

  return response.data;
};

export const obtenerDocumentoBlob = async (url) => {
  const response = await api.get(url, {
    responseType: "blob",
    baseURL: "",
  });

  return response.data;
};