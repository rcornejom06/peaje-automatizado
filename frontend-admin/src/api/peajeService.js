import api from "./axios";

export const obtenerPeajes = async () => {
    const response = await api.get("/peajes/");
    return response.data;
};

export const crearPeaje = async (data) => {
    const response = await api.post("/peajes/", data);
    return response.data;
};

export const actualizarPeaje = async (id, data) => {
    const response = await api.patch(`/peajes/${id}/`, data);
    return response.data;
};

export const obtenerCategoriasVehiculo = async () => {
    const response = await api.get("/vehiculos/categorias/");
    return response.data;
};

export const obtenerViasConcesionadas = async () => {
    const response = await api.get("/peajes/vias-concesionadas/");
    return response.data;
};

export const crearViaConcesionada = async (data) => {
    const response = await api.post("/peajes/vias-concesionadas/", data);
    return response.data;
};

export const actualizarViaConcesionada = async (id, data) => {
    const response = await api.patch(`/peajes/vias-concesionadas/${id}/`, data);
    return response.data;
};