import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../baseapi.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // 👇 Use your WEB CLIENT ID here
    serverClientId: '403760480648-15tn8e24rvk35ef03gqps3gqiukb3rie.apps.googleusercontent.com',
  );

  Future<bool> signInWithGoogle() async {
    try {
      // 1️⃣ Trigger Google Sign-In popup
      final googleUser = await _googleSignIn.signIn();

      // 2️⃣ Get the Google Auth tokens
      final googleAuth = await googleUser?.authentication;

      // 3️⃣ Make sure we have an ID token
      if (googleAuth?.idToken == null) return false;

      // 4️⃣ Send the token to your Laravel API endpoint
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/google-login'),
        headers: {'Accept': 'application/json'},
        body: {'id_token': googleAuth!.idToken}, // 👈 PUT HERE
      );

      // print(response);

      // 5️⃣ Decode and save user data locally
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();

        prefs.setString('app_token', data['token']);
        prefs.setString('name', data['user']['name'] ?? '');
        prefs.setString('email', data['user']['email'] ?? '');
        prefs.setString('avatar', data['user']['avatar'] ?? '');
        // ⭐ MOST IMPORTANT
        prefs.setInt('user_id', data['user']['id']);

        return true;
      } else {
        print('Server Error: ${response.body}');
      }
    } catch (e) {
      print("Error: $e");
    }
    return false;
  }

  // Sign out method
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await _googleSignIn.signOut();
    await prefs.clear();
  }
}
