import api from "./axios";

export const obtenerUsuarios = async () => {
  const response = await api.get("/usuarios/usuarios/");
  return response.data;
};

export const obtenerPerfiles = async () => {
  const response = await api.get("/usuarios/perfiles/");
  return response.data;
};