import api from "./axios";

export const obtenerPlanesMembresia = async () => {
  const response = await api.get("/membresias/planes/");
  return response.data;
};

export const crearPlanMembresia = async (data) => {
  const response = await api.post("/membresias/planes/", data);
  return response.data;
};

export const actualizarPlanMembresia = async (id, data) => {
  const response = await api.patch(`/membresias/planes/${id}/`, data);
  return response.data;
};

export const eliminarPlanMembresia = async (id) => {
  const response = await api.delete(`/membresias/planes/${id}/`);
  return response.data;
};

export const obtenerMembresias = async () => {
  const response = await api.get("/membresias/");
  return response.data;
};
