import api from "./axios";

export const obtenerUsuarios = async () => {
    const response = await api.get("/usuarios/");
    return response.data;
};

export const obtenerPerfiles = async () => {
    const response = await api.get("/usuarios/perfiles/");
    return response.data;
};
export const crearOperador = async (datos) => {
    const response = await api.post("/usuarios/perfiles/crear-operador/", datos);
    return response.data;
};

export const obtenerMiPerfil = async () => {
    const response = await api.get("/usuarios/perfiles/mi-perfil/");
    return response.data;
};

export const actualizarMiPerfil = async (datos) => {
    const response = await api.patch(
        "/usuarios/perfiles/actualizar-mi-perfil/",
        datos
    );

    return response.data;
};