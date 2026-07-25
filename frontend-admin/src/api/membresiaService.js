import api from "./axios";

export const obtenerPlanesMembresia = async () => {
  const response = await api.get("/membresias/planes/");
  return response.data;
};

export const crearPlanMembresia = async (data) => {
  const response = await api.post("/membresias/planes/", data);
  return response.data;
};

export const obtenerMembresias = async () => {
  const response = await api.get("/membresias/");
  return response.data;
};