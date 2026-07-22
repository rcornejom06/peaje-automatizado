import api from "./axios";

export const obtenerNotificaciones = async () => {
  const response = await api.get("/notificaciones/");
  return response.data;
};

export const obtenerNotificacionesNoLeidas = async () => {
  const response = await api.get("/notificaciones/no-leidas/");
  return response.data;
};

export const marcarNotificacionLeida = async (id) => {
  const response = await api.patch(
    `/notificaciones/${id}/marcar-leida/`,
    {}
  );
  return response.data;
};

export const marcarTodasNotificacionesLeidas = async () => {
  const response = await api.patch(
    "/notificaciones/marcar-todas-leidas/",
    {}
  );
  return response.data;
};