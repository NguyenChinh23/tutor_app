const express = require("express");
const cors = require("cors");
const admin = require("firebase-admin");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const path = require("path");

// ️ SECRET dùng để ký JWT – khi deploy nên chuyển sang biến môi trường
const JWT_SECRET = "CHANGE_THIS_TO_A_LONG_RANDOM_SECRET";

const serviceAccount = require(path.join(__dirname, "firebaseServiceAccount.json"));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

const app = express();
app.use(cors());
app.use(express.json());

//  Helper: Tạo token JWT
function signAdminToken(adminUser) {
  return jwt.sign(
    {
      uid: adminUser.uid,
      email: adminUser.email,
      role: adminUser.role || "admin",
    },
    JWT_SECRET,
    { expiresIn: "7d" }
  );
}
// 2. Middleware: Kiểm tra JWT & quyền admin
function adminAuthMiddleware(req, res, next) {
  const authHeader = req.headers["authorization"];

  if (!authHeader) {
    return res.status(401).json({ message: "Missing Authorization header" });
  }

  // Định dạng: "Bearer token..."
  const parts = authHeader.split(" ");
  if (parts.length !== 2 || parts[0] !== "Bearer") {
    return res.status(401).json({ message: "Invalid Authorization header" });
  }

  const token = parts[1];

  try {
    const decoded = jwt.verify(token, JWT_SECRET);

    if (decoded.role !== "admin") {
      return res.status(403).json({ message: "Forbidden: not an admin" });
    }

    // Gắn thông tin admin vào request
    req.admin = decoded;
    next();
  } catch (err) {
    console.error("JWT verify error:", err);
    return res.status(401).json({ message: "Invalid or expired token" });
  }
}

// 3. API ĐĂNG NHẬP ADMIN
//    POST /api/admin/login
app.post("/api/admin/login", async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res
        .status(400)
        .json({ message: "Vui lòng nhập đầy đủ email và mật khẩu" });
    }

    //  Tìm user có role = "admin" trong collection users (hoặc admins)
    const snap = await db
      .collection("users") // nếu bạn dùng collection khác thì đổi tên ở đây
      .where("email", "==", email)
      .where("role", "==", "admin")
      .limit(1)
      .get();

    if (snap.empty) {
      return res
        .status(401)
        .json({ message: "Email hoặc mật khẩu không đúng (không tìm thấy admin)" });
    }

    const docAdmin = snap.docs[0];
    const adminData = docAdmin.data();
    const uid = docAdmin.id;

    // Kiểm tra mật khẩu: Firestore cần lưu hashedPassword
    const hashedPassword = adminData.hashedPassword;
    if (!hashedPassword) {
      return res
        .status(500)
        .json({ message: "Tài khoản admin chưa được cấu hình mật khẩu." });
    }

    const isMatch = await bcrypt.compare(password, hashedPassword);
    if (!isMatch) {
      return res
        .status(401)
        .json({ message: "Email hoặc mật khẩu không đúng." });
    }

    //  Tạo token
    const token = signAdminToken({
      uid,
      email: adminData.email,
      role: adminData.role,
    });

    return res.json({
      message: "Đăng nhập admin thành công",
      token,
      admin: {
        uid,
        email: adminData.email,
        displayName: adminData.displayName || "Admin",
        role: adminData.role,
      },
    });
  } catch (err) {
    console.error("Admin login error:", err);
    return res.status(500).json({ message: "Lỗi server khi đăng nhập admin" });
  }
});

//  Lấy thông tin admin hiện tại
// GET /api/admin/me
app.get("/api/admin/me", adminAuthMiddleware, async (req, res) => {
  try {
    const { uid } = req.admin;
    const docRef = db.collection("users").doc(uid);
    const docSnap = await docRef.get();

    if (!docSnap.exists) {
      return res.status(404).json({ message: "Admin not found" });
    }

    const data = docSnap.data();
    return res.json({
      uid: docSnap.id,
      email: data.email,
      displayName: data.displayName || "Admin",
      role: data.role,
    });
  } catch (err) {
    console.error("Get admin profile error:", err);
    return res.status(500).json({ message: "Lỗi server" });
  }
});

