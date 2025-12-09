import React, { useEffect, useMemo, useState } from "react";
import { collection, onSnapshot, query } from "firebase/firestore";
import { db } from "../firebase";
import adminClient from "../api/adminClient";

const thStyle = { padding: "10px 8px", textAlign: "center" };
const tdStyle = { padding: "10px 8px", borderBottom: "1px solid #eee" };

function UsersPage() {
  const [roleFilter, setRoleFilter] = useState("all");
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const q = query(collection(db, "users"));
    const unsub = onSnapshot(q, (snap) => {
      const list = snap.docs.map((d) => ({ uid: d.id, ...d.data() }));
      setUsers(list);
      setLoading(false);
    });
    return () => unsub();
  }, []);

  const filteredUsers = useMemo(() => {
    if (roleFilter === "all") return users;
    return users.filter((u) => u.role === roleFilter);
  }, [users, roleFilter]);

  const toggleBlock = async (uid, currentBlocked) => {
    try {
      await adminClient.patch(`/admin/users/${uid}/block`, {
        isBlocked: !currentBlocked,
      });
    } catch (err) {
      console.error(err);
      alert("Lỗi cập nhật trạng thái user");
    }
  };

  return (
    <div style={{ width: "100%" }}>
      <h2 style={{ marginBottom: 16 }}>👤 Quản lý người dùng</h2>

      <div
        style={{
          marginBottom: 16,
          display: "flex",
          alignItems: "center",
          gap: 8,
        }}
      >
        <label>Role: </label>
        <select
          value={roleFilter}
          onChange={(e) => setRoleFilter(e.target.value)}
          style={{ padding: "6px 10px", borderRadius: 6 }}
        >
          <option value="all">Tất cả</option>
          <option value="student">Student</option>
          <option value="tutor">Tutor</option>
          <option value="admin">Admin</option>
        </select>
      </div>

      {loading && <p>Đang tải...</p>}
      {!loading && filteredUsers.length === 0 && <p>Không có user nào.</p>}

      <div
        style={{
          background: "#fff",
          borderRadius: 8,
          boxShadow: "0 1px 3px rgba(0,0,0,0.08)",
          overflowX: "auto",
        }}
      >
        <table
          style={{
            width: "100%",
            borderCollapse: "collapse",
            minWidth: 800,
          }}
        >
          <thead>
            <tr style={{ background: "#1976d2", color: "#fff" }}>
              <th style={thStyle}>Email</th>
              <th style={thStyle}>Tên hiển thị</th>
              <th style={thStyle}>Role</th>
              <th style={thStyle}>Trạng thái</th>
              <th style={thStyle}>Thao tác</th>
            </tr>
          </thead>
          <tbody>
            {filteredUsers.map((u) => (
              <tr key={u.uid} style={{ textAlign: "center" }}>
                <td style={tdStyle}>{u.email}</td>
                <td style={tdStyle}>{u.displayName || "—"}</td>
                <td style={tdStyle}>{u.role}</td>
                <td style={tdStyle}>
                  {u.isBlocked ? (
                    <span style={{ color: "red" }}> Đã khóa</span>
                  ) : (
                    <span style={{ color: "green" }}> Hoạt động</span>
                  )}
                </td>
                <td style={tdStyle}>
                  {u.role !== "admin" && (
                    <button
                      onClick={() => toggleBlock(u.uid, u.isBlocked)}
                      style={{
                        padding: "6px 12px",
                        borderRadius: 6,
                        border: "none",
                        background: u.isBlocked ? "#1976d2" : "#e53935",
                        color: "#fff",
                        cursor: "pointer",
                      }}
                    >
                      {u.isBlocked ? "Mở khóa" : "Khóa tài khoản"}
                    </button>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

export default UsersPage;
