import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? name, email, avatar;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('name');
      email = prefs.getString('email');
      avatar = prefs.getString('avatar');
    });
  }

  Future<void> logout() async {
    await AuthService().signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        actions: [
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: Center(
        child: name == null
            ? const CircularProgressIndicator()
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: NetworkImage(avatar ?? ''),
            ),
            const SizedBox(height: 16),
            Text(name!, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(email!, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