// 4.2. Lấy danh sách user (student/tutor/admin)
// GET /api/admin/users?role=student|tutor|admin
app.get("/api/admin/users", adminAuthMiddleware, async (req, res) => {
  try {
    const { role } = req.query;

    let ref = db.collection("users");
    if (role) {
      ref = ref.where("role", "==", role);
    }

    const snap = await ref.limit(100).get();
    const users = snap.docs.map((d) => ({
      uid: d.id,
      ...d.data(),
    }));

    return res.json({ users });
  } catch (err) {
    console.error("Get users error:", err);
    return res.status(500).json({ message: "Lỗi server" });
  }
});

//  Khóa / mở khóa user
// PATCH /api/admin/users/:uid/block
// body: { isBlocked: true/false }
app.patch("/api/admin/users/:uid/block", adminAuthMiddleware, async (req, res) => {
  try {
    const { uid } = req.params;
    const { isBlocked } = req.body;

    await db.collection("users").doc(uid).update({
      isBlocked: !!isBlocked,
    });

    return res.json({ message: "Cập nhật trạng thái khóa tài khoản thành công" });
  } catch (err) {
    console.error("Block user error:", err);
    return res.status(500).json({ message: "Lỗi server" });
  }
});

//  Lấy danh sách hồ sơ gia sư theo status
// GET /api/admin/tutor-applications?status=pending|approved|rejected
app.get("/api/admin/tutor-applications", adminAuthMiddleware, async (req, res) => {
  try {
    const { status } = req.query;
    let ref = db.collection("tutorApplications");

    if (status) {
      ref = ref.where("status", "==", status);
    }

    const snap = await ref.limit(100).get();
    const applications = snap.docs.map((d) => ({
      id: d.id,
      ...d.data(),
    }));

    return res.json({ applications });
  } catch (err) {
    console.error("Get tutor applications error:", err);
    return res.status(500).json({ message: "Lỗi server" });
  }
});

//  Duyệt / từ chối hồ sơ gia sư
// PATCH /api/admin/tutor-applications/:id/status
app.patch(
  "/api/admin/tutor-applications/:id/status",
  adminAuthMiddleware,
  async (req, res) => {
    try {
      const { id } = req.params;
      const { status } = req.body;

      if (!["approved", "rejected"].includes(status)) {
        return res.status(400).json({ message: "Trạng thái không hợp lệ" });
      }

      const appRef = db.collection("tutorApplications").doc(id);
      const appSnap = await appRef.get();

      if (!appSnap.exists) {
        return res.status(404).json({ message: "Không tìm thấy hồ sơ" });
      }

      const appData = appSnap.data();

      await appRef.update({
        status,
        reviewedAt: new Date(),
        reviewedBy: req.admin.uid,
      });

      // Nếu duyệt -> cập nhật role & isTutorVerified trong users
      if (status === "approved" && appData.uid) {
        await db.collection("users").doc(appData.uid).update({
          role: "tutor",
          isTutorVerified: true,
        });
      }

      return res.json({ message: `Cập nhật trạng thái hồ sơ: ${status}` });
    } catch (err) {
      console.error("Update tutor application status error:", err);
      return res.status(500).json({ message: "Lỗi server" });
    }
  }
);

// GET /api/admin/bookings?status=accepted|completed|canceled
app.get("/api/admin/bookings", adminAuthMiddleware, async (req, res) => {
  try {
    const { status } = req.query;
    let ref = db.collection("bookings");

    if (status) {
      ref = ref.where("status", "==", status);
    }

    const snap = await ref.limit(100).get();
    const bookings = snap.docs.map((d) => ({
      id: d.id,
      ...d.data(),
    }));

    return res.json({ bookings });
  } catch (err) {
    console.error("Get bookings error:", err);
    return res.status(500).json({ message: "Lỗi server" });
  }
});

// 5. Khởi chạy server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(` Admin backend running on http://localhost:${PORT}`);
});
