import api from "../api/axios";

const ROLES_PANEL_ADMIN = ["administrador", "operador"];

const obtenerRol = (perfil) => {
    return perfil?.rol || perfil?.perfil?.rol || perfil?.usuario?.perfil?.rol || "";
};

export const obtenerPerfilActual = async () => {
    const response = await api.get("/usuarios/perfiles/mi-perfil/");
    return response.data;
};

export const login = async (username, password) => {
    try {
        const response = await api.post("/auth/token/", {
            username: username.trim(),
            password,
        });

        const {access, refresh} = response.data;

        localStorage.setItem("access_token", access);
        localStorage.setItem("refresh_token", refresh);
        localStorage.setItem("access", access);
        localStorage.setItem("refresh", refresh);

        const perfil = await obtenerPerfilActual();
        const rol = obtenerRol(perfil);

        if (!ROLES_PANEL_ADMIN.includes(rol)) {
            logout();
            throw new Error("No tienes permisos para acceder al panel administrativo.");
        }

        localStorage.setItem("admin_profile", JSON.stringify(perfil));
        if (response.data.requiere_cambio_password) {
            localStorage.setItem("requiere_cambio_password", "true");
        } else {
            localStorage.removeItem("requiere_cambio_password");
        }

        return {
            ...response.data,
            perfil,
            rol,
        };
    } catch (error) {
        const data = error.response?.data || {};
        const detail = data.detail;

        let codigoError = data.code || "";
        let emailError = data.email || "";
        let mensajeError =
            data.message ||
            data.mensaje ||
            data.error ||
            "Usuario o contraseña incorrectos.";

        if (typeof detail === "object" && detail !== null) {
            codigoError = detail.code || codigoError;
            emailError = detail.email || emailError;
            mensajeError = detail.message || mensajeError;
        }

        if (typeof detail === "string") {
            if (!mensajeError) {
                mensajeError = detail;
            }

            if (
                detail.toLowerCase().includes("correo") ||
                mensajeError.toLowerCase().includes("correo")
            ) {
                codigoError = "correo_no_verificado";
            }
        }

        logout();

        if (codigoError === "correo_no_verificado") {
            const customError = new Error(
                mensajeError || "Debe verificar su correo electrónico."
            );

            customError.code = "correo_no_verificado";
            customError.email = emailError;

            throw customError;
        }

        if (codigoError === "cuenta_inactiva") {
            throw new Error(
                mensajeError || "Su cuenta está inactiva. Contacte al administrador."
            );
        }

        throw new Error(mensajeError || error.message || "No se pudo iniciar sesión.");
    }
}

    export const logout = () => {
        localStorage.removeItem("access_token");
        localStorage.removeItem("refresh_token");
        localStorage.removeItem("access");
        localStorage.removeItem("refresh");
        localStorage.removeItem("token");
        localStorage.removeItem("admin_profile");
        localStorage.removeItem("requiere_cambio_password");
    };

    export const getStoredProfile = () => {
        try {
            const perfil = localStorage.getItem("admin_profile");
            return perfil ? JSON.parse(perfil) : null;
        } catch {
            return null;
        }
    };

    export const isAuthenticated = () => {
        return Boolean(localStorage.getItem("access_token"));
    };

    export const isAdminPanelUser = () => {
        const perfil = getStoredProfile();
        const rol = obtenerRol(perfil);

        return ROLES_PANEL_ADMIN.includes(rol);
    };

    export const verificarCorreo = async ({email, codigo}) => {
        const response = await api.post("/usuarios/verificar-correo-operador/", {
            email,
            codigo,
        });

        return response.data;
    };

    export const reenviarCodigoVerificacion = async (email) => {
        const response = await api.post("/usuarios/reenviar-codigo/", {
            email,
        });

        return response.data;
    };

    export const cambiarPasswordInicial = async ({
                                                     passwordActual,
                                                     nuevaPassword,
                                                     confirmarPassword,
                                                 }) => {
        const response = await api.post("/usuarios/perfiles/cambiar-password/", {
            password_actual: passwordActual,
            nueva_password: nuevaPassword,
            confirmar_password: confirmarPassword,
        });

        localStorage.removeItem("requiere_cambio_password");

        return response.data;
    };