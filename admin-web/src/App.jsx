import React, { useEffect, useState } from "react";
import AdminLogin from "./pages/AdminLogin";
import TutorApplicationsPage from "./pages/TutorApplicationsPage";
import UsersPage from "./pages/UsersPage";
import BookingsPage from "./pages/BookingsPage";
import SystemDashboardPage from "./pages/SystemDashboardPage";
import adminClient from "./api/adminClient";
import "./App.css";

function App() {
  const [admin, setAdmin] = useState(null);
  const [activeTab, setActiveTab] = useState("dashboard");
  const [checking, setChecking] = useState(true);

  useEffect(() => {
    const token = localStorage.getItem("adminToken");
    const stored = localStorage.getItem("adminInfo");
    if (!token || !stored) return setChecking(false);

    (async () => {
      try {
        const res = await adminClient.get("/admin/me");
        setAdmin(res.data);
      } catch {
        localStorage.removeItem("adminToken");
        localStorage.removeItem("adminInfo");
      } finally {
        setChecking(false);
      }
    })();
  }, []);

  if (checking) return <div>Đang kiểm tra phiên đăng nhập...</div>;
  if (!admin) return <AdminLogin onLogin={(info) => setAdmin(info)} />;

  return (
    <div className="layout">
      {/* HEADER */}
      <header className="header">
        <div className="header-left">
          <b className="logo">Bảng quản trị hệ thống</b>
        </div>
        <button
          className="logout-btn"
          onClick={() => {
            localStorage.clear();
            setAdmin(null);
          }}
        >
          Đăng xuất
        </button>
      </header>

      {/* BODY */}
      <div className="main">
        {/* SIDEBAR */}
        <aside className="sidebar">
          <div className="menu-title">Chức năng</div>
          {[
            { key: "dashboard", label: "Tổng quan" },
            { key: "tutor", label: "Hồ sơ gia sư" },
            { key: "users", label: "Người dùng" },
            { key: "bookings", label: "Booking" },
          ].map((item) => (
            <button
              key={item.key}
              onClick={() => setActiveTab(item.key)}
              className={`menu-btn ${
                activeTab === item.key ? "active" : ""
              }`}
            >
              {item.label}
            </button>
          ))}
        </aside>

        {/* MAIN CONTENT */}
        <main className="main-content">
          {activeTab === "dashboard" && <SystemDashboardPage />}
          {activeTab === "tutor" && <TutorApplicationsPage />}
          {activeTab === "users" && <UsersPage />}
          {activeTab === "bookings" && <BookingsPage />}
        </main>
      </div>
    </div>
  );
}

export default App;
