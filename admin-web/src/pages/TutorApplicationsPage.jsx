import React, { useEffect, useMemo, useState } from "react";
import { collection, onSnapshot, orderBy, query } from "firebase/firestore";
import { db } from "../firebase";
import adminClient from "../api/adminClient";

function TutorApplicationsPage() {
  const [statusFilter, setStatusFilter] = useState("pending");
  const [applications, setApplications] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const q = query(collection(db, "tutorApplications"), orderBy("submittedAt", "desc"));
    const unsub = onSnapshot(q, (snap) => {
      const list = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
      setApplications(list);
      setLoading(false);
    });
    return () => unsub();
  }, []);

  const filteredApps = useMemo(() => {
    if (statusFilter === "all") return applications;
    return applications.filter((a) => a.status === statusFilter);
  }, [applications, statusFilter]);

  const updateStatus = async (id, newStatus) => {
    try {
      await adminClient.patch(`/admin/tutor-applications/${id}/status`, {
        status: newStatus,
      });
    } catch (err) {
      console.error(err);
      alert("Lỗi cập nhật trạng thái hồ sơ");
    }
  };

  return (
    <div style={{ width: "100%" }}>
      <h2 style={{ marginBottom: 16 }}>📋 Quản lý hồ sơ gia sư</h2>

      <div style={{ marginBottom: 16, display: "flex", alignItems: "center", gap: 8 }}>
        <span>Trạng thái:</span>
        <select
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          style={{
            padding: "6px 10px",
            borderRadius: 6,
            border: "1px solid #ccc",
            background: "#fff",
          }}
        >
          <option value="pending">Đang chờ duyệt</option>
          <option value="approved">Đã duyệt</option>
          <option value="rejected">Đã từ chối</option>
          <option value="all">Tất cả</option>
        </select>
      </div>

      {loading && <p>Đang tải...</p>}
      {!loading && filteredApps.length === 0 && <p>Không có hồ sơ nào.</p>}

      <div style={{ display: "grid", gap: 12 }}>
        {filteredApps.map((app) => (
          <div
            key={app.id}
            style={{
              background: "#fff",
              borderRadius: 8,
              padding: "20px 24px",
              boxShadow: "0 1px 4px rgba(0,0,0,0.08)",
              display: "flex",
              alignItems: "center",
              justifyContent: "space-between",
              gap: 16,
            }}
          >
            <div style={{ flex: 1 }}>
              <p><b>Họ tên:</b> {app.fullName || "—"}</p>
              <p><b>Email:</b> {app.email || "—"}</p>
              <p><b>Môn dạy:</b> {app.subject || "—"}</p>
              <p><b>Kinh nghiệm:</b> {app.experience || "—"}</p>
              <p>
                <b>Trạng thái:</b>{" "}
                <span
                  style={{
                    marginLeft: 8,
                    color:
                      app.status === "approved"
                        ? "#2e7d32"
                        : app.status === "rejected"
                        ? "#c62828"
                        : "#555",
                    fontWeight: 500,
                  }}
                >
                  {app.status}
                </span>
              </p>
            </div>

            {app.status === "pending" && (
              <div
                style={{
                  display: "flex",
                  flexDirection: "column",
                  gap: 10,
                  alignItems: "flex-end",
                  minWidth: 100,
                }}
              >
                <button
                  onClick={() => updateStatus(app.id, "approved")}
                  style={{
                    width: "90px",
                    padding: "8px 0",
                    borderRadius: 6,
                    border: "none",
                    background: "#43a047",
                    color: "#fff",
                    fontWeight: 500,
                    cursor: "pointer",
                  }}
                >
                  Duyệt
                </button>
                <button
                  onClick={() => updateStatus(app.id, "rejected")}
                  style={{
                    width: "90px",
                    padding: "8px 0",
                    borderRadius: 6,
                    border: "none",
                    background: "#e53935",
                    color: "#fff",
                    fontWeight: 500,
                    cursor: "pointer",
                  }}
                >
                  Từ chối
                </button>
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}

export default TutorApplicationsPage;
