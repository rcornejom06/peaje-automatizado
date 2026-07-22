import {useEffect, useMemo, useState} from "react";
import {useNavigate, useSearchParams} from "react-router-dom";
import {
    reenviarCodigoVerificacion,
    verificarCorreo,
} from "../../auth/authService.js";
import "../Styles/Login.css";

function VerificarCorreo() {
    const navigate = useNavigate();
    const [searchParams] = useSearchParams();

    const emailInicial = useMemo(() => {
        return searchParams.get("email") || "";
    }, [searchParams]);

    const [email, setEmail] = useState(emailInicial);
    const [codigo, setCodigo] = useState("");
    const [mensaje, setMensaje] = useState("");
    const [error, setError] = useState("");
    const [cargando, setCargando] = useState(false);

    const codigoInicial = useMemo(() => {
        return searchParams.get("codigo") || "";
    }, [searchParams]);

    useEffect(() => {
        const verificarDesdeEnlace = async () => {
            if (!emailInicial || !codigoInicial) {
                return;
            }

            setEmail(emailInicial);
            setCodigo(codigoInicial);
            setError("");
            setMensaje("");
            setCargando(true);

            try {
                const response = await verificarCorreo({
                    email: emailInicial.trim(),
                    codigo: codigoInicial.trim(),
                });

                setMensaje(
                    response.mensaje ||
                    "Correo verificado correctamente. Ahora puedes iniciar sesión."
                );

                setTimeout(() => {
                    navigate("/");
                }, 1500);
            } catch (error) {
                setError(
                    error.response?.data?.error ||
                    error.response?.data?.detail ||
                    error.message ||
                    "No se pudo verificar el correo."
                );
            } finally {
                setCargando(false);
            }
        };

        verificarDesdeEnlace();
    }, [emailInicial, codigoInicial, navigate]);

    const handleVerificar = async (e) => {
        e.preventDefault();

        setError("");
        setMensaje("");
        setCargando(true);

        try {
            const response = await verificarCorreo({
                email: email.trim(),
                codigo: codigo.trim(),
            });

            setMensaje(
                response.mensaje ||
                "Correo verificado correctamente. Ahora puedes iniciar sesión."
            );

            setTimeout(() => {
                navigate("/");
            }, 1200);
        } catch (error) {
            setError(
                error.response?.data?.error ||
                error.response?.data?.detail ||
                error.message ||
                "No se pudo verificar el correo."
            );
        } finally {
            setCargando(false);
        }
    };

    const handleReenviar = async () => {
        if (!email.trim()) {
            setError("Ingresa tu correo para reenviar el código.");
            return;
        }

        setError("");
        setMensaje("");
        setCargando(true);

        try {
            const response = await reenviarCodigoVerificacion(email.trim());

            setMensaje(
                response.codigo_debug
                    ? `Código generado: ${response.codigo_debug}`
                    : response.mensaje || "Código reenviado correctamente."
            );
        } catch (error) {
            setError(
                error.response?.data?.error ||
                error.response?.data?.detail ||
                error.message ||
                "No se pudo reenviar el código."
            );
        } finally {
            setCargando(false);
        }
    };

    return (
        <div className="login-page">
            <div className="login-wrapper">
                <div className="login-left">
                    <div className="login-left-content">
                        <span className="login-badge">Verificación</span>
                        <h1>Verifica tu correo electrónico</h1>
                        <p>
                            Ingresa el código de 6 dígitos enviado a tu correo para activar tu
                            cuenta administrativa.
                        </p>
                    </div>
                </div>

                <div className="login-right">
                    <div className="login-card">
                        <div className="login-brand">
                            <div className="login-logo">✉️</div>
                            <h2>Verificar correo</h2>
                            <p>Panel Administrativo</p>
                        </div>

                        <form onSubmit={handleVerificar} className="login-form">
                            <div className="form-group">
                                <label htmlFor="email">Correo electrónico</label>
                                <div className="input-with-icon">
                                    <input
                                        id="email"
                                        type="email"
                                        value={email}
                                        onChange={(e) => setEmail(e.target.value)}
                                        placeholder="correo@ejemplo.com"
                                        required
                                    />
                                </div>
                            </div>

                            <div className="form-group">
                                <label htmlFor="codigo">Código de verificación</label>
                                <div className="input-with-icon">
                                    <input
                                        id="codigo"
                                        type="text"
                                        value={codigo}
                                        onChange={(e) => setCodigo(e.target.value)}
                                        placeholder="123456"
                                        maxLength={6}
                                        required
                                    />
                                </div>
                            </div>

                            {error && <div className="error-message">{error}</div>}

                            {mensaje && (
                                <div className="error-message" style={{background: "#dcfce7", color: "#166534"}}>
                                    {mensaje}
                                </div>
                            )}

                            <button type="submit" className="login-button" disabled={cargando}>
                                {cargando ? "Verificando..." : "Verificar correo"}
                            </button>

                            <button
                                type="button"
                                className="forgot-link"
                                onClick={handleReenviar}
                                disabled={cargando}
                            >
                                Reenviar código
                            </button>

                            <button
                                type="button"
                                className="forgot-link"
                                onClick={() => navigate("/")}
                            >
                                Volver al login
                            </button>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    );
}

export default VerificarCorreo;