import api from "./axios";

const construirParametros = (filtros = {}) => {
  const params = {};

  if (filtros.fecha_inicio) {
    params.fecha_inicio = filtros.fecha_inicio;
  }

  if (filtros.fecha_fin) {
    params.fecha_fin = filtros.fecha_fin;
  }

  if (filtros.peaje) {
    params.peaje = filtros.peaje;
  }

  return params;
};

export const obtenerResumen = async (filtros = {}) => {
  const response = await api.get("/reportes/resumen/", {
    params: construirParametros(filtros),
  });
  return response.data;
};

export const obtenerRecaudacion = async (filtros = {}) => {
  const response = await api.get("/reportes/recaudacion/", {
    params: construirParametros(filtros),
  });
  return response.data;
};

export const obtenerAlertasReporte = async (filtros = {}) => {
  const response = await api.get("/reportes/alertas/", {
    params: construirParametros(filtros),
  });
  return response.data;
};

export const obtenerAlertas = obtenerAlertasReporte;

export const obtenerPasosPorPeaje = async (filtros = {}) => {
  const response = await api.get("/reportes/pasos-por-peaje/", {
    params: construirParametros(filtros),
  });
  return response.data;
};

export const obtenerVehiculosDetectados = async (filtros = {}) => {
  const response = await api.get("/reportes/vehiculos-detectados/", {
    params: construirParametros(filtros),
  });
  return response.data;
};

export const obtenerUsoMembresias = async (filtros = {}) => {
  const response = await api.get("/reportes/uso-membresias/", {
    params: construirParametros(filtros),
  });
  return response.data;
};