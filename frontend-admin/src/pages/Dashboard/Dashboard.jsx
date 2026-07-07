import {useEffect, useMemo, useState} from "react";
import {
    Area,
    AreaChart,
    Bar,
    BarChart,
    CartesianGrid,
    Cell,
    Legend,
    Pie,
    PieChart,
    ResponsiveContainer,
    Tooltip,
    XAxis,
    YAxis,
} from "recharts";

import {
    obtenerResumen,
    obtenerRecaudacion,
    obtenerAlertas,
} from "../../api/reportesService";

import "../Styles/Dashboard.css";

const chartColors = ["#2563eb", "#16a34a", "#f59e0b", "#dc2626", "#7c3aed"];

function Dashboard() {
    const [resumen, setResumen] = useState(null);
    const [recaudacion, setRecaudacion] = useState(null);
    const [alertas, setAlertas] = useState(null);
    const [cargando, setCargando] = useState(true);
    const [error, setError] = useState("");

    const cargarDatos = async () => {
        try {
            setCargando(true);
            setError("");

            const [resumenData, recaudacionData, alertasData] = await Promise.all([
                obtenerResumen(),
                obtenerRecaudacion(),
                obtenerAlertas(),
            ]);

            setResumen(resumenData);
            setRecaudacion(recaudacionData);
            setAlertas(alertasData);
        } catch (error) {
            console.error("Error cargando dashboard:", error);
            setError("No se pudieron cargar los datos del dashboard.");
        } finally {
            setCargando(false);
        }
    };

    useEffect(() => {
        cargarDatos();
    }, []);

    const datosRecaudacion = useMemo(() => {
        return [
            {
                nombre: "Peajes",
                valor: Number(recaudacion?.recaudacion_peajes || 0),
            },
            {
                nombre: "Membresías",
                valor: Number(recaudacion?.recaudacion_membresias || 0),
            },
            {
                nombre: "Recargas",
                valor: Number(recaudacion?.recargas_billetera || 0),
            },
        ];
    }, [recaudacion]);

    const datosPasos = useMemo(() => {
        return [
            {
                nombre: "Total de pases registrados",
                total: Number(resumen?.total_pasos || 0),
            },
            {
                nombre: "Membresía",
                total: Number(resumen?.pasos_cubiertos_por_membresia || 0),
            },
            {
                nombre: "Vehículos",
                total: Number(resumen?.total_vehiculos_detectados || 0),
            },
            {
                nombre: "Alertas",
                total: Number(resumen?.total_alertas || 0),
            },
        ];
    }, [resumen]);

    const datosAlertasEstado = useMemo(() => {
        if (!alertas?.por_estado?.length) {
            return [];
        }

        return alertas.por_estado.map((item) => ({
            nombre: item.estado || "Sin estado",
            total: Number(item.total || 0),
        }));
    }, [alertas]);

    const datosAlertasPeaje = useMemo(() => {
        if (!alertas?.por_peaje?.length) {
            return [];
        }

        return alertas.por_peaje.map((item) => ({
            nombre: item.peaje__nombre || "Sin peaje",
            total: Number(item.total_alertas || 0),
        }));
    }, [alertas]);

    if (cargando) {
        return (
            <div className="dashboard-page">
                <div className="dashboard-loading-card">
                    <h2>Dashboard</h2>
                    <p>Cargando información del sistema...</p>
                </div>
            </div>
        );
    }

    if (error) {
        return (
            <div className="dashboard-page">
                <div className="dashboard-error-card">
                    <h2>Dashboard</h2>
                    <div className="dashboard-error">{error}</div>
                    <button className="dashboard-retry" onClick={cargarDatos}>
                        Reintentar
                    </button>
                </div>
            </div>
        );
    }

    return (
        <div className="dashboard-page">
            <div className="dashboard-hero">
                <div>
                    <span className="dashboard-kicker">Centro de control</span>
                    <h2>Dashboard operativo</h2>
                    <p>
                        Visualización general de pasos, recaudación, membresías y alertas
                        del sistema inteligente de peaje.
                    </p>
                </div>

                <button className="dashboard-refresh" onClick={cargarDatos}>
                    Actualizar datos
                </button>
            </div>

            <div className="stats-grid">
                <div className="stat-card primary">
                    <div className="stat-icon">🛣️</div>
                    <span>Total de pases registrados</span>
                    <strong>{resumen?.total_pasos ?? 0}</strong>
                    <small>Registros procesados por el sistema</small>
                </div>

                <div className="stat-card success">
                    <div className="stat-icon">🚗</div>
                    <span>Vehículos detectados</span>
                    <strong>{resumen?.total_vehiculos_detectados ?? 0}</strong>
                    <small>Placas reconocidas por LPR</small>
                </div>

                <div className="stat-card danger">
                    <div className="stat-icon">🚨</div>
                    <span>Total de alertas</span>
                    <strong>{resumen?.total_alertas ?? 0}</strong>
                    <small>Eventos de seguridad generados</small>
                </div>

                <div className="stat-card warning">
                    <div className="stat-icon">🎫</div>
                    <span>Pasos con membresía</span>
                    <strong>{resumen?.pasos_cubiertos_por_membresia ?? 0}</strong>
                    <small>Cobros cubiertos por paquetes</small>
                </div>
            </div>

            <div className="stats-grid money-grid">
                <div className="stat-card money">
                    <span>Recaudación por peajes</span>
                    <strong>${recaudacion?.recaudacion_peajes ?? "0.00"}</strong>
                </div>

                <div className="stat-card money">
                    <span>Recaudación por membresías</span>
                    <strong>${recaudacion?.recaudacion_membresias ?? "0.00"}</strong>
                </div>

                <div className="stat-card money total">
                    <span>Recaudación total</span>
                    <strong>${recaudacion?.recaudacion_total ?? "0.00"}</strong>
                </div>

                <div className="stat-card money">
                    <span>Recargas de billetera</span>
                    <strong>${recaudacion?.recargas_billetera ?? "0.00"}</strong>
                </div>
            </div>

            <div className="dashboard-charts-grid">
                <section className="dashboard-chart-card">
                    <div className="chart-header">
                        <div>
                            <h3>Recaudación por fuente</h3>
                            <p>Distribución de ingresos registrados.</p>
                        </div>
                    </div>

                    <div className="chart-box">
                        <ResponsiveContainer width="100%" height={280}>
                            <PieChart>
                                <Pie
                                    data={datosRecaudacion}
                                    dataKey="valor"
                                    nameKey="nombre"
                                    cx="50%"
                                    cy="50%"
                                    innerRadius={62}
                                    outerRadius={96}
                                    paddingAngle={4}
                                    label
                                >
                                    {datosRecaudacion.map((_, index) => (
                                        <Cell
                                            key={`cell-recaudacion-${index}`}
                                            fill={chartColors[index % chartColors.length]}
                                        />
                                    ))}
                                </Pie>
                                <Tooltip formatter={(value) => `$${value}`}/>
                                <Legend/>
                            </PieChart>
                        </ResponsiveContainer>
                    </div>
                </section>

                <section className="dashboard-chart-card">
                    <div className="chart-header">
                        <div>
                            <h3>Indicadores operativos</h3>
                            <p>Tendencia visual de pasos, vehículos y alertas.</p>
                        </div>
                    </div>

                    <div className="chart-box">
                        <ResponsiveContainer width="100%" height={280}>
                            <AreaChart data={datosPasos}>
                                <defs>
                                    <linearGradient id="colorIndicadores" x1="0" y1="0" x2="0" y2="1">
                                        <stop offset="5%" stopColor="#2563eb" stopOpacity={0.45}/>
                                        <stop offset="95%" stopColor="#2563eb" stopOpacity={0.05}/>
                                    </linearGradient>
                                </defs>
                                <CartesianGrid strokeDasharray="3 3"/>
                                <XAxis dataKey="nombre"/>
                                <YAxis/>
                                <Tooltip/>
                                <Area
                                    type="monotone"
                                    dataKey="total"
                                    stroke="#2563eb"
                                    strokeWidth={3}
                                    fill="url(#colorIndicadores)"
                                    activeDot={{r: 7}}
                                />
                            </AreaChart>
                        </ResponsiveContainer>
                    </div>
                </section>

                <section className="dashboard-chart-card">
                    <div className="chart-header">
                        <div>
                            <h3>Alertas por estado</h3>
                            <p>Estado actual de las alertas generadas.</p>
                        </div>
                    </div>

                    <div className="chart-box">
                        {datosAlertasEstado.length > 0 ? (
                            <ResponsiveContainer width="100%" height={280}>
                                <PieChart>
                                    <Pie
                                        data={datosAlertasEstado}
                                        dataKey="total"
                                        nameKey="nombre"
                                        cx="50%"
                                        cy="50%"
                                        outerRadius={95}
                                        label
                                    >
                                        {datosAlertasEstado.map((_, index) => (
                                            <Cell
                                                key={`cell-alerta-estado-${index}`}
                                                fill={chartColors[index % chartColors.length]}
                                            />
                                        ))}
                                    </Pie>
                                    <Tooltip/>
                                    <Legend/>
                                </PieChart>
                            </ResponsiveContainer>
                        ) : (
                            <div className="empty-chart">No existen alertas registradas.</div>
                        )}
                    </div>
                </section>

                <section className="dashboard-chart-card">
                    <div className="chart-header">
                        <div>
                            <h3>Alertas por peaje</h3>
                            <p>Puntos con mayor cantidad de alertas.</p>
                        </div>
                    </div>

                    <div className="chart-box">
                        {datosAlertasPeaje.length > 0 ? (
                            <ResponsiveContainer width="100%" height={280}>
                                <BarChart
                                    data={datosAlertasPeaje}
                                    layout="vertical"
                                    margin={{top: 10, right: 20, left: 30, bottom: 10}}
                                >
                                    <CartesianGrid strokeDasharray="3 3"/>
                                    <XAxis type="number"/>
                                    <YAxis type="category" dataKey="nombre" width={100}/>
                                    <Tooltip/>
                                    <Bar dataKey="total" radius={[0, 10, 10, 0]}>
                                        {datosAlertasPeaje.map((_, index) => (
                                            <Cell
                                                key={`cell-alerta-peaje-${index}`}
                                                fill={chartColors[index % chartColors.length]}
                                            />
                                        ))}
                                    </Bar>
                                </BarChart>
                            </ResponsiveContainer>
                        ) : (
                            <div className="empty-chart">No existen alertas por peaje.</div>
                        )}
                    </div>
                </section>
            </div>

            <div className="dashboard-bottom-grid">
                <section className="dashboard-table-card">
                    <div className="chart-header">
                        <div>
                            <h3>Resumen de alertas por estado</h3>
                            <p>Detalle tabular para revisión rápida.</p>
                        </div>
                    </div>

                    <table>
                        <thead>
                        <tr>
                            <th>Estado</th>
                            <th>Total</th>
                        </tr>
                        </thead>

                        <tbody>
                        {alertas?.por_estado?.length > 0 ? (
                            alertas.por_estado.map((item) => (
                                <tr key={item.estado}>
                                    <td>
                      <span className="dashboard-badge">
                        {item.estado || "Sin estado"}
                      </span>
                                    </td>
                                    <td>{item.total}</td>
                                </tr>
                            ))
                        ) : (
                            <tr>
                                <td colSpan="2">No existen alertas registradas.</td>
                            </tr>
                        )}
                        </tbody>
                    </table>
                </section>

                <section className="quick-actions-card">
                    <div className="chart-header">
                        <div>
                            <h3>Accesos rápidos</h3>
                            <p>Ir directamente a los módulos principales.</p>
                        </div>
                    </div>

                    <div className="quick-actions-grid">
                        <a href="/reconocimiento-placas">🔎 Reconocimiento LPR</a>
                        <a href="/vehiculos">🚗 Vehículos</a>
                        <a href="/alertas">🚨 Alertas</a>
                        <a href="/reportes">📈 Reportes</a>
                    </div>
                </section>
            </div>
        </div>
    );
}

export default Dashboard;