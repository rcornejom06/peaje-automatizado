import api from "./axios";

export const obtenerCamaras = async () => {
  const response = await api.get("/peajes/camaras/");
  return response.data;
};

export const crearCamara = async (data) => {
  const response = await api.post("/peajes/camaras/", data);
  return response.data;
};