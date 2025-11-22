import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tutor_app/config/theme.dart';
import 'package:tutor_app/presentation/provider/auth_provider.dart';
import 'package:tutor_app/presentation/provider/tutor_provider.dart';
import 'package:tutor_app/presentation/screens/common/widgets/tutor_card.dart';
import 'package:tutor_app/presentation/screens/chat/chat_list_screen.dart';
import 'package:tutor_app/presentation/screens/profile/student_profile_screen.dart';
import 'package:tutor_app/presentation/screens/student/tutor_search_screen.dart';
import 'package:tutor_app/presentation/screens/student/filter_bottom_sheet.dart';
import 'package:tutor_app/presentation/screens/student/tutor_detail_screen.dart';

String fmtVnd(num v) => NumberFormat.currency(
  locale: 'vi_VN',
  symbol: '₫',
  decimalDigits: 0,
).format(v);

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _selectedIndex = 0;
  List<String> selectedSubjects = [];

  double? minPrice;
  double? maxPrice;
  double minRating = 0;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) context.read<TutorProvider>().refresh();
    });
  }

  /// avatar user: hỗ trợ http + base64 + fallback asset
  ImageProvider _buildUserAvatar(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return const AssetImage('assets/avatar.png');
    }

    try {
      if (avatarUrl.startsWith('http')) {
        return NetworkImage(avatarUrl);
      } else {
        final bytes = base64Decode(avatarUrl);
        return MemoryImage(bytes);
      }
    } catch (e) {
      debugPrint('User avatar decode error: $e');
      return const AssetImage('assets/avatar.png');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final tutorProvider = context.watch<TutorProvider>();
    final user = auth.user;

    final List<Widget> screens = [
      _buildHome(context, user, tutorProvider),
      const ChatListScreen(),
      const StudentProfileScreen(),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_outlined), label: 'Chat'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildHome(
      BuildContext context, user, TutorProvider tutorProvider) {
    final tutors = tutorProvider.tutors.where((tutor) {
      final subjectMatch = selectedSubjects.isEmpty ||
          selectedSubjects.any((sub) =>
              tutor.subject.toLowerCase().contains(sub.toLowerCase()));

      final priceMatch = (minPrice == null || tutor.price >= minPrice!) &&
          (maxPrice == null || tutor.price <= maxPrice!);

      final ratingMatch = tutor.rating >= minRating;

      return subjectMatch && priceMatch && ratingMatch;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryColor, Colors.indigoAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2)),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundImage:
                    _buildUserAvatar(user?.avatarUrl as String?),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Welcome,",
                            style: TextStyle(
                                color: Colors.white70, fontSize: 14)),
                        Text(
                          user?.displayName ?? "Student 👋",
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: tutorProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () async =>
            context.read<TutorProvider>().refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _searchAndFilterBar(context),
              const SizedBox(height: 24),
              const Text("Popular Subjects",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SizedBox(
                height: 45,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _subjectChip("All", Icons.all_inclusive),
                    _subjectChip("Math", Icons.calculate),
                    _subjectChip("English", Icons.language),
                    _subjectChip("Physics", Icons.science),
                    _subjectChip("Chemistry", Icons.biotech),
                    _subjectChip("IELTS", Icons.school),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              const Text("Top Tutors",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (tutors.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 50),
                    child: Text("No tutors found with these filters."),
                  ),
                )
              else
                Column(
                  children: tutors
                      .map(
                        (tutor) => AnimatedOpacity(
                      duration:
                      const Duration(milliseconds: 400),
                      opacity: 1,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TutorDetailScreen(
                                tutor: tutor,
                                autoOpenBook: false,
                              ),
                            ),
                          );
                        },
                        child: TutorCard(
                          tutor: tutor,
                          onBook: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    TutorDetailScreen(
                                      tutor: tutor,
                                      autoOpenBook: true,
                                    ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  )
                      .toList(),
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openFilter() async {
    final tutors = context.read<TutorProvider>().tutors;
    final double priceMaxLimit = tutors.isEmpty
        ? 1_000_000
        : tutors
        .map((t) => (t.price as num).toDouble())
        .reduce(math.max);

    final result = await showFilterBottomSheet(
      context,
      initialSubjects: selectedSubjects,
      initialMinPrice: minPrice ?? 0,
      initialMaxPrice: maxPrice ?? priceMaxLimit,
      initialMinRating: minRating,
      priceMaxLimit: priceMaxLimit,
    );

    if (!mounted || result == null) return;

    setState(() {
      selectedSubjects =
      List<String>.from(result["subjects"] ?? []);
      minPrice = (result["minPrice"] as num?)?.toDouble() ?? 0;
      maxPrice =
          (result["maxPrice"] as num?)?.toDouble() ?? priceMaxLimit;
      minRating =
          (result["minRating"] as num?)?.toDouble() ?? 0;
    });
  }

  Widget _searchAndFilterBar(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const TutorSearchScreen()),
              );
            },
            child: Container(
              height: 48,
              padding:
              const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.search, color: Colors.grey),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Search for tutors or subjects...",
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: _openFilter,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black12.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Icon(Icons.tune,
                color: AppTheme.primaryColor),
          ),
        ),
      ],
    );
  }

  Widget _subjectChip(String title, IconData icon) {
    final isSelected = selectedSubjects.contains(title) ||
        (title == "All" && selectedSubjects.isEmpty);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (title == "All") {
            selectedSubjects.clear();
            minPrice = null;
            maxPrice = null;
            minRating = 0;
          } else if (isSelected) {
            selectedSubjects.remove(title);
          } else {
            selectedSubjects.add(title);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black12.withOpacity(0.05),
                blurRadius: 3),
          ],
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color: isSelected
                    ? Colors.white
                    : AppTheme.primaryColor),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : AppTheme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
