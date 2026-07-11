import api from "./axios";

export const obtenerComprobantePaso = async (pasoId) => {
  const response = await api.get(`/peajes/pasos-peaje/${pasoId}/comprobante/`);
  return response.data;
};