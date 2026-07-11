import api from "./axios";

export const obtenerPeajes = async () => {
  const response = await api.get("/peajes/peajes/");
  return response.data;
};

export const crearPeaje = async (data) => {
  const response = await api.post("/peajes/peajes/", data);
  return response.data;
};