import 'package:bmt99_app/widget/bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/home_screen.dart';
import '../screens/category_screen.dart';
import '../screens/new_products.dart';
import '../screens/cart_screen.dart';
import '../screens/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  final int initialIndex; // ⭐ Coming from anywhere (Home → Category)

  const MainNavigation({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _currentIndex;

  // Used only for CartScreen refresh
  Key cartKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex; // ⭐ Set default tab
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;

      // Refresh ONLY cart page when visiting cart
      if (index == 3) {
        cartKey = UniqueKey();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const HomeScreen(),
          const CategoryScreen(),
          const NewProducts(),
          CartScreen(key: cartKey), // ⭐ Reload only this one
          FutureBuilder(
            future: loadUserData(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox();
              }
              final user = snapshot.data!;
              return ProfileScreen(
                name: user["name"],
                email: user["email"],
                avatar: user["avatar"],
              );
            },
          ),
        ],
      ),

      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: onTabTapped,
      ),
    );
  }

  // ⭐ Load saved user data (updated after Edit Profile)
  Future<Map<String, dynamic>> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      "name": prefs.getString("name"),
      "email": prefs.getString("email"),
      "avatar": prefs.getString("avatar"),
    };
  }
}
