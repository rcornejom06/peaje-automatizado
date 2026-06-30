import api from "./axios";

export const obtenerVehiculos = async () => {
  const response = await api.get("/vehiculos/vehiculos/");
  return response.data;
};

export const buscarVehiculoRevision = async (placa) => {
  const response = await api.get("/vehiculos/vehiculos/buscar-revision/", {
    params: { placa },
  });

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
      motivo_revision: motivoRevision,
    }
  );

  return response.data;
};