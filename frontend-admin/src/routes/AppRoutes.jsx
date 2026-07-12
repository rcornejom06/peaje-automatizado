import { BrowserRouter, Navigate, Route, Routes } from "react-router-dom";

import { isAuthenticated } from "../auth/authService";

import AdminLayout from "../layouts/AdminLayout.jsx";
import Login from "../pages/Login/Login";
import ForgotPassword from "../pages/ForgotPassword/ForgotPassword.jsx";
import Dashboard from "../pages/Dashboard/Dashboard";
import Peajes from "../pages/Peajes/Peajes";
import Camaras from "../pages/Camaras/Camaras";
import Vehiculos from "../pages/Vehiculos/Vehiculos";
import ReconocimientoPlacas from "../pages/ReconocimientoPlacas/ReconocimientoPlacas";
import Alertas from "../pages/Alertas/Alertas";
import Membresias from "../pages/Membresias/Membresias";
import Reportes from "../pages/Reportes/Reportes";
import Usuarios from "../pages/Usuarios/Usuarios";
import Auditoria from "../pages/Auditoria/Auditoria.jsx";

function PrivateRoute({ children }) {
  if (!isAuthenticated()) {
    return <Navigate to="/" replace />;
  }

  return children;
}

function AppRoutes() {
  return (
    <BrowserRouter>
      <Routes>
        {/* Rutas públicas */}
        <Route path="/" element={<Login />} />
        <Route path="/forgot-password" element={<ForgotPassword />} />

        {/* Rutas protegidas */}
        <Route
          element={
            <PrivateRoute>
              <AdminLayout />
            </PrivateRoute>
          }
        >
          <Route path="/dashboard" element={<Dashboard />} />
          <Route path="/peajes" element={<Peajes />} />
          <Route path="/camaras" element={<Camaras />} />
          <Route path="/vehiculos" element={<Vehiculos />} />
          <Route
            path="/reconocimiento-placas"
            element={<ReconocimientoPlacas />}
          />
          <Route path="/alertas" element={<Alertas />} />
          <Route path="/membresias" element={<Membresias />} />
          <Route path="/reportes" element={<Reportes />} />
          <Route path="/usuarios" element={<Usuarios />} />
          <Route path="/auditoria" element={<Auditoria />} />
        </Route>

        {/* Ruta no encontrada */}
        <Route
          path="*"
          element={
            isAuthenticated() ? (
              <Navigate to="/dashboard" replace />
            ) : (
              <Navigate to="/" replace />
            )
          }
        />
      </Routes>
    </BrowserRouter>
  );
}

export default AppRoutes;