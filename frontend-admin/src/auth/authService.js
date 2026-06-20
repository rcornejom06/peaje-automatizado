import api from "../api/axios";

export const login = async (username, password) => {
  const response = await api.post("/auth/token/", {
    username,
    password,
  });

  const { access, refresh } = response.data;

  localStorage.setItem("access_token", access);
  localStorage.setItem("refresh_token", refresh);

  return response.data;
};

export const logout = () => {
  localStorage.removeItem("access_token");
  localStorage.removeItem("refresh_token");
};

export const isAuthenticated = () => {
  return Boolean(localStorage.getItem("access_token"));
};