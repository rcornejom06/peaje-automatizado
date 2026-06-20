import { useNavigate } from "react-router-dom";
import { logout } from "../../auth/authService";

function Dashboard() {
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate("/");
  };

  return (
    <div style={{ padding: "32px", fontFamily: "Arial, sans-serif" }}>
      <h1>Dashboard Administrativo</h1>
      <p>Bienvenido al sistema inteligente de peaje automatizado.</p>

      <button
        onClick={handleLogout}
        style={{
          width: "auto",
          padding: "10px 16px",
          background: "#dc2626",
          color: "white",
          border: "none",
          borderRadius: "8px",
          cursor: "pointer",
        }}
      >
        Cerrar sesión
      </button>
    </div>
  );
}

export default Dashboard;