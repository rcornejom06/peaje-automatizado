import {useEffect, useState} from "react";
import * as XLSX from "xlsx-js-style";
import {
    obtenerResumen,
    obtenerRecaudacion,
    obtenerPasosPorPeaje,
    obtenerAlertasReporte,
    obtenerVehiculosDetectados,
    obtenerUsoMembresias,
} from "../../api/reportesService";
import "../Styles/Reportes.css";
import ModuleHeader from "../../components/ModuleHeader/ModuleHeader";


// Fecha local (no UTC) en formato YYYY-MM-DD, para que el filtro por
// defecto sea "hoy" segun la hora del navegador del usuario, no la de UTC.
const obtenerFechaHoyLocal = () => {
    const ahora = new Date();
    const offsetMs = ahora.getTimezoneOffset() * 60000;
    const local = new Date(ahora.getTime() - offsetMs);
    return local.toISOString().slice(0, 10);
};

function Reportes() {
    const [tab, setTab] = useState("recaudacion");
    const [cargando, setCargando] = useState(false);
    const [error, setError] = useState("");

    // Un solo campo de fecha (no un rango): fecha_inicio y fecha_fin
    // siempre se mandan iguales, para filtrar "ese dia" exactamente.
    // Arranca en el dia de hoy en vez de mostrar todo el historial.
    const [filtros, setFiltros] = useState({
        fecha_inicio: obtenerFechaHoyLocal(),
        fecha_fin: obtenerFechaHoyLocal(),
    });

    const [resumen, setResumen] = useState(null);
    const [recaudacion, setRecaudacion] = useState(null);
    const [pasosPorPeaje, setPasosPorPeaje] = useState([]);
    const [alertas, setAlertas] = useState(null);
    const [vehiculosDetectados, setVehiculosDetectados] = useState(null);
    const [usoMembresias, setUsoMembresias] = useState(null);

    const cargarReportes = async (filtrosActuales = filtros) => {
        try {
            setCargando(true);
            setError("");

            const [
                resumenData,
                recaudacionData,
                pasosData,
                alertasData,
                vehiculosData,
                usoMembresiasData,
            ] = await Promise.all([
                obtenerResumen(filtrosActuales),
                obtenerRecaudacion(filtrosActuales),
                obtenerPasosPorPeaje(filtrosActuales),
                obtenerAlertasReporte(filtrosActuales),
                obtenerVehiculosDetectados(filtrosActuales),
                obtenerUsoMembresias(filtrosActuales),
            ]);

            setResumen(resumenData);
            setRecaudacion(recaudacionData);
            setPasosPorPeaje(Array.isArray(pasosData) ? pasosData : []);
            setAlertas(alertasData);
            setVehiculosDetectados(vehiculosData);
            setUsoMembresias(usoMembresiasData);
        } finally {
            setCargando(false);
        }
    };

    useEffect(() => {
        cargarReportes();
    }, []);

    const handleFiltroChange = (e) => {
        setFiltros({
            ...filtros,
            [e.target.name]: e.target.value,
        });
    };

    // El input de fecha unico actualiza fecha_inicio y fecha_fin al mismo
    // valor, para que el backend filtre exactamente ese dia.
    const handleFechaChange = (e) => {
        const nuevaFecha = e.target.value;

        setFiltros((actual) => ({
            ...actual,
            fecha_inicio: nuevaFecha,
            fecha_fin: nuevaFecha,
        }));
    };

    const limpiarFiltros = async () => {
        const filtrosLimpios = {
            fecha_inicio: "",
            fecha_fin: "",
        };

        setFiltros(filtrosLimpios);
        await cargarReportes(filtrosLimpios);
    };
        const valorSeguro = (valor, defecto = "") => {
        if (valor === null || valor === undefined || valor === "") {
            return defecto;
        }

        return valor;
    };

    const formatearFechaExcel = (fecha) => {
        if (!fecha) return "Sin fecha";

        try {
            return new Date(fecha).toLocaleString("es-EC");
        } catch {
            return fecha;
        }
    };

    const nombreArchivoFecha = () => {
        const ahora = new Date();

        const yyyy = ahora.getFullYear();
        const mm = String(ahora.getMonth() + 1).padStart(2, "0");
        const dd = String(ahora.getDate()).padStart(2, "0");
        const hh = String(ahora.getHours()).padStart(2, "0");
        const mi = String(ahora.getMinutes()).padStart(2, "0");

        return `${yyyy}-${mm}-${dd}_${hh}-${mi}`;
    };

    const coloresExcel = {
        azulOscuro: "0B3A53",
        azulHeader: "2F7DB8",
        azulClaro: "DDEBF7",
        verde: "70AD47",
        rojo: "C00000",
        rojoClaro: "F4CCCC",
        amarillo: "FFD966",
        amarilloClaro: "FFF2CC",
        blanco: "FFFFFF",
        negro: "111111",
        bordeAzul: "9CC2E5",
    };

    const bordeExcel = {
        top: {style: "thin", color: {rgb: coloresExcel.bordeAzul}},
        bottom: {style: "thin", color: {rgb: coloresExcel.bordeAzul}},
        left: {style: "thin", color: {rgb: coloresExcel.bordeAzul}},
        right: {style: "thin", color: {rgb: coloresExcel.bordeAzul}},
    };

    const estiloTituloExcel = {
        font: {
            bold: true,
            color: {rgb: coloresExcel.blanco},
            sz: 18,
        },
        fill: {
            fgColor: {rgb: coloresExcel.azulOscuro},
        },
        alignment: {
            horizontal: "center",
            vertical: "center",
        },
    };

    const estiloSubtituloExcel = {
        font: {
            italic: true,
            color: {rgb: coloresExcel.azulOscuro},
            sz: 10,
        },
        fill: {
            fgColor: {rgb: coloresExcel.azulClaro},
        },
        alignment: {
            vertical: "center",
        },
    };

    const estiloGeneradoExcel = {
        font: {
            bold: true,
            color: {rgb: coloresExcel.azulOscuro},
            sz: 10,
        },
        fill: {
            fgColor: {rgb: coloresExcel.azulClaro},
        },
        alignment: {
            horizontal: "center",
            vertical: "center",
        },
    };

    const estiloHeaderTablaExcel = {
        font: {
            bold: true,
            color: {rgb: coloresExcel.blanco},
            sz: 11,
        },
        fill: {
            fgColor: {rgb: coloresExcel.azulHeader},
        },
        alignment: {
            horizontal: "center",
            vertical: "center",
            wrapText: true,
        },
        border: bordeExcel,
    };

    const estiloCeldaExcel = {
        font: {
            color: {rgb: coloresExcel.negro},
            sz: 10,
        },
        alignment: {
            vertical: "center",
            wrapText: true,
        },
        border: bordeExcel,
    };

    const estiloCeldaCentradaExcel = {
        ...estiloCeldaExcel,
        alignment: {
            horizontal: "center",
            vertical: "center",
            wrapText: true,
        },
    };

    const crearEstiloResumenTitulo = (colorFondo, colorTexto = coloresExcel.blanco) => ({
        font: {
            bold: true,
            color: {rgb: colorTexto},
            sz: 10,
        },
        fill: {
            fgColor: {rgb: colorFondo},
        },
        alignment: {
            horizontal: "center",
            vertical: "center",
            wrapText: true,
        },
        border: bordeExcel,
    });

    const crearEstiloResumenValor = (colorFondo, colorTexto) => ({
        font: {
            bold: true,
            color: {rgb: colorTexto},
            sz: 16,
        },
        fill: {
            fgColor: {rgb: colorFondo},
        },
        alignment: {
            horizontal: "center",
            vertical: "center",
        },
        border: bordeExcel,
    });

    const asegurarCelda = (worksheet, fila, columna) => {
        const direccion = XLSX.utils.encode_cell({
            r: fila,
            c: columna,
        });

        if (!worksheet[direccion]) {
            worksheet[direccion] = {
                v: "",
            };
        }

        return worksheet[direccion];
    };

    const aplicarEstiloRango = (worksheet, filaInicio, filaFin, columnaInicio, columnaFin, estilo) => {
        for (let fila = filaInicio; fila <= filaFin; fila++) {
            for (let columna = columnaInicio; columna <= columnaFin; columna++) {
                asegurarCelda(worksheet, fila, columna).s = estilo;
            }
        }
    };

    const limpiarNombreHoja = (nombre) => {
        return String(nombre || "Reporte")
            .replace(/[\\/?*[\]:]/g, "")
            .substring(0, 31);
    };

    const obtenerEstadoNormalizadoExcel = (item) => {
        const texto = String(
            item?.estado ||
            item?.Estado ||
            item?.estado_pago ||
            item?.Pago ||
            item?.estado_seguridad ||
            item?.Seguridad ||
            ""
        ).toLowerCase();

        if (
            texto.includes("aprobado") ||
            texto.includes("aprobada") ||
            texto.includes("pagado") ||
            texto.includes("pagada") ||
            texto.includes("activo") ||
            texto.includes("activa") ||
            texto.includes("cerrada") ||
            texto.includes("cerrado") ||
            texto.includes("revisada") ||
            texto.includes("revisado") ||
            texto.includes("exitoso")
        ) {
            return "exitoso";
        }

        if (
            texto.includes("rechazado") ||
            texto.includes("rechazada") ||
            texto.includes("fallido") ||
            texto.includes("fallida") ||
            texto.includes("inactivo") ||
            texto.includes("inactiva") ||
            texto.includes("descartada") ||
            texto.includes("descartado")
        ) {
            return "rechazado";
        }

        if (
            texto.includes("error") ||
            texto.includes("pendiente") ||
            texto.includes("alerta") ||
            texto.includes("robado") ||
            texto.includes("robo") ||
            texto.includes("derivada") ||
            texto.includes("derivado")
        ) {
            return "error";
        }

        return "otro";
    };

    const calcularResumenExcel = (datos, resumenManual = {}) => {
        if (resumenManual) {
            return {
                total: resumenManual.total ?? datos.length,
                exitosos: resumenManual.exitosos ?? 0,
                rechazados: resumenManual.rechazados ?? 0,
                errores: resumenManual.errores ?? 0,
            };
        }

        return {
            total: datos.length,
            exitosos: datos.filter((item) => obtenerEstadoNormalizadoExcel(item) === "exitoso").length,
            rechazados: datos.filter((item) => obtenerEstadoNormalizadoExcel(item) === "rechazado").length,
            errores: datos.filter((item) => obtenerEstadoNormalizadoExcel(item) === "error").length,
        };
    };

    const agregarHojaViasmart = ({
        workbook,
        nombre,
        titulo,
        subtitulo,
        columnas,
        datos,
        resumenManual = null,
    }) => {
        const datosSeguros = Array.isArray(datos) && datos.length > 0
            ? datos
            : [{mensaje: "Sin datos disponibles"}];

        const columnasSeguras = Array.isArray(columnas) && columnas.length > 0
            ? columnas
            : Object.keys(datosSeguros[0]).map((key) => ({
                header: key,
                key,
            }));

        const maxColumnas = Math.max(8, columnasSeguras.length);
        const ultimaColumna = XLSX.utils.encode_col(maxColumnas - 1);

        const resumen = calcularResumenExcel(datosSeguros, resumenManual);

        const worksheet = {};

        const filaTitulo = Array(maxColumnas).fill("");
        filaTitulo[0] = titulo;

        const filaSubtitulo = Array(maxColumnas).fill("");
        filaSubtitulo[0] = subtitulo;
        filaSubtitulo[maxColumnas - 2] = "Generado:";
        filaSubtitulo[maxColumnas - 1] = formatearFechaExcel(new Date());

        const filaResumenTitulos = Array(maxColumnas).fill("");
        const filaResumenValores = Array(maxColumnas).fill("");

        const gruposResumen = [
            {
                titulo: "TOTAL REGISTROS",
                valor: resumen.total,
                tituloStyle: crearEstiloResumenTitulo(coloresExcel.azulHeader),
                valorStyle: crearEstiloResumenValor(coloresExcel.blanco, coloresExcel.azulOscuro),
            },
            {
                titulo: "EXITOSOS",
                valor: resumen.exitosos,
                tituloStyle: crearEstiloResumenTitulo(coloresExcel.verde),
                valorStyle: crearEstiloResumenValor(coloresExcel.blanco, coloresExcel.azulOscuro),
            },
            {
                titulo: "RECHAZADOS",
                valor: resumen.rechazados,
                tituloStyle: crearEstiloResumenTitulo(coloresExcel.rojo),
                valorStyle: crearEstiloResumenValor(coloresExcel.rojoClaro, coloresExcel.rojo),
            },
            {
                titulo: "ERRORES",
                valor: resumen.errores,
                tituloStyle: crearEstiloResumenTitulo(coloresExcel.amarillo, "7F6000"),
                valorStyle: crearEstiloResumenValor(coloresExcel.amarilloClaro, "7F6000"),
            },
        ];

        gruposResumen.forEach((grupo, index) => {
            const inicio = Math.floor((index * maxColumnas) / 4);
            filaResumenTitulos[inicio] = grupo.titulo;
            filaResumenValores[inicio] = grupo.valor;
        });

        const filaEncabezados = Array(maxColumnas).fill("");
        columnasSeguras.forEach((columna, index) => {
            filaEncabezados[index] = columna.header;
        });

        const filasDatos = datosSeguros.map((item) => {
            const fila = Array(maxColumnas).fill("");

            columnasSeguras.forEach((columna, index) => {
                if (typeof columna.value === "function") {
                    fila[index] = columna.value(item);
                } else {
                    fila[index] = valorSeguro(item[columna.key], "");
                }
            });

            return fila;
        });

        XLSX.utils.sheet_add_aoa(
            worksheet,
            [
                filaTitulo,
                filaSubtitulo,
                Array(maxColumnas).fill(""),
                filaResumenTitulos,
                filaResumenValores,
                Array(maxColumnas).fill(""),
                filaEncabezados,
                ...filasDatos,
            ],
            {
                origin: "A1",
            }
        );

        const ultimaFila = Math.max(30, filasDatos.length + 7);
        worksheet["!ref"] = `A1:${ultimaColumna}${ultimaFila}`;

        const merges = [
            {
                s: {r: 0, c: 0},
                e: {r: 0, c: maxColumnas - 1},
            },
            {
                s: {r: 1, c: 0},
                e: {r: 1, c: Math.max(0, maxColumnas - 3)},
            },
        ];

        gruposResumen.forEach((_, index) => {
            const inicio = Math.floor((index * maxColumnas) / 4);
            const fin = index === 3
                ? maxColumnas - 1
                : Math.floor(((index + 1) * maxColumnas) / 4) - 1;

            if (inicio < fin) {
                merges.push({
                    s: {r: 3, c: inicio},
                    e: {r: 3, c: fin},
                });

                merges.push({
                    s: {r: 4, c: inicio},
                    e: {r: 4, c: fin},
                });
            }
        });

        worksheet["!merges"] = merges;

        worksheet["!cols"] = Array.from({length: maxColumnas}).map((_, index) => {
            const columna = columnasSeguras[index];

            if (columna?.width) {
                return {
                    wch: columna.width,
                };
            }

            if (index === 0) return {wch: 12};
            if (index === 1) return {wch: 24};
            if (index === 5) return {wch: 42};

            return {
                wch: Math.max(String(columna?.header || "").length + 6, 16),
            };
        });

        worksheet["!rows"] = [
            {hpt: 24},
            {hpt: 18},
            {hpt: 8},
            {hpt: 20},
            {hpt: 24},
            {hpt: 8},
            {hpt: 24},
        ];

        aplicarEstiloRango(worksheet, 0, 0, 0, maxColumnas - 1, estiloTituloExcel);

        for (let col = 0; col < maxColumnas; col++) {
            asegurarCelda(worksheet, 1, col).s =
                col >= maxColumnas - 2 ? estiloGeneradoExcel : estiloSubtituloExcel;
        }

        gruposResumen.forEach((grupo, index) => {
            const inicio = Math.floor((index * maxColumnas) / 4);
            const fin = index === 3
                ? maxColumnas - 1
                : Math.floor(((index + 1) * maxColumnas) / 4) - 1;

            aplicarEstiloRango(worksheet, 3, 3, inicio, fin, grupo.tituloStyle);
            aplicarEstiloRango(worksheet, 4, 4, inicio, fin, grupo.valorStyle);
        });

        aplicarEstiloRango(worksheet, 6, 6, 0, maxColumnas - 1, estiloHeaderTablaExcel);

        for (let fila = 7; fila < ultimaFila; fila++) {
            const esFilaAlterna = fila % 2 === 0;

            for (let col = 0; col < maxColumnas; col++) {
                const estiloBase = [0, 1, maxColumnas - 2, maxColumnas - 1].includes(col)
                    ? estiloCeldaCentradaExcel
                    : estiloCeldaExcel;

                asegurarCelda(worksheet, fila, col).s = {
                    ...estiloBase,
                    fill: {
                        fgColor: {
                            rgb: esFilaAlterna ? "F7FBFF" : coloresExcel.blanco,
                        },
                    },
                };
            }
        }

        worksheet["!autofilter"] = {
            ref: `A7:${ultimaColumna}${Math.max(7, filasDatos.length + 7)}`,
        };

        XLSX.utils.book_append_sheet(
            workbook,
            worksheet,
            limpiarNombreHoja(nombre)
        );
    };

    const descargarReporteExcel = () => {
        const workbook = XLSX.utils.book_new();

        const totalTransacciones =
            Number(recaudacion?.transacciones_aprobadas || 0) +
            Number(recaudacion?.transacciones_fallidas || 0);

        agregarHojaViasmart({
            workbook,
            nombre: "Recaudación",
            titulo: "REPORTE DE RECAUDACIÓN DEL SISTEMA",
            subtitulo: "VIASMART - Reporte financiero y transacciones",
            resumenManual: {
                total: totalTransacciones,
                exitosos: Number(recaudacion?.transacciones_aprobadas || 0),
                rechazados: Number(recaudacion?.transacciones_fallidas || 0),
                errores: 0,
            },
            columnas: [
                {header: "Concepto", key: "concepto", width: 34},
                {header: "Valor", key: "valor", width: 22},
                {header: "Observación", key: "observacion", width: 48},
            ],
            datos: [
                {
                    concepto: "Recaudación por peajes",
                    valor: valorSeguro(recaudacion?.recaudacion_peajes, 0),
                    observacion: "Ingresos generados por pasos de peaje.",
                },
                {
                    concepto: "Recaudación por membresías",
                    valor: valorSeguro(recaudacion?.recaudacion_membresias, 0),
                    observacion: "Ingresos generados por compra de membresías.",
                },
                {
                    concepto: "Total recaudado",
                    valor: valorSeguro(recaudacion?.recaudacion_total, 0),
                    observacion: "Suma total de ingresos registrados.",
                },
                {
                    concepto: "Recargas billetera",
                    valor: valorSeguro(recaudacion?.recargas_billetera, 0),
                    observacion: "Total de recargas realizadas por usuarios.",
                },
                {
                    concepto: "Pagos por billetera",
                    valor: valorSeguro(recaudacion?.pagos_por_billetera, 0),
                    observacion: "Pagos ejecutados con saldo de billetera.",
                },
                {
                    concepto: "Usos de membresía",
                    valor: valorSeguro(recaudacion?.usos_membresia, 0),
                    observacion: "Cantidad de pasos cubiertos por membresía.",
                },
                {
                    concepto: "Transacciones aprobadas",
                    valor: valorSeguro(recaudacion?.transacciones_aprobadas, 0),
                    observacion: "Operaciones procesadas correctamente.",
                },
                {
                    concepto: "Transacciones fallidas",
                    valor: valorSeguro(recaudacion?.transacciones_fallidas, 0),
                    observacion: "Operaciones no procesadas.",
                },
                {
                    concepto: "Nota",
                    valor: valorSeguro(recaudacion?.nota, ""),
                    observacion: "",
                },
            ],
        });

        agregarHojaViasmart({
            workbook,
            nombre: "Pasos por peaje",
            titulo: "REPORTE DE PASOS POR PEAJE",
            subtitulo: "VIASMART - Flujo vehicular por estación",
            resumenManual: {
                total: pasosPorPeaje.reduce(
                    (total, item) => total + Number(item.total_pasos || 0),
                    0
                ),
                exitosos: pasosPorPeaje.reduce(
                    (total, item) =>
                        total +
                        Number(item.pagados || 0) +
                        Number(item.membresia || 0),
                    0
                ),
                rechazados: pasosPorPeaje.reduce(
                    (total, item) => total + Number(item.fallidos || 0),
                    0
                ),
                errores: pasosPorPeaje.reduce(
                    (total, item) =>
                        total +
                        Number(item.pendientes || 0) +
                        Number(item.alertas || 0),
                    0
                ),
            },
            columnas: [
                {header: "Peaje", key: "peaje", width: 28},
                {header: "Ciudad", key: "ciudad", width: 22},
                {header: "Total pasos", key: "total_pasos", width: 18},
                {header: "Vehículos distintos", key: "vehiculos_distintos", width: 22},
                {header: "Pagados", key: "pagados", width: 16},
                {header: "Membresía", key: "membresia", width: 16},
                {header: "Pendientes", key: "pendientes", width: 16},
                {header: "Fallidos", key: "fallidos", width: 16},
                {header: "Alertas", key: "alertas", width: 16},
            ],
            datos: pasosPorPeaje.map((item) => ({
                peaje: item.peaje_nombre || item.peaje__nombre || "Sin peaje",
                ciudad: item.peaje_ciudad || item.peaje__ciudad || "Sin ciudad",
                total_pasos: valorSeguro(item.total_pasos, 0),
                vehiculos_distintos: valorSeguro(item.vehiculos_distintos, 0),
                pagados: valorSeguro(item.pagados, 0),
                membresia: valorSeguro(item.membresia, 0),
                pendientes: valorSeguro(item.pendientes, 0),
                fallidos: valorSeguro(item.fallidos, 0),
                alertas: valorSeguro(item.alertas, 0),
            })),
        });

        agregarHojaViasmart({
            workbook,
            nombre: "Alertas por estado",
            titulo: "REPORTE DE ALERTAS POR ESTADO",
            subtitulo: "VIASMART - Seguridad vehicular",
            resumenManual: {
                total: valorSeguro(alertas?.total_alertas, 0),
                exitosos: alertas?.por_estado?.filter((item) =>
                    ["cerrada", "revisada"].includes(item.estado)
                ).reduce((total, item) => total + Number(item.total || 0), 0) || 0,
                rechazados: alertas?.por_estado?.filter((item) =>
                    ["descartada"].includes(item.estado)
                ).reduce((total, item) => total + Number(item.total || 0), 0) || 0,
                errores: alertas?.por_estado?.filter((item) =>
                    ["pendiente", "derivada"].includes(item.estado)
                ).reduce((total, item) => total + Number(item.total || 0), 0) || 0,
            },
            columnas: [
                {header: "Estado", key: "estado", width: 28},
                {header: "Total", key: "total", width: 18},
            ],
            datos: alertas?.por_estado || [],
        });

        agregarHojaViasmart({
            workbook,
            nombre: "Alertas por peaje",
            titulo: "REPORTE DE ALERTAS POR PEAJE",
            subtitulo: "VIASMART - Alertas agrupadas por estación",
            resumenManual: {
                total: alertas?.por_peaje?.reduce(
                    (total, item) => total + Number(item.total_alertas || 0),
                    0
                ) || 0,
                exitosos: 0,
                rechazados: 0,
                errores: alertas?.por_peaje?.reduce(
                    (total, item) => total + Number(item.total_alertas || 0),
                    0
                ) || 0,
            },
            columnas: [
                {
                    header: "Peaje",
                    value: (item) =>
                        item.peaje__nombre || item.peaje_nombre || "Sin peaje",
                    width: 34,
                },
                {header: "Total alertas", key: "total_alertas", width: 20},
            ],
            datos: alertas?.por_peaje || [],
        });

        agregarHojaViasmart({
            workbook,
            nombre: "Últimas alertas",
            titulo: "REPORTE DE ÚLTIMAS ALERTAS",
            subtitulo: "VIASMART - Registro de eventos de seguridad",
            columnas: [
                {header: "ID", key: "id", width: 10},
                {header: "Placa", key: "placa", width: 18},
                {header: "Peaje", key: "peaje", width: 28},
                {header: "Tipo", key: "tipo_alerta", width: 28},
                {header: "Estado", key: "estado", width: 18},
                {
                    header: "Fecha y hora",
                    value: (item) => formatearFechaExcel(item.fecha_hora),
                    width: 24,
                },
            ],
            datos: alertas?.ultimas_alertas || [],
        });

        agregarHojaViasmart({
            workbook,
            nombre: "Vehículos detectados",
            titulo: "REPORTE DE VEHÍCULOS DETECTADOS",
            subtitulo: "VIASMART - Resumen de detecciones LPR",
            resumenManual: {
                total: valorSeguro(vehiculosDetectados?.total_detecciones, 0),
                exitosos: valorSeguro(vehiculosDetectados?.vehiculos_distintos, 0),
                rechazados: 0,
                errores: 0,
            },
            columnas: [
                {header: "Concepto", key: "concepto", width: 34},
                {header: "Valor", key: "valor", width: 20},
            ],
            datos: [
                {
                    concepto: "Total detecciones",
                    valor: valorSeguro(vehiculosDetectados?.total_detecciones, 0),
                },
                {
                    concepto: "Vehículos distintos",
                    valor: valorSeguro(vehiculosDetectados?.vehiculos_distintos, 0),
                },
            ],
        });

        agregarHojaViasmart({
            workbook,
            nombre: "Top vehículos",
            titulo: "REPORTE DE TOP VEHÍCULOS DETECTADOS",
            subtitulo: "VIASMART - Vehículos con mayor frecuencia de detección",
            columnas: [
                {header: "Placa", key: "placa_detectada", width: 18},
                {header: "Total detecciones", key: "total_detecciones", width: 22},
            ],
            datos: vehiculosDetectados?.top_vehiculos_detectados || [],
        });

        agregarHojaViasmart({
            workbook,
            nombre: "Últimas detecciones",
            titulo: "REPORTE DE ÚLTIMAS DETECCIONES",
            subtitulo: "VIASMART - Registro LPR de vehículos",
            columnas: [
                {header: "ID", key: "id", width: 10},
                {header: "Placa", key: "placa_detectada", width: 18},
                {
                    header: "Vehículo",
                    value: (item) => item.vehiculo || "No registrado",
                    width: 28,
                },
                {
                    header: "Peaje",
                    value: (item) => item.peaje || "Sin peaje",
                    width: 28,
                },
                {
                    header: "Cámara",
                    value: (item) => item.camara || "Sin cámara",
                    width: 24,
                },
                {header: "Pago", key: "estado_pago", width: 18},
                {header: "Seguridad", key: "estado_seguridad", width: 18},
                {
                    header: "Tarifa",
                    value: (item) => valorSeguro(item.tarifa_aplicada, 0),
                    width: 16,
                },
                {
                    header: "Fecha y hora",
                    value: (item) => formatearFechaExcel(item.fecha_hora),
                    width: 24,
                },
            ],
            datos: vehiculosDetectados?.ultimas_detecciones || [],
        });

        agregarHojaViasmart({
            workbook,
            nombre: "Uso membresías",
            titulo: "REPORTE DE USO DE MEMBRESÍAS",
            subtitulo: "VIASMART - Consumo de pases por membresía",
            resumenManual: {
                total: valorSeguro(usoMembresias?.total_pasos_cubiertos_por_membresia, 0),
                exitosos: valorSeguro(usoMembresias?.membresias_activas, 0),
                rechazados: 0,
                errores: 0,
            },
            columnas: [
                {header: "Concepto", key: "concepto", width: 40},
                {header: "Valor", key: "valor", width: 20},
            ],
            datos: [
                {
                    concepto: "Pasos cubiertos por membresía",
                    valor: valorSeguro(
                        usoMembresias?.total_pasos_cubiertos_por_membresia,
                        0
                    ),
                },
                {
                    concepto: "Membresías activas",
                    valor: valorSeguro(usoMembresias?.membresias_activas, 0),
                },
                {
                    concepto: "Pases restantes",
                    valor: valorSeguro(usoMembresias?.pases_restantes_totales, 0),
                },
            ],
        });

        agregarHojaViasmart({
            workbook,
            nombre: "Uso por plan",
            titulo: "REPORTE DE USO POR PLAN",
            subtitulo: "VIASMART - Membresías agrupadas por plan",
            columnas: [
                {
                    header: "Plan",
                    value: (item) =>
                        item.membresia_utilizada__plan__nombre || "Sin plan",
                    width: 36,
                },
                {header: "Total usos", key: "total_usos", width: 20},
            ],
            datos: usoMembresias?.uso_por_plan || [],
        });

        agregarHojaViasmart({
            workbook,
            nombre: "Membresías activas",
            titulo: "REPORTE DE MEMBRESÍAS ACTIVAS",
            subtitulo: "VIASMART - Estado de membresías de usuarios",
            columnas: [
                {header: "ID", key: "id", width: 10},
                {header: "Usuario", key: "usuario", width: 28},
                {header: "Plan", key: "plan", width: 30},
                {header: "Estado", key: "estado", width: 18},
                {header: "Pases restantes", key: "pases_restantes", width: 22},
                {header: "Inicio", key: "fecha_inicio", width: 22},
                {
                    header: "Fin / Observación",
                    value: (item) =>
                        item.pases_restantes > 0
                            ? `Agotamiento de pases (${item.pases_restantes} restantes)`
                            : "Pases agotados",
                    width: 36,
                },
            ],
            datos: usoMembresias?.membresias || [],
        });

        XLSX.writeFile(
            workbook,
            `reporte_general_peaje_${nombreArchivoFecha()}.xlsx`
        );
    };

    const formatoDinero = (valor) => {
        const numero = Number(valor || 0);
        return `$${numero.toFixed(2)}`;
    };

    return (
        <div className="reportes-page">
            <ModuleHeader
                icon="📈"
                title="Reportes del sistema"
                subtitle="Genera reportes operativos, financieros y de uso del sistema."
                badge="Analítica"
                status="Datos actualizados"
                actions={
                    <>
                        <button className="btn-primary" onClick={descargarReporteExcel}>
                            Descargar reporte completo
                        </button>
                        <button
                            className="btn-secondary"
                            onClick={() => cargarReportes()}
                        >
                            Actualizar reportes
                        </button>

                    </>

                }

            />

            {error && <div className="reportes-error">{error}</div>}

            <div className="filtros-card">
                <div className="form-group">
                    <label>Fecha</label>
                    <input
                        type="date"
                        name="fecha"
                        value={filtros.fecha_inicio}
                        onChange={handleFechaChange}
                    />
                </div>


                <div className="filtros-actions">
                    <button className="btn-primary" onClick={() => cargarReportes()}>
                        Aplicar filtros
                    </button>

                    <button className="btn-secondary" onClick={limpiarFiltros}>
                        Limpiar
                    </button>
                </div>
            </div>

            {cargando && <p>Cargando reportes...</p>}

            {resumen && (
                <div className="stats-grid resumen-general-grid">
                    <div className="stat-card">
                        <span>Total pasos</span>
                        <strong>{resumen.total_pasos ?? 0}</strong>
                    </div>
                    <div className="stat-card success">
                        <span>Pasos pagados</span>
                        <strong>{resumen.pasos_pagados ?? 0}</strong>
                    </div>
                    <div className="stat-card danger">
                        <span>Alertas</span>
                        <strong>{resumen.pasos_alerta ?? resumen.total_alertas ?? 0}</strong>
                    </div>
                </div>
            )}

            <div className="tabs">


                <button
                    className={tab === "recaudacion" ? "active" : ""}
                    onClick={() => setTab("recaudacion")}
                >
                    Recaudación
                </button>

                <button
                    className={tab === "pasos" ? "active" : ""}
                    onClick={() => setTab("pasos")}
                >
                    Pasos por peaje
                </button>

                <button
                    className={tab === "alertas" ? "active" : ""}
                    onClick={() => setTab("alertas")}
                >
                    Alertas
                </button>

                <button
                    className={tab === "vehiculos" ? "active" : ""}
                    onClick={() => setTab("vehiculos")}
                >
                    Vehículos detectados
                </button>

                <button
                    className={tab === "membresias" ? "active" : ""}
                    onClick={() => setTab("membresias")}
                >
                    Uso de membresías
                </button>
            </div>


            {tab === "recaudacion" && (
                <div className="report-section">
                    <h3>Reporte de recaudación</h3>

                    <div className="stats-grid">
                        <div className="stat-card money">
                            <span>Recaudación por peajes</span>
                            <strong>{formatoDinero(recaudacion?.recaudacion_peajes)}</strong>
                        </div>

                        <div className="stat-card money">
                            <span>Recaudación por membresías</span>
                            <strong>{formatoDinero(recaudacion?.recaudacion_membresias)}</strong>
                        </div>

                        <div className="stat-card money">
                            <span>Total recaudado</span>
                            <strong>{formatoDinero(recaudacion?.recaudacion_total)}</strong>
                        </div>

                        <div className="stat-card money">
                            <span>Recargas billetera</span>
                            <strong>{formatoDinero(recaudacion?.recargas_billetera)}</strong>
                        </div>

                        <div className="stat-card money">
                            <span>Pagos por billetera</span>
                            <strong>{formatoDinero(recaudacion?.pagos_por_billetera)}</strong>
                        </div>

                        <div className="stat-card">
                            <span>Usos de membresía</span>
                            <strong>{recaudacion?.usos_membresia ?? 0}</strong>
                        </div>

                        <div className="stat-card success">
                            <span>Transacciones aprobadas</span>
                            <strong>{recaudacion?.transacciones_aprobadas ?? 0}</strong>
                        </div>

                        <div className="stat-card danger">
                            <span>Transacciones fallidas</span>
                            <strong>{recaudacion?.transacciones_fallidas ?? 0}</strong>
                        </div>
                    </div>

                    {recaudacion?.nota && (
                        <div className="nota-card">{recaudacion.nota}</div>
                    )}
                </div>
            )}

            {tab === "pasos" && (
                <div className="report-section">
                    <h3>Pasos por peaje</h3>

                    <div className="table-card">
                        <table>
                            <thead>
                            <tr>
                                <th>Peaje</th>
                                <th>Ciudad</th>
                                <th>Total pasos</th>
                                <th>Vehículos distintos</th>
                                <th>Pagados</th>
                                <th>Membresía</th>
                                <th>Pendientes</th>
                                <th>Fallidos</th>
                                <th>Alertas</th>
                            </tr>
                            </thead>

                            <tbody>
                            {pasosPorPeaje.length > 0 ? (
                                pasosPorPeaje.map((item) => (
                                    <tr key={item.peaje_id || item.peaje__id}>
                                        <td>{item.peaje_nombre || item.peaje__nombre || "Sin peaje"}</td>
                                        <td>{item.peaje_ciudad || item.peaje__ciudad || "Sin ciudad"}</td>
                                        <td>{item.total_pasos}</td>
                                        <td>{item.vehiculos_distintos}</td>
                                        <td>{item.pagados ?? 0}</td>
                                        <td>{item.membresia ?? 0}</td>
                                        <td>{item.pendientes ?? 0}</td>
                                        <td>{item.fallidos ?? 0}</td>
                                        <td>{item.alertas ?? 0}</td>
                                    </tr>
                                ))
                            ) : (
                                <tr>
                                    <td colSpan="9">No existen registros de pasos por peaje.</td>
                                </tr>
                            )}
                            </tbody>
                        </table>
                    </div>
                </div>
            )}

            {tab === "alertas" && (
                <div className="report-section">
                    <h3>Reporte de alertas</h3>

                    <div className="stats-grid">
                        <div className="stat-card danger">
                            <span>Total alertas</span>
                            <strong>{alertas?.total_alertas ?? 0}</strong>
                        </div>
                    </div>

                    <h4>Alertas por estado</h4>

                    <div className="table-card">
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
                                        <td>{item.estado}</td>
                                        <td>{item.total}</td>
                                    </tr>
                                ))
                            ) : (
                                <tr>
                                    <td colSpan="2">No existen alertas por estado.</td>
                                </tr>
                            )}
                            </tbody>
                        </table>
                    </div>

                    <h4>Alertas por peaje</h4>

                    <div className="table-card">
                        <table>
                            <thead>
                            <tr>
                                <th>Peaje</th>
                                <th>Total alertas</th>
                            </tr>
                            </thead>

                            <tbody>
                            {alertas?.por_peaje?.length > 0 ? (
                                alertas.por_peaje.map((item) => (
                                    <tr key={item.peaje__id || item.peaje_id}>
                                        <td>{item.peaje__nombre || item.peaje_nombre || "Sin peaje"}</td>
                                        <td>{item.total_alertas}</td>
                                    </tr>
                                ))
                            ) : (
                                <tr>
                                    <td colSpan="2">No existen alertas por peaje.</td>
                                </tr>
                            )}
                            </tbody>
                        </table>
                    </div>

                    <h4>Últimas alertas</h4>

                    <div className="table-card">
                        <table>
                            <thead>
                            <tr>
                                <th>ID</th>
                                <th>Placa</th>
                                <th>Peaje</th>
                                <th>Tipo</th>
                                <th>Estado</th>
                                <th>Fecha</th>
                            </tr>
                            </thead>

                            <tbody>
                            {alertas?.ultimas_alertas?.length > 0 ? (
                                alertas.ultimas_alertas.map((item) => (
                                    <tr key={item.id}>
                                        <td>{item.id}</td>
                                        <td>{item.placa || "Sin placa"}</td>
                                        <td>{item.peaje || "Sin peaje"}</td>
                                        <td>{item.tipo_alerta}</td>
                                        <td>{item.estado}</td>
                                        <td>
                                            {item.fecha_hora
                                                ? new Date(item.fecha_hora).toLocaleString()
                                                : "Sin fecha"}
                                        </td>
                                    </tr>
                                ))
                            ) : (
                                <tr>
                                    <td colSpan="6">No existen últimas alertas.</td>
                                </tr>
                            )}
                            </tbody>
                        </table>
                    </div>
                </div>
            )}

            {tab === "vehiculos" && (
                <div className="report-section">
                    <h3>Vehículos detectados</h3>

                    <div className="stats-grid">
                        <div className="stat-card">
                            <span>Total detecciones</span>
                            <strong>{vehiculosDetectados?.total_detecciones ?? 0}</strong>
                        </div>

                        <div className="stat-card">
                            <span>Vehículos distintos</span>
                            <strong>{vehiculosDetectados?.vehiculos_distintos ?? 0}</strong>
                        </div>
                    </div>

                    <h4>Top vehículos detectados</h4>

                    <div className="table-card">
                        <table>
                            <thead>
                            <tr>
                                <th>Placa</th>
                                <th>Total detecciones</th>
                            </tr>
                            </thead>

                            <tbody>
                            {vehiculosDetectados?.top_vehiculos_detectados?.length > 0 ? (
                                vehiculosDetectados.top_vehiculos_detectados.map((item) => (
                                    <tr key={item.placa_detectada}>
                                        <td>{item.placa_detectada}</td>
                                        <td>{item.total_detecciones}</td>
                                    </tr>
                                ))
                            ) : (
                                <tr>
                                    <td colSpan="2">No existen vehículos detectados.</td>
                                </tr>
                            )}
                            </tbody>
                        </table>
                    </div>

                    <h4>Últimas detecciones</h4>

                    <div className="table-card">
                        <table>
                            <thead>
                            <tr>
                                <th>ID</th>
                                <th>Placa</th>
                                <th>Vehículo</th>
                                <th>Peaje</th>
                                <th>Cámara</th>
                                <th>Pago</th>
                                <th>Seguridad</th>
                                <th>Tarifa</th>
                                <th>Fecha</th>
                            </tr>
                            </thead>

                            <tbody>
                            {vehiculosDetectados?.ultimas_detecciones?.length > 0 ? (
                                vehiculosDetectados.ultimas_detecciones.map((item) => (
                                    <tr key={item.id}>
                                        <td>{item.id}</td>
                                        <td>{item.placa_detectada}</td>
                                        <td>{item.vehiculo || "No registrado"}</td>
                                        <td>{item.peaje || "Sin peaje"}</td>
                                        <td>{item.camara || "Sin cámara"}</td>
                                        <td>{item.estado_pago}</td>
                                        <td>{item.estado_seguridad}</td>
                                        <td>{formatoDinero(item.tarifa_aplicada)}</td>
                                        <td>
                                            {item.fecha_hora
                                                ? new Date(item.fecha_hora).toLocaleString()
                                                : "Sin fecha"}
                                        </td>
                                    </tr>
                                ))
                            ) : (
                                <tr>
                                    <td colSpan="9">No existen últimas detecciones.</td>
                                </tr>
                            )}
                            </tbody>
                        </table>
                    </div>
                </div>
            )}

            {tab === "membresias" && (
                <div className="report-section">
                    <h3>Uso de membresías</h3>

                    <div className="stats-grid">
                        <div className="stat-card">
                            <span>Pasos cubiertos por membresía</span>
                            <strong>
                                {usoMembresias?.total_pasos_cubiertos_por_membresia ?? 0}
                            </strong>
                        </div>

                        <div className="stat-card">
                            <span>Membresías activas</span>
                            <strong>{usoMembresias?.membresias_activas ?? 0}</strong>
                        </div>

                        <div className="stat-card">
                            <span>Pases restantes</span>
                            <strong>{usoMembresias?.pases_restantes_totales ?? 0}</strong>
                        </div>
                    </div>

                    <h4>Uso por plan</h4>

                    <div className="table-card">
                        <table>
                            <thead>
                            <tr>
                                <th>Plan</th>
                                <th>Total usos</th>
                            </tr>
                            </thead>

                            <tbody>
                            {usoMembresias?.uso_por_plan?.length > 0 ? (
                                usoMembresias.uso_por_plan.map((item, index) => (
                                    <tr key={index}>
                                        <td>
                                            {item.membresia_utilizada__plan__nombre || "Sin plan"}
                                        </td>
                                        <td>{item.total_usos}</td>
                                    </tr>
                                ))
                            ) : (
                                <tr>
                                    <td colSpan="2">No existen usos de membresía.</td>
                                </tr>
                            )}
                            </tbody>
                        </table>
                    </div>

                    <h4>Membresías activas</h4>

                    <div className="table-card">
                        <table>
                            <thead>
                            <tr>
                                <th>ID</th>
                                <th>Usuario</th>
                                <th>Plan</th>
                                <th>Estado</th>
                                <th>Pases restantes</th>
                                <th>Inicio</th>
                                <th>Fin</th>
                            </tr>
                            </thead>

                            <tbody>
                            {usoMembresias?.membresias?.length > 0 ? (
                                usoMembresias.membresias.map((item) => (
                                    <tr key={item.id}>
                                        <td>{item.id}</td>
                                        <td>{item.usuario}</td>
                                        <td>{item.plan}</td>
                                        <td>{item.estado}</td>
                                        <td>{item.pases_restantes}</td>
                                        <td>{item.fecha_inicio}</td>
                                        <td>
                                            {item.pases_restantes > 0
                                                ? `Agotamiento de pases (${item.pases_restantes} restantes)`
                                                : "Pases agotados"}
                                        </td>
                                    </tr>
                                ))
                            ) : (
                                <tr>
                                    <td colSpan="7">No existen membresías activas.</td>
                                </tr>
                            )}
                            </tbody>
                        </table>
                    </div>
                </div>
            )}
        </div>
    );
}

export default Reportes;
