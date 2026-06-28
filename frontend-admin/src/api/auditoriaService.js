import api from "./axios";

const construirParametros = (filtros = {}) => {
  const params = {};

  if (filtros.fecha_inicio) {
    params.fecha_inicio = filtros.fecha_inicio;
  }

  if (filtros.fecha_fin) {
    params.fecha_fin = filtros.fecha_fin;
  }

  if (filtros.modulo) {
    params.modulo = filtros.modulo;
  }

  if (filtros.estado) {
    params.estado = filtros.estado;
  }

  if (filtros.accion) {
    params.accion = filtros.accion;
  }

  return params;
};

export const obtenerHistorialAuditoria = async (filtros = {}) => {
  const response = await api.get("/auditoria/historial/", {
    params: construirParametros(filtros),
  });

  return response.data;
};

export const obtenerResumenAuditoria = async () => {
  const response = await api.get("/auditoria/historial/resumen/");
  return response.data;
};