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

/* =======================
   STATUS NORMALIZE
======================= */
const normalizeStatus = (status) => {
  if (!status) return "active";
  if (status === "requested" || status === "accepted") return "active";
  return status;
};

const STATUS_COLOR = {
  active: "#1565c0",
  completed: "#2e7d32",
  cancelled: "#d32f2f",
};

/* =======================
   TIME HELPERS
======================= */
const toDate = (ts) =>
  ts?.toDate ? ts.toDate() : new Date(ts?.seconds * 1000);

const calcEndTime = (startAt, hours) => {
  if (!startAt || !hours) return null;
  const start = toDate(startAt);
  return new Date(start.getTime() + hours * 60 * 60 * 1000);
};

/* =======================
   COMPONENT
======================= */
function BookingsPage() {
  const [bookings, setBookings] = useState([]);
  const [usersMap, setUsersMap] = useState({});
  const [loading, setLoading] = useState(true);

  const [statusFilter, setStatusFilter] = useState("all");
  const [dateFrom, setDateFrom] = useState("");
  const [dateTo, setDateTo] = useState("");

  /* ===== USERS MAP ===== */
  useEffect(() => {
    const fetchUsers = async () => {
      const snap = await getDocs(collection(db, "users"));
      const map = {};
      snap.forEach((d) => {
        const u = d.data();
        map[d.id] = u.displayName || u.email || "(Không rõ)";
      });
      setUsersMap(map);
    };
    fetchUsers();
  }, []);

  /* ===== BOOKINGS REALTIME ===== */
  useEffect(() => {
    const q = query(collection(db, "bookings"), orderBy("createdAt", "desc"));
    const unsub = onSnapshot(q, (snap) => {
      const list = snap.docs.map((d) => ({
        id: d.id,
        ...d.data(),
      }));
      setBookings(list);
      setLoading(false);
    });
    return () => unsub();
  }, []);

  /* ===== FILTERED DATA ===== */
  const filteredBookings = useMemo(() => {
    let list = bookings.map((b) => ({
      ...b,
      status: normalizeStatus(b.status),
    }));

    if (statusFilter !== "all") {
      list = list.filter((b) => b.status === statusFilter);
    }

    if (dateFrom || dateTo) {
      const from = dateFrom ? new Date(dateFrom) : new Date("2000-01-01");
      const to = dateTo
        ? new Date(dateTo + "T23:59:59")
        : new Date("2100-01-01");

      list = list.filter((b) => {
        const d = toDate(b.startAt);
        return d >= from && d <= to;
      });
    }

    return list;
  }, [bookings, statusFilter, dateFrom, dateTo]);

  /* ===== DELETE ===== */
  const handleDelete = async (id) => {
    if (!window.confirm("Bạn có chắc muốn xóa booking này?")) return;
    await deleteDoc(doc(db, "bookings", id));
    alert("Đã xóa booking");
  };

  if (loading) return <p>Đang tải dữ liệu...</p>;

  return (
    <div style={{ padding: 24 }}>
      <h2 style={{ marginBottom: 16 }}>📅 Quản lý Booking</h2>

      {/* ===== FILTER ===== */}
      <div style={{ display: "flex", gap: 12, marginBottom: 16 }}>
        <select
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
        >
          <option value="all">Tất cả</option>
          <option value="active">Đang học</option>
          <option value="completed">Hoàn thành</option>
          <option value="cancelled">Đã hủy</option>
        </select>

        <input
          type="date"
          value={dateFrom}
          onChange={(e) => setDateFrom(e.target.value)}
        />
        <input
          type="date"
          value={dateTo}
          onChange={(e) => setDateTo(e.target.value)}
        />
      </div>

      <p>
        Tổng số: <b>{filteredBookings.length}</b> booking
      </p>

      {/* ===== HEADER ===== */}
      <div
        style={{
          display: "grid",
          gridTemplateColumns:
            "1.2fr 1.2fr 2fr 0.8fr 1fr 1fr 1.4fr 0.8fr",
          padding: "10px 12px",
          fontWeight: 700,
          background: "#f1f3f5",
          borderRadius: 8,
        }}
      >
        <div>Học viên</div>
        <div>Gia sư</div>
        <div>Thời gian</div>
        <div>Thời lượng</div>
        <div>Hình thức</div>
        <div>Loại</div>
        <div>Tiến độ / Giá</div>
        <div>Trạng thái</div>
      </div>

      {/* ===== ROWS ===== */}
      <div
        style={{
          marginTop: 8,
          display: "flex",
          flexDirection: "column",
          gap: 8,
        }}
      >
        {filteredBookings.map((b) => {
          const isPackage = b.packageType && b.packageType !== "single";
          const start = toDate(b.startAt);
          const end = calcEndTime(b.startAt, b.hours);

          return (
            <div
              key={b.id}
              style={{
                display: "grid",
                gridTemplateColumns:
                  "1.2fr 1.2fr 2fr 0.8fr 1fr 1fr 1.4fr 0.8fr",
                padding: "12px",
                background: "#fff",
                borderRadius: 8,
                boxShadow: "0 2px 6px rgba(0,0,0,0.06)",
                alignItems: "center",
              }}
            >
              <div>{usersMap[b.studentId] || b.studentName}</div>
              <div>{usersMap[b.tutorId] || b.tutorName}</div>

              <div>
                {start.toLocaleDateString("vi-VN")}{" "}
                {start.toLocaleTimeString("vi-VN", {
                  hour: "2-digit",
                  minute: "2-digit",
                })}
                {end && (
                  <>
                    {" "}
                    –{" "}
                    {end.toLocaleTimeString("vi-VN", {
                      hour: "2-digit",
                      minute: "2-digit",
                    })}
                  </>
                )}
              </div>

              <div>{b.hours} giờ</div>
              <div>{b.mode}</div>
              <div>{isPackage ? `Gói ${b.packageType}` : "Buổi lẻ"}</div>

              <div>
                {isPackage
                  ? `${b.completedSessions || 0} / ${
                      b.totalSessions || 0
                    } buổi`
                  : `${b.price?.toLocaleString("vi-VN")} ₫`}
              </div>

              <div>
                <div
                  style={{
                    color: STATUS_COLOR[b.status],
                    fontWeight: 600,
                    marginBottom: 4,
                  }}
                >
                  {b.status}
                </div>
                <button
                  onClick={() => handleDelete(b.id)}
                  style={{
                    fontSize: 12,
                    padding: "4px 8px",
                    borderRadius: 6,
                    background: "#e53935",
                    color: "#fff",
                    border: "none",
                    cursor: "pointer",
                  }}
                >
                  🗑 Xóa
                </button>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

export default BookingsPage;
