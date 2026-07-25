import axios from "axios";

const baseURL = import.meta.env.VITE_API_URL || "http://localhost:8000/api";

const api = axios.create({
  baseURL,
  timeout: 15000,
});

let refreshPromise = null;

const rutasSinToken = [
  "/auth/token/",
  "/auth/token/refresh/",
  "/usuarios/verificar-correo/",
  "/usuarios/verificar-correo-operador/",
  "/usuarios/reenviar-codigo/",
  "/usuarios/solicitar-reset-password/",
  "/usuarios/confirmar-reset-password/",
];

const esRutaSinToken = (url = "") => {
  return rutasSinToken.some((ruta) => url.includes(ruta));
};

const obtenerAccessToken = () => {
  return (
    localStorage.getItem("access_token") ||
    localStorage.getItem("access") ||
    localStorage.getItem("token")
  );
};

const obtenerRefreshToken = () => {
  return (
    localStorage.getItem("refresh_token") ||
    localStorage.getItem("refresh")
  );
};

const limpiarSesion = () => {
  localStorage.removeItem("access_token");
  localStorage.removeItem("refresh_token");
  localStorage.removeItem("access");
  localStorage.removeItem("refresh");
  localStorage.removeItem("token");
  localStorage.removeItem("admin_profile");
};

api.interceptors.request.use(
  (config) => {
    const url = config.url || "";

    if (esRutaSinToken(url)) {
      delete config.headers.Authorization;
      return config;
    }

    const token = obtenerAccessToken();

    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }

    return config;
  },
  (error) => Promise.reject(error)
);

api.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config;
    const status = error.response?.status;
    const url = originalRequest?.url || "";

    if (
      status !== 401 ||
      !originalRequest ||
      originalRequest._retry ||
      esRutaSinToken(url)
    ) {
      return Promise.reject(error);
    }

    const refreshToken = obtenerRefreshToken();

    if (!refreshToken) {
      limpiarSesion();

      if (window.location.pathname !== "/") {
        window.location.replace("/");
      }

      return Promise.reject(error);
    }

    originalRequest._retry = true;

    try {
      if (!refreshPromise) {
        refreshPromise = axios.post(`${baseURL}/auth/token/refresh/`, {
          refresh: refreshToken,
        });
      }

      const response = await refreshPromise;
      const nuevoAccess = response.data?.access;

      if (!nuevoAccess) {
        throw new Error("No se recibió un nuevo token de acceso.");
      }

      localStorage.setItem("access_token", nuevoAccess);
      localStorage.setItem("access", nuevoAccess);

      originalRequest.headers.Authorization = `Bearer ${nuevoAccess}`;

      return api(originalRequest);
    } catch (refreshError) {
      limpiarSesion();

      if (window.location.pathname !== "/") {
        window.location.replace("/");
      }

      return Promise.reject(refreshError);
    } finally {
      refreshPromise = null;
    }
  }
);

export default api;