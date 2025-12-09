// src/pages/AdminLogin.jsx
import React, { useState } from "react";
import adminClient from "../api/adminClient";

function AdminLogin({ onLogin }) {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError("");
    setLoading(true);

    try {
      const res = await adminClient.post("/admin/login", { email, password });
      const { token, admin } = res.data;

      localStorage.setItem("adminToken", token);
      localStorage.setItem("adminInfo", JSON.stringify(admin));

      onLogin(admin);
    } catch (err) {
      console.error(err);
      setError(
        err.response?.data?.message || "Có lỗi xảy ra, vui lòng thử lại."
      );
    } finally {
      setLoading(false);
    }
  };

  return (
    <div
      style={{
        minHeight: "100vh",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        background: "#f0f2f5",
      }}
    >
      <form
        onSubmit={handleSubmit}
        autoComplete="off"
        style={{
          background: "#fff",
          padding: "24px 32px",
          borderRadius: "12px",
          boxShadow: "0 4px 16px rgba(0,0,0,0.08)",
          width: "100%",
          maxWidth: "420px",
        }}
      >
        <h2 style={{ marginBottom: "16px", textAlign: "center" }}>
          Admin Login
        </h2>

        <div style={{ marginBottom: "12px" }}>
          <label style={{ fontSize: 14 }}>Email</label>
          <input
            type="email"
            placeholder="Nhập email admin"
            autoComplete="new-email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            style={{
              width: "100%",
              padding: "10px 12px",
              borderRadius: "8px",
              border: "1px solid #ddd",
              marginTop: "4px",
            }}
          />
        </div>

        <div style={{ marginBottom: "12px" }}>
          <label style={{ fontSize: 14 }}>Mật khẩu</label>
          <input
            type="password"
            placeholder="Nhập mật khẩu"
            autoComplete="new-password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            style={{
              width: "100%",
              padding: "10px 12px",
              borderRadius: "8px",
              border: "1px solid #ddd",
              marginTop: "4px",
            }}
          />
        </div>

        {error && (
          <div
            style={{
              color: "red",
              fontSize: 13,
              marginBottom: 8,
              textAlign: "center",
            }}
          >
            {error}
          </div>
        )}

        <button
          type="submit"
          disabled={loading}
          style={{
            width: "100%",
            padding: "10px 0",
            borderRadius: "8px",
            border: "none",
            background: loading ? "#9e9e9e" : "#1976d2",
            color: "#fff",
            fontWeight: 600,
            cursor: loading ? "not-allowed" : "pointer",
          }}
        >
          {loading ? "Đang đăng nhập..." : "Đăng nhập"}
        </button>
      </form>
    </div>
  );
}

export default AdminLogin;
