import React, { useEffect, useState } from "react";
import { db } from "../firebase";
import { collection, onSnapshot } from "firebase/firestore";
import {
  ResponsiveContainer,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  CartesianGrid,
  PieChart,
  Pie,
  Cell,
  Legend,
  LineChart,
  Line,
} from "recharts";

function SystemDashboardPage() {
  const [users, setUsers] = useState([]);
  const [bookings, setBookings] = useState([]);
  const [loading, setLoading] = useState(true);
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    const unsubUsers = onSnapshot(collection(db, "users"), (snap) => {
      setUsers(snap.docs.map((d) => ({ id: d.id, ...d.data() })));
    });

    const unsubBookings = onSnapshot(collection(db, "bookings"), (snap) => {
      setBookings(snap.docs.map((d) => ({ id: d.id, ...d.data() })));
      setLoading(false);
    });

    return () => {
      unsubUsers();
      unsubBookings();
    };
  }, []);

  // ✅ delay 1 khung hình để Recharts có kích thước thật
  useEffect(() => {
    const timer = setTimeout(() => setMounted(true), 400);
    return () => clearTimeout(timer);
  }, []);

  // ===== Tổng hợp dữ liệu =====
  const totalUsers = users.length;
  const totalTutors = users.filter((u) => u.role === "tutor").length;
  const totalStudents = users.filter((u) => u.role === "student").length;

  const totalBookings = bookings.length;
  const completedBookings = bookings.filter(
    (b) => (b.status || "").toLowerCase() === "completed"
  ).length;
  const canceledBookings = bookings.filter(
    (b) => (b.status || "").toLowerCase().includes("cancel")
  ).length;

  const totalRevenue = bookings.reduce((sum, b) => {
    const st = (b.status || "").toLowerCase();
    if (st === "completed" && typeof b.price === "number") {
      return sum + b.price;
    }
    return sum;
  }, 0);

  // ===== Biểu đồ tổng quan =====
  const dataChart = [
    { name: "Người dùng", value: totalUsers },
    { name: "Gia sư", value: totalTutors },
    { name: "Học viên", value: totalStudents },
    { name: "Booking", value: totalBookings },
    { name: "Hoàn thành", value: completedBookings },
    { name: "Bị hủy", value: canceledBookings },
  ];

  // ===== Biểu đồ tròn =====
  const pieData = [
    { name: "Hoàn thành", value: completedBookings },
    { name: "Bị hủy", value: canceledBookings },
    {
      name: "Đang hoạt động",
      value: totalBookings - completedBookings - canceledBookings,
    },
  ];
  const COLORS = ["#4caf50", "#f44336", "#1976d2"];

  // ===== Biểu đồ doanh thu theo tháng =====
  const monthNames = [
    "Th1",
    "Th2",
    "Th3",
    "Th4",
    "Th5",
    "Th6",
    "Th7",
    "Th8",
    "Th9",
    "Th10",
    "Th11",
    "Th12",
  ];

  const monthlyStats = Array(12).fill(0);
  bookings.forEach((b) => {
    if (b.status?.toLowerCase() === "completed" && b.endAt) {
      const d = b.endAt.toDate ? b.endAt.toDate() : new Date(b.endAt);
      const month = d.getMonth();
      monthlyStats[month] += b.price || 0;
    }
  });

  const revenueChart = monthNames.map((m, i) => ({
    month: m,
    revenue: monthlyStats[i],
  }));

  if (loading) return <p className="loading">Đang tải dữ liệu...</p>;
  if (!mounted) return <p className="loading">Đang khởi tạo biểu đồ...</p>;

  // ===== Render giao diện =====
  return (
    <div style={{ width: "100%", minHeight: "100%" }}>
      <h2 style={{ marginBottom: 20 }}>📊 Tổng quan hệ thống</h2>

      {/* ===== Cards thống kê ===== */}
      <div
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(auto-fit, minmax(180px, 1fr))",
          gap: 16,
          marginBottom: 32,
        }}
      >
        <StatCard title="Tổng người dùng" value={totalUsers} color="#1976d2" />
        <StatCard title="Gia sư" value={totalTutors} color="#0288d1" />
        <StatCard title="Học viên" value={totalStudents} color="#43a047" />
        <StatCard title="Tổng Booking" value={totalBookings} color="#6a1b9a" />
        <StatCard title="Hoàn thành" value={completedBookings} color="#2e7d32" />
        <StatCard title="Bị hủy" value={canceledBookings} color="#e53935" />
        <StatCard
          title="Doanh thu (ước tính)"
          value={totalRevenue.toLocaleString("vi-VN") + " ₫"}
          color="#f57c00"
        />
      </div>

      {/* ===== Biểu đồ chính ===== */}
      <div
        style={{
          display: "grid",
          gridTemplateColumns: "2fr 1fr",
          gap: 20,
          flexWrap: "wrap",
          alignItems: "stretch",
          minHeight: "420px",
        }}
      >
        {/* Biểu đồ cột tổng quan */}
        <div
          style={{
            background: "#fff",
            borderRadius: 8,
            boxShadow: "0 1px 3px rgba(0,0,0,0.1)",
            padding: 20,
            display: "flex",
            flexDirection: "column",
            justifyContent: "space-between",
            minHeight: 380,
          }}
        >
          <h3 style={{ marginBottom: 10 }}>Biểu đồ tổng quan</h3>
          <div style={{ flex: 1, minHeight: 320 }}>
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={dataChart}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="name" />
                <YAxis />
                <Tooltip />
                <Bar dataKey="value" fill="#1976d2" radius={[8, 8, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Biểu đồ tròn tỉ lệ */}
        <div
          style={{
            background: "#fff",
            borderRadius: 8,
            boxShadow: "0 1px 3px rgba(0,0,0,0.1)",
            padding: 20,
            display: "flex",
            flexDirection: "column",
            justifyContent: "space-between",
            minHeight: 380,
          }}
        >
          <h3 style={{ marginBottom: 10 }}>Tỉ lệ Booking</h3>
          <div style={{ flex: 1, minHeight: 320 }}>
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={pieData}
                  cx="50%"
                  cy="50%"
                  labelLine={false}
                  outerRadius={120}
                  fill="#8884d8"
                  dataKey="value"
                  label={({ name, percent }) =>
                    `${name} (${(percent * 100).toFixed(0)}%)`
                  }
                >
                  {pieData.map((entry, index) => (
                    <Cell
                      key={`cell-${index}`}
                      fill={COLORS[index % COLORS.length]}
                    />
                  ))}
                </Pie>
                <Legend />
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>

      {/* ===== Biểu đồ doanh thu theo tháng ===== */}
      <div
        style={{
          marginTop: 30,
          background: "#fff",
          borderRadius: 8,
          boxShadow: "0 1px 3px rgba(0,0,0,0.1)",
          padding: 20,
          minHeight: 400,
        }}
      >
        <h3 style={{ marginBottom: 10 }}>📈 Doanh thu theo tháng</h3>
        <div style={{ width: "100%", height: 340 }}>
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={revenueChart}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="month" />
              <YAxis />
              <Tooltip />
              <Line
                type="monotone"
                dataKey="revenue"
                stroke="#f57c00"
                strokeWidth={3}
                dot={{ r: 4 }}
              />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  );
}

// ===== Component Card nhỏ =====
function StatCard({ title, value, color }) {
  return (
    <div
      style={{
        background: "#fff",
        borderRadius: 10,
        padding: "16px 20px",
        boxShadow: "0 1px 3px rgba(0,0,0,0.08)",
      }}
    >
      <p style={{ margin: 0, fontSize: 14, color: "#555" }}>{title}</p>
      <h3 style={{ marginTop: 6, color, fontWeight: "700" }}>{value}</h3>
    </div>
  );
}

export default SystemDashboardPage;
