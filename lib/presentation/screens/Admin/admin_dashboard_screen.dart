import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../provider/auth_provider.dart';
import '../../../config/app_router.dart';
import '../../../config/theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  final _fs = FirebaseFirestore.instance;
  final _repo = AuthRepository();

  String _userRoleFilter = 'all'; // all | student | tutor | admin

  @override
  Widget build(BuildContext context) {
    final reviewerUid = _repo.currentUser?.uid ?? "admin";

    final pages = [
      _buildApplicationsPage(reviewerUid),
      _buildUsersPage(),
      _buildSystemPage(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            tooltip: "Đăng xuất",
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await context.read<AppAuthProvider>().logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRouter.login,
                      (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: "Ứng tuyển",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: "Người dùng",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_customize),
            label: "Hệ thống",
          ),
        ],
      ),
    );
  }

  // ==============================
  //  TAB 0: Duyệt hồ sơ tutor
  // ==============================
  Widget _buildApplicationsPage(String reviewerUid) {
    const statuses = ["pending", "approved", "rejected"];
    const statusLabels = {
      "pending": "Chờ duyệt",
      "approved": "Đã duyệt",
      "rejected": "Từ chối",
    };

    return DefaultTabController(
      length: statuses.length,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: const TabBar(
              indicatorColor: Colors.blue,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              tabs: [
                Tab(text: "Chờ duyệt"),
                Tab(text: "Đã duyệt"),
                Tab(text: "Từ chối"),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: statuses.map((status) {
                return StreamBuilder<
                    QuerySnapshot<Map<String, dynamic>>>(
                  stream: _fs
                      .collection('tutorApplications')
                      .where('status', isEqualTo: status)
                      .orderBy('submittedAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          "Lỗi tải dữ liệu: ${snapshot.error}",
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return Center(
                        child: Text(
                          "📭 Không có hồ sơ ${statusLabels[status]}",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: docs.length,
                      itemBuilder: (context, i) {
                        final d = docs[i].data();
                        final name =
                            d['fullName']?.toString() ?? 'Chưa có tên';
                        final subj =
                            d['subject']?.toString() ?? 'Không rõ';
                        final exp =
                            d['experience']?.toString() ?? '0';
                        final desc =
                            d['description']?.toString() ?? '';
                        final uid = d['uid']?.toString();
                        final appId = d['id']?.toString();
                        final email = d['email']?.toString() ?? '';

                        return Card(
                          margin:
                          const EdgeInsets.symmetric(vertical: 8),
                          elevation: 3,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: AppTheme
                                          .primaryColor
                                          .withOpacity(0.1),
                                      child: Text(
                                        name.isNotEmpty
                                            ? name[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                            color:
                                            Colors.blueAccent),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight:
                                              FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            email,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4),
                                      decoration: BoxDecoration(
                                        color: status == 'pending'
                                            ? Colors.orange
                                            .withOpacity(0.1)
                                            : status == 'approved'
                                            ? Colors.green
                                            .withOpacity(0.1)
                                            : Colors.red
                                            .withOpacity(0.1),
                                        borderRadius:
                                        BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        statusLabels[status]!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: status == 'pending'
                                              ? Colors.orange
                                              : status == 'approved'
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text("Môn dạy: $subj"),
                                Text("Kinh nghiệm: $exp năm"),
                                if (desc.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 4),
                                    child: Text("Mô tả: $desc"),
                                  ),
                                const SizedBox(height: 8),
                                if (d['price'] != null)
                                  Text(
                                      "Giá đề xuất: ${d['price']} đ / giờ"),
                                const SizedBox(height: 12),
                                if (status == 'pending' &&
                                    uid != null &&
                                    appId != null)
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.end,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () async {
                                          try {
                                            await _repo.approveTutor(
                                              uid: uid,
                                              appId: appId,
                                              reviewerUid:
                                              reviewerUid,
                                            );
                                            ScaffoldMessenger.of(
                                                context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    "✅ Đã duyệt hồ sơ của $name ($email)"),
                                                backgroundColor:
                                                Colors.green,
                                              ),
                                            );
                                          } catch (e) {
                                            ScaffoldMessenger.of(
                                                context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    "Lỗi duyệt: $e"),
                                                backgroundColor:
                                                Colors.red,
                                              ),
                                            );
                                          }
                                        },
                                        icon: const Icon(Icons.check),
                                        label: const Text("Duyệt"),
                                        style: ElevatedButton
                                            .styleFrom(
                                          backgroundColor:
                                          Colors.green,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        onPressed: () async {
                                          try {
                                            await _repo.rejectTutor(
                                              appId: appId,
                                              reviewerUid:
                                              reviewerUid,
                                            );
                                            ScaffoldMessenger.of(
                                                context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    "🚫 Đã từ chối hồ sơ"),
                                                backgroundColor:
                                                Colors.red,
                                              ),
                                            );
                                          } catch (e) {
                                            ScaffoldMessenger.of(
                                                context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    "Lỗi từ chối: $e"),
                                                backgroundColor:
                                                Colors.red,
                                              ),
                                            );
                                          }
                                        },
                                        icon: const Icon(Icons.close),
                                        label: const Text("Từ chối"),
                                        style: ElevatedButton
                                            .styleFrom(
                                          backgroundColor:
                                          Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
  //  TAB 1: Quản lý user
  Widget _buildUsersPage() {
    Query<Map<String, dynamic>> query =
    _fs.collection('users').orderBy('email');

    if (_userRoleFilter != 'all') {
      query = query.where('role', isEqualTo: _userRoleFilter);
    }

    return Column(
      children: [
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              _buildRoleFilterChip('all', 'Tất cả'),
              _buildRoleFilterChip('student', 'Học viên'),
              _buildRoleFilterChip('tutor', 'Gia sư'),
              _buildRoleFilterChip('admin', 'Admin'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: query.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    "Lỗi tải user: ${snapshot.error}",
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(
                  child: Text(
                    "Không có người dùng nào.",
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final d = docs[i].data();
                  final email =
                      d['email']?.toString() ?? 'Không có email';
                  final displayName =
                      d['displayName']?.toString() ?? 'Ẩn danh';
                  final role =
                      d['role']?.toString() ?? 'student';
                  final isTutorVerified =
                      d['isTutorVerified'] == true;

                  return Card(
                    margin:
                    const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : '?',
                        ),
                      ),
                      title: Text(displayName),
                      subtitle: Text(email),
                      trailing: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.end,
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: [
                          Container(
                            padding:
                            const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: role == 'admin'
                                  ? Colors.red.withOpacity(0.1)
                                  : role == 'tutor'
                                  ? Colors.purple
                                  .withOpacity(0.1)
                                  : Colors.blue
                                  .withOpacity(0.1),
                              borderRadius:
                              BorderRadius.circular(12),
                            ),
                            child: Text(
                              role.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                color: role == 'admin'
                                    ? Colors.red
                                    : role == 'tutor'
                                    ? Colors.purple
                                    : Colors.blue,
                              ),
                            ),
                          ),
                          if (role == 'tutor')
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 4),
                              child: Text(
                                isTutorVerified
                                    ? 'Đã xác minh'
                                    : 'Chưa xác minh',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isTutorVerified
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRoleFilterChip(String value, String label) {
    final selected = _userRoleFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() {
            _userRoleFilter = value;
          });
        },
      ),
    );
  }
  //  TAB 2: Booking + thống kê
  Widget _buildSystemPage() {
    final bookingsStream = _fs
        .collection('bookings')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();

    final usersStream = _fs.collection('users').snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: usersStream,
      builder: (context, usersSnap) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: bookingsStream,
          builder: (context, bookingsSnap) {
            if (bookingsSnap.connectionState ==
                ConnectionState.waiting ||
                usersSnap.connectionState ==
                    ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final userDocs = usersSnap.data?.docs ?? [];
            final bookingDocs = bookingsSnap.data?.docs ?? [];

            final totalUsers = userDocs.length;
            final totalTutors = userDocs
                .where((d) => d.data()['role'] == 'tutor')
                .length;
            final totalStudents = userDocs
                .where((d) => d.data()['role'] == 'student')
                .length;

            int totalBookings = bookingDocs.length;
            int completed = 0;
            int cancelled = 0;
            int pending = 0;
            num revenue = 0;

            for (var b in bookingDocs) {
              final data = b.data();
              final status =
              (data['status'] ?? '').toString().toLowerCase();
              final price = data['price'] ?? 0;
              if (status == 'done' ||
                  status == 'completed') {
                completed++;
                revenue += (price is num) ? price : 0;
              } else if (status == 'cancelled' ||
                  status == 'canceled') {
                cancelled++;
              } else {
                pending++;
              }
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    "Tổng quan hệ thống",
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildStatCard(
                        title: "Tổng người dùng",
                        value: "$totalUsers",
                        icon: Icons.group,
                        color: Colors.blue,
                      ),
                      _buildStatCard(
                        title: "Gia sư",
                        value: "$totalTutors",
                        icon: Icons.school,
                        color: Colors.purple,
                      ),
                      _buildStatCard(
                        title: "Học viên",
                        value: "$totalStudents",
                        icon: Icons.person,
                        color: Colors.teal,
                      ),
                      _buildStatCard(
                        title: "Tổng booking",
                        value: "$totalBookings",
                        icon: Icons.event_note,
                        color: Colors.indigo,
                      ),
                      _buildStatCard(
                        title: "Hoàn thành",
                        value: "$completed",
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                      _buildStatCard(
                        title: "Bị hủy",
                        value: "$cancelled",
                        icon: Icons.cancel,
                        color: Colors.red,
                      ),
                      _buildStatCard(
                        title: "Đang xử lý",
                        value: "$pending",
                        icon: Icons.pending_actions,
                        color: Colors.orange,
                      ),
                      _buildStatCard(
                        title: "Doanh thu (ước tính)",
                        value: "${revenue.toInt()} đ",
                        icon: Icons.attach_money,
                        color: Colors.amber[800]!,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Booking gần đây",
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (bookingDocs.isEmpty)
                    const Text(
                      "Chưa có booking nào.",
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics:
                      const NeverScrollableScrollPhysics(),
                      itemCount: bookingDocs.length,
                      itemBuilder: (context, i) {
                        final data = bookingDocs[i].data();
                        final studentName =
                            data['studentName']?.toString() ??
                                'Học viên';
                        final tutorName =
                            data['tutorName']?.toString() ??
                                'Gia sư';
                        final status =
                            data['status']?.toString() ??
                                'unknown';
                        final price = data['price'] ?? 0;
                        final mode =
                            data['mode']?.toString() ?? '';
                        final createdAt =
                        (data['createdAt'] as Timestamp?)
                            ?.toDate();

                        Color statusColor = Colors.blueGrey;
                        if (status == 'done' ||
                            status == 'completed') {
                          statusColor = Colors.green;
                        } else if (status == 'cancelled' ||
                            status == 'canceled') {
                          statusColor = Colors.red;
                        } else if (status == 'pending') {
                          statusColor = Colors.orange;
                        }

                        return Card(
                          margin:
                          const EdgeInsets.symmetric(
                              vertical: 6),
                          child: ListTile(
                            title: Text(
                                "$studentName → $tutorName"),
                            subtitle: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                    "Giá: ${price is num ? price.toInt() : price} đ • Hình thức: $mode"),
                                if (createdAt != null)
                                  Text(
                                    "Tạo lúc: $createdAt",
                                    style: const TextStyle(
                                        fontSize: 11),
                                  ),
                              ],
                            ),
                            trailing: Container(
                              padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor
                                    .withOpacity(0.1),
                                borderRadius:
                                BorderRadius.circular(12),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return SizedBox(
      width: 160,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
