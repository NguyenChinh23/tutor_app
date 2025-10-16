import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutor_app/config/theme.dart';
import 'package:tutor_app/presentation/provider/auth_provider.dart';
import 'package:tutor_app/presentation/provider/tutor_provider.dart';
import 'package:tutor_app/presentation/screens/common/widgets/tutor_card.dart';
import 'package:tutor_app/presentation/screens/chat/chat_list_screen.dart';
import 'package:tutor_app/presentation/screens/profile/student_profile_screen.dart';
import 'package:tutor_app/presentation/screens/student/filter_screen.dart';
import 'package:tutor_app/presentation/screens/student/tutor_search_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _selectedIndex = 0;
  List<String> selectedSubjects = [];
  double minPrice = 0;
  double maxPrice = 100;
  double minRating = 0;

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
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_outlined), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  // 🏠 Home
  Widget _buildHome(BuildContext context, user, TutorProvider tutorProvider) {
    final tutors = tutorProvider.tutors.where((tutor) {
      final subjectMatch = selectedSubjects.isEmpty ||
          selectedSubjects.any((sub) =>
              tutor.subject.toLowerCase().contains(sub.toLowerCase()));
      final priceMatch = tutor.price >= minPrice && tutor.price <= maxPrice;
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
                offset: Offset(0, 2),
              )
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundImage: (user?.avatarUrl != null &&
                        user!.avatarUrl!.isNotEmpty)
                        ? NetworkImage(user.avatarUrl!)
                        : const AssetImage('assets/tutor1.png')
                    as ImageProvider,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Welcome,",
                            style:
                            TextStyle(color: Colors.white70, fontSize: 14)),
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
                  IconButton(
                    icon: const Icon(Icons.filter_alt, color: Colors.white),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const FilterTutorsScreen()),
                      );
                      if (result != null) {
                        setState(() {
                          selectedSubjects =
                          List<String>.from(result["subjects"] ?? []);
                          minPrice = result["minPrice"] ?? 0;
                          maxPrice = result["maxPrice"] ?? 100;
                          minRating = result["minRating"] ?? 0;
                        });
                      }
                    },
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
        onRefresh: () async => setState(() {}),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔍 Thanh tìm kiếm
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const TutorSearchScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black12.withOpacity(0.08),
                          blurRadius: 5)
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.search, color: Colors.grey),
                      SizedBox(width: 10),
                      Text("Search for tutors or subjects...",
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                "Popular Subjects",
                style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
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

              const Text(
                "Top Tutors",
                style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (tutors.isEmpty)
                const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 50),
                      child: Text("No tutors found with these filters."),
                    ))
              else
                Column(
                  children: tutors
                      .map((tutor) => AnimatedOpacity(
                    duration: const Duration(milliseconds: 400),
                    opacity: 1,
                    child: TutorCard(
                      tutor: tutor,
                      onBook: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                              Text("Booked ${tutor.name}!")),
                        );
                      },
                    ),
                  ))
                      .toList(),
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 Subject Chip có icon và hiệu ứng chọn
  Widget _subjectChip(String title, IconData icon) {
    final isSelected = selectedSubjects.contains(title) ||
        (title == "All" && selectedSubjects.isEmpty);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (title == "All") {
            selectedSubjects.clear();
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.05),
              blurRadius: 3,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18, color: isSelected ? Colors.white : AppTheme.primaryColor),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
