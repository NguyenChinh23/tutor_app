import React, { useEffect, useMemo, useState } from "react";
import {
  collection,
  onSnapshot,
  orderBy,
  query,
  getDocs,
  deleteDoc,
  doc,
} from "firebase/firestore";
import { db } from "../firebase";

function BookingsPage() {
  const [statusFilter, setStatusFilter] = useState("all");
  const [bookings, setBookings] = useState([]);
  const [usersMap, setUsersMap] = useState({});
  const [loading, setLoading] = useState(true);

  // 🔹 Bộ lọc thời gian
  const [dateFrom, setDateFrom] = useState("");
  const [dateTo, setDateTo] = useState("");

  // 🔹 Lấy danh sách user 1 lần để map tên
  useEffect(() => {
    const fetchUsers = async () => {
      const snap = await getDocs(collection(db, "users"));
      const map = {};
      snap.forEach((doc) => {
        const d = doc.data();
        map[doc.id] = d.displayName || d.email || "(Không rõ)";
      });
      setUsersMap(map);
    };
    fetchUsers();
  }, []);

  // 🔹 Lấy danh sách booking realtime
  useEffect(() => {
    const q = query(collection(db, "bookings"), orderBy("createdAt", "desc"));
    const unsub = onSnapshot(q, (snap) => {
      const list = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
      setBookings(list);
      setLoading(false);
    });
    return () => unsub();
  }, []);

  const normalize = (s = "") => s.toLowerCase().trim();

  // 🔹 Lọc nâng cao (trạng thái + thời gian)
  const filteredBookings = useMemo(() => {
    let list = bookings;

    // 1️⃣ Lọc theo trạng thái
    if (statusFilter !== "all") {
      list = list.filter((b) => {
        const st = normalize(b.status);
        if (statusFilter === "requested") return st.includes("requested") || st.includes("yêu cầu");
        if (statusFilter === "accepted") return st.includes("accepted") || st.includes("chấp nhận");
        if (statusFilter === "completed") return st.includes("completed") || st.includes("hoàn thành");
        if (statusFilter === "canceled") return st.includes("hủy") || st.includes("cancel");
        return true;
      });
    }

    // 2️⃣ Lọc theo thời gian
    if (dateFrom || dateTo) {
      const from = dateFrom ? new Date(dateFrom) : new Date("2000-01-01");
      const to = dateTo ? new Date(dateTo + "T23:59:59") : new Date("2100-01-01");

      list = list.filter((b) => {
        const start = b.startAt?.toDate ? b.startAt.toDate() : new Date(b.startAt?.seconds * 1000);
        return start >= from && start <= to;
      });
    }

    return list;
  }, [bookings, statusFilter, dateFrom, dateTo]);

  const formatTime = (ts) => {
    if (!ts) return "N/A";
    try {
      const d = ts.toDate ? ts.toDate() : new Date(ts.seconds * 1000);
      return d.toLocaleString("vi-VN");
    } catch {
      return "N/A";
    }
  };

  // 🔹 Xóa booking
  const handleDelete = async (id) => {
    if (!window.confirm("Bạn có chắc chắn muốn xóa booking này?")) return;
    try {
      await deleteDoc(doc(db, "bookings", id));
      alert("Đã xóa thành công!");
    } catch (err) {
      console.error(err);
      alert("Lỗi khi xóa booking.");
    }
  };

  if (loading) return <p>Đang tải dữ liệu...</p>;

  return (
    <div style={{ width: "100%", paddingBottom: 50 }}>
      <h2 style={{ marginBottom: 16 }}>📅 Quản lý Booking</h2>

      {/* 🔹 Bộ lọc */}
      <div
        style={{
          display: "flex",
          flexWrap: "wrap",
          gap: 12,
          marginBottom: 20,
          alignItems: "center",
        }}
      >
        <label>Trạng thái: </label>
        <select
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          style={{ padding: "6px 10px", borderRadius: 6 }}
        >
          <option value="all">Tất cả</option>
          <option value="requested">Đã yêu cầu</option>
          <option value="accepted">Đã chấp nhận</option>
          <option value="completed">Hoàn thành</option>
          <option value="canceled">Đã hủy</option>
        </select>

        <label>Từ ngày: </label>
        <input
          type="date"
          value={dateFrom}
          onChange={(e) => setDateFrom(e.target.value)}
          style={{ padding: "6px 10px", borderRadius: 6 }}
        />
        <label>Đến ngày: </label>
        <input
          type="date"
          value={dateTo}
          onChange={(e) => setDateTo(e.target.value)}
          style={{ padding: "6px 10px", borderRadius: 6 }}
        />
      </div>

      <p style={{ color: "#555", marginBottom: 12 }}>
        Tổng số: <b>{filteredBookings.length}</b> kết quả
      </p>

      {filteredBookings.length === 0 && <p>Không có booking nào.</p>}

      <div style={{ display: "grid", gap: 12 }}>
        {filteredBookings.map((b) => (
          <div
            key={b.id}
            style={{
              background: "#fff",
              borderRadius: 8,
              padding: 16,
              boxShadow: "0 1px 3px rgba(0,0,0,0.08)",
              lineHeight: 1.6,
            }}
          >
            <p>
              <b>Học viên:</b> {usersMap[b.studentId] || b.studentName || b.studentId}
            </p>
            <p>
              <b>Gia sư:</b> {usersMap[b.tutorId] || b.tutorName || b.tutorId}
            </p>
            <p>
              <b>Thời gian:</b> {formatTime(b.startAt)} ({b.hours} giờ)
            </p>
            <p>
              <b>Hình thức:</b> {b.mode}
            </p>
            <p>
              <b>Giá:</b>{" "}
              {b.price ? `${b.price.toLocaleString("vi-VN")} ₫` : "N/A"}
            </p>
            <p>
              <b>Trạng thái:</b>{" "}
              <span
                style={{
                  color:
                    normalize(b.status) === "completed"
                      ? "#2e7d32"
                      : normalize(b.status) === "accepted"
                      ? "#1565c0"
                      : normalize(b.status).includes("hủy")
                      ? "#d32f2f"
                      : "#555",
                  fontWeight: 600,
                }}
              >
                {b.status}
              </span>
            </p>

            <button
              onClick={() => handleDelete(b.id)}
              style={{
                marginTop: 10,
                padding: "6px 12px",
                borderRadius: 6,
                background: "#e53935",
                color: "#fff",
                border: "none",
                cursor: "pointer",
              }}
            >
              🗑️ Xóa booking
            </button>
          </div>
        ))}
      </div>
    </div>
  );
}

export default BookingsPage;
