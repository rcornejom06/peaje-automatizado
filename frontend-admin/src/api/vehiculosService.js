import api from "./axios";

export const obtenerVehiculos = async () => {
  const response = await api.get("/vehiculos/vehiculos/");
  return response.data;
};

export const obtenerCategoriasVehiculo = async () => {
  const response = await api.get("/vehiculos/categorias/");
  return response.data;
};