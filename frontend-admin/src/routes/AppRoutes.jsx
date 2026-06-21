import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";

import Login from "../pages/Login/Login";
import Dashboard from "../pages/Dashboard/Dashboard";
import Peajes from "../pages/Peajes/Peajes";
import Camaras from "../pages/Camaras/Camaras";
import Vehiculos from "../pages/Vehiculos/Vehiculos";
import Alertas from "../pages/Alertas/Alertas";
import Membresias from "../pages/Membresias/Membresias";
import Reportes from "../pages/Reportes/Reportes";
import Usuarios from "../pages/Usuarios/Usuarios";

import AdminLayout from "../layouts/AdminLayout.jsx"

import { isAuthenticated } from "../auth/authService";

function PrivateRoute({ children }) {
  if (!isAuthenticated()) {
    return <Navigate to="/" />;
  }

  return children;
}

function AppRoutes() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Login />} />

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
          <Route path="/alertas" element={<Alertas />} />
          <Route path="/membresias" element={<Membresias />} />
          <Route path="/reportes" element={<Reportes />} />
          <Route path="/usuarios" element={<Usuarios />} />
        </Route>
      </Routes>
    </BrowserRouter>
  );
}

export default AppRoutes;