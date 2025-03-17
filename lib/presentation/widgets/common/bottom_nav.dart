
// presentation/widgets/common/bottom_nav.dart
import 'package:flutter/material.dart';
import '../../../config/routes.dart';
import '../../../config/theme.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.group_outlined),
          activeIcon: Icon(Icons.group),
          label: 'Groups',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.event_outlined),
          activeIcon: Icon(Icons.event),
          label: 'Events',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.message_outlined),
          activeIcon: Icon(Icons.message),
          label: 'Messages',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.menu_book_outlined),
          activeIcon: Icon(Icons.menu_book),
          label: 'Stories',
        ),
      ],
      onTap: (index) {
        if (index == currentIndex) return;
        
        switch (index) {
          case 0:
            Navigator.of(context).pushReplacementNamed(AppRoutes.home);
            break;
          case 1:
            Navigator.of(context).pushReplacementNamed(AppRoutes.groups);
            break;
          case 2:
            Navigator.of(context).pushReplacementNamed(AppRoutes.events);
            break;
          case 3:
            Navigator.of(context).pushReplacementNamed(AppRoutes.messages);
            break;
          case 4:
            Navigator.of(context).pushReplacementNamed(AppRoutes.stories);
            break;
        }
      },
    );
  }
}