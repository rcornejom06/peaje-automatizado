import api from "./axios";

export const obtenerAlertas = async () => {
    const response = await api.get("/seguridad/alertas/");
    return response.data;
};

export const marcarAlertaRevisada = async (id) => {
    const response = await api.patch(`/seguridad/alertas/${id}/marcar-revisada/`);
    return response.data;
};

export const derivarAlertaAutoridad = async (id) => {
    const response = await api.patch(`/seguridad/alertas/${id}/derivar-autoridad/`);
    return response.data;
};

export const cerrarAlerta = async (id) => {
    const response = await api.patch(`/seguridad/alertas/${id}/cerrar/`);
    return response.data;
};

export const descartarAlerta = async (id) => {
    const response = await api.patch(`/seguridad/alertas/${id}/descartar/`);
    return response.data;
};
export const obtenerSolicitudesReactivacion = async () => {
    const response = await api.get("/seguridad/reactivaciones-vehiculo/");
    return response.data;
};

export const aprobarSolicitudReactivacion = async (id, respuestaAdmin = "") => {
    const response = await api.patch(
        `/seguridad/reactivaciones-vehiculo/${id}/aprobar/`,
        {
            respuesta_admin:
                respuestaAdmin ||
                "Solicitud aprobada. Vehículo recuperado y reactivado.",
        }
    );

    return response.data;
};

export const rechazarSolicitudReactivacion = async (id, respuestaAdmin) => {
    const response = await api.patch(
        `/seguridad/reactivaciones-vehiculo/${id}/rechazar/`,
        {
            respuesta_admin: respuestaAdmin,
        }
    );

    return response.data;
};