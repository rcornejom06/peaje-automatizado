import api from "./axios";

export const solicitarResetPassword = async (email) => {
  const response = await api.post(
    "/usuarios/solicitar-reset-password/",
    {
      email,
    }
  );

  return response.data;
};

export const confirmarResetPassword = async ({
  email,
  codigo,
  nuevaPassword,
}) => {
  const response = await api.post(
    "/usuarios/confirmar-reset-password/",
    {
      email,
      codigo,
      nueva_password: nuevaPassword,
    }
  );

  return response.data;
};