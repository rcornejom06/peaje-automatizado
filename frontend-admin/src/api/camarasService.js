import api from "./axios";

export const obtenerCamaras = async () => {
  const response = await api.get("/peajes/camaras/");
  return response.data;
};

export const crearCamara = async (data) => {
  const response = await api.post("/peajes/camaras/", data);
  return response.data;
};

export const editarCamara = async (id, data) => {
  const response = await api.patch(`/peajes/camaras/${id}/`, data);
  return response.data;
};

export const cambiarEstadoCamara = async (id, estado) => {
  const response = await api.patch(`/peajes/camaras/${id}/cambiar-estado/`, {
    estado,
  });
  return response.data;
};
