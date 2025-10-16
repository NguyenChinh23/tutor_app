import 'package:flutter/material.dart';

/// Widget thanh điều hướng dưới đáy app (BottomNavigationBar)
class CommonBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavigationBarItem> items;
  final Color selectedColor;
  final Color unselectedColor;

  const CommonBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.selectedColor = Colors.indigo,
    this.unselectedColor = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: selectedColor,
      unselectedItemColor: unselectedColor,
      showUnselectedLabels: true,
      elevation: 8,
      items: items,
    );
  }
}
