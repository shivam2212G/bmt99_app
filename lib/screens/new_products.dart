import 'package:bmt99_app/screens/category_screen.dart';
import 'package:bmt99_app/screens/profile_screen.dart';
import 'package:flutter/material.dart';

import '../widget/bottom_navigation_bar.dart';
import 'cart_screen.dart';
import 'home_screen.dart';

class NewProducts extends StatefulWidget {
  const NewProducts({super.key});

  @override
  State<NewProducts> createState() => _NewProductsState();
}

class _NewProductsState extends State<NewProducts> {
  int _currentIndex = 2;

  void _onItemTapped(int index) {
    switch (index) {
      case 0: Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen())); break;
      case 1: Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CategoryScreen())); break;
      case 2: break;
      case 3: Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CartScreen())); break;
      case 4: Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProfileScreen())); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Text("NewProducts"),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
