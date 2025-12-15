import 'dart:convert';
import 'dart:math' as math;
import 'package:bmt99_app/screens/wishlist_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import '../baseapi.dart';
import '../services/auth_service.dart';
import '../services/wishlist_service.dart';
import 'cart_screen.dart';
import 'category_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'my_orders_screen.dart';
import 'new_products.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? name;
  final String? email;
  final String? avatar;

  const ProfileScreen({
    super.key,
    this.name,
    this.email,
    this.avatar,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? name;
  String? email;
  String? avatar;
  String? phone;
  String? address;
  bool isLoading = true;

  List<dynamic> wishlistItems = [];
  bool loadingWishlist = true;

  @override
  void initState() {
    super.initState();
    loadUserData();
    loadWishlist();
    loadSettings();
  }

  Future<void> loadWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt("user_id");

    if (userId == null) {
      setState(() => loadingWishlist = false);
      return;
    }

    final data = await WishlistService().getWishlist(userId);

    setState(() {
      wishlistItems = data;
      loadingWishlist = false;
    });
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      name = prefs.getString("name") ?? widget.name ?? "User Name";
      email = prefs.getString("email") ?? widget.email ?? "user@example.com";
      avatar = prefs.getString("avatar") ?? widget.avatar ?? "";
      phone = prefs.getString("phone") ?? "";
      address = prefs.getString("address") ?? "";
      isLoading = false;
    });
  }


  Map<String, dynamic>? settingsData;
  bool loadingSettings = true;

  Future<void> loadSettings() async {
    final url = "${ApiConfig.baseUrl}/api/settings";

    print("Loading settings from: $url");

    try {
      final response = await http.get(Uri.parse(url));

      print("Status code: ${response.statusCode}");
      print("Body: ${response.body}");

      if (response.statusCode == 200) {
        settingsData = jsonDecode(response.body);
        print("Settings loaded: $settingsData");
      } else {
        print("Failed to load settings");
      }
    } catch (e) {
      print("Error loading settings: $e");
    }

    setState(() => loadingSettings = false);
  }

  void showPolicyPopup({
    required BuildContext context,
    required String title,
    required String content,
    required String updatedAt,
    required String email,
    String? phone,
    String? address,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  Colors.green.shade50,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.2),
                  blurRadius: 25,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with green gradient
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.shade800,
                          Colors.green.shade600,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified_user_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content Area
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Content with green border
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.green.shade100,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              content,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.6,
                                color: Colors.black87,
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Contact Info Card with green theme
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.green.shade100,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.contact_page_outlined,
                                      color: Colors.green.shade700,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Contact Information",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Updated At
                                _buildContactItem(
                                  Icons.update_rounded,
                                  "Last Updated",
                                  updatedAt,
                                  Colors.orange.shade700,
                                ),
                                const SizedBox(height: 10),

                                // Email
                                _buildContactItem(
                                  Icons.email_rounded,
                                  "Email",
                                  email,
                                  Colors.green.shade700,
                                ),
                                const SizedBox(height: 10),

                                // Phone (if available)
                                if (phone != null)
                                  Column(
                                    children: [
                                      _buildContactItem(
                                        Icons.phone_rounded,
                                        "Phone",
                                        phone,
                                        Colors.green.shade600,
                                      ),
                                      const SizedBox(height: 10),
                                    ],
                                  ),

                                // Address (if available)
                                if (address != null)
                                  _buildContactItem(
                                    Icons.location_on_rounded,
                                    "Address",
                                    address,
                                    Colors.green.shade800,
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Footer Note with green theme
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.green.shade200,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.shield_outlined,
                                  color: Colors.green.shade700,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    "Your privacy is protected with bank-level security. We never share your data without consent.",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Actions Footer with green buttons
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Row(
                      children: [
                        // Learn More Button (green outline)
                        // Expanded(
                        //   child: OutlinedButton.icon(
                        //     onPressed: () {
                        //       // Add functionality for viewing full policy
                        //       Navigator.pop(context);
                        //     },
                        //     style: OutlinedButton.styleFrom(
                        //       foregroundColor: Colors.green.shade700,
                        //       padding: const EdgeInsets.symmetric(vertical: 14),
                        //       shape: RoundedRectangleBorder(
                        //         borderRadius: BorderRadius.circular(12),
                        //       ),
                        //       side: BorderSide(
                        //         color: Colors.green.shade400,
                        //         width: 1.5,
                        //       ),
                        //     ),
                        //     icon: Icon(
                        //       Icons.description_outlined,
                        //       size: 18,
                        //       color: Colors.green.shade700,
                        //     ),
                        //     label: Text(
                        //       "View Full Policy",
                        //       style: TextStyle(
                        //         fontWeight: FontWeight.w500,
                        //         color: Colors.green.shade700,
                        //       ),
                        //     ),
                        //   ),
                        // ),
                        // const SizedBox(width: 12),

                        // OK Button (green solid)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                              shadowColor: Colors.green.shade200,
                            ),
                            icon: const Icon(Icons.check_circle_outline_rounded,
                                size: 18),
                            label: const Text(
                              "Accept & Continue",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  Future<void> logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.green.shade100,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.green.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              "Logout",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
            ),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthService().signOut();
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeaderShimmer() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          Shimmer(
            child: Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Shimmer(
            child: Container(
              height: 24,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Shimmer(
            child: Container(
              height: 16,
              width: 150,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsShimmer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(
          3,
              (index) => Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Shimmer(
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Shimmer(
                    child: Container(
                      height: 18,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Shimmer(
                    child: Container(
                      height: 12,
                      width: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionsShimmer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: List.generate(
          5,
              (index) => Column(
            children: [
              ListTile(
                leading: Shimmer(
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                title: Shimmer(
                  child: Container(
                    height: 16,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                subtitle: Shimmer(
                  child: Container(
                    height: 12,
                    width: 80,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                trailing: Shimmer(
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              if (index < 4)
                const Divider(height: 1, indent: 20, endIndent: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isLargeScreen = screenWidth > 600;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            // Logo/Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.green.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(34),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadiusGeometry.circular(34),
                child: Image.asset(
                  fit: BoxFit.fitHeight,
                  'assets/shoplogo.png',
                  width: 34,
                  height: 34,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Title
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Profile",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Manage your account",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade600, Colors.green.shade800],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        toolbarHeight: 70,
        actions: [
          // Notification icon
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: IconButton(
              icon: Badge(
                label: const Text('2'),
                backgroundColor: Colors.red.shade400,
                textColor: Colors.white,
                smallSize: 18,
                child: Icon(
                  Iconsax.notification,
                  size: 22,
                  color: Colors.white.withOpacity(0.95),
                ),
              ),
              onPressed: () {},
              padding: const EdgeInsets.all(8),
            ),
          ),
          // Search icon
          // Padding(
          //   padding: const EdgeInsets.only(right: 12, left: 4),
          //   child: IconButton(
          //     icon: Icon(
          //       Icons.search_rounded,
          //       size: 22,
          //       color: Colors.white.withOpacity(0.95),
          //     ),
          //     onPressed: () {},
          //     padding: const EdgeInsets.all(8),
          //   ),
          // ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.shade50,
              Colors.green.shade100,
              Colors.green.shade200,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // PROFILE HEADER SECTION
                if (isLoading)
                  _buildProfileHeaderShimmer()
                else
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              color: Colors.green.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Profile",
                              style: TextStyle(
                                fontSize: isLargeScreen ? 20 : 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.green.shade100,
                                    Colors.blue.shade100,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.green.shade300,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: (avatar != null && avatar!.isNotEmpty)
                                    ? Image.network(
                                  avatar!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Icon(
                                        Icons.person_rounded,
                                        color: Colors.green.shade600,
                                        size: 40,
                                      ),
                                    );
                                  },
                                )
                                    : Center(
                                  child: Icon(
                                    Icons.person_rounded,
                                    color: Colors.green.shade600,
                                    size: 40,
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () async {
                                final prefs = await SharedPreferences.getInstance();
                                final userId = prefs.getInt("user_id");

                                if (userId == null) return;

                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EditProfileScreen(
                                      userId: userId,
                                      name: name,
                                      avatar: avatar,
                                      phone: phone,
                                      address: address,
                                    ),
                                  ),
                                );

                                if (result == true) {
                                  await loadUserData();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text("Profile updated successfully"),
                                      backgroundColor: Colors.green,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.green.shade400,
                                      Colors.green.shade600,
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.edit_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          name ?? "User Name",
                          style: TextStyle(
                            fontSize: isLargeScreen ? 22 : 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email ?? "user@example.com",
                          style: TextStyle(
                            fontSize: isLargeScreen ? 15 : 14,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        if (phone != null && phone!.isNotEmpty)
                          _buildInfoRow(
                            icon: Icons.phone_rounded,
                            label: "Phone",
                            value: phone!,
                          ),
                        if (address != null && address!.isNotEmpty)
                          _buildInfoRow(
                            icon: Icons.location_on_rounded,
                            label: "Address",
                            value: address!,
                            isMultiline: true,
                          ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // STATS SECTION
                if (isLoading)
                  _buildStatsShimmer()
                else
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MyOrdersScreen(),
                                ),
                              );
                            },
                            child: _buildStatItem(
                              icon: Icons.shopping_bag_rounded,
                              value: "12",
                              label: "Orders",
                              color: Colors.blue.shade600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const WishlistScreen(),
                                ),
                              );
                            },
                            child: _buildStatItem(
                              icon: Icons.favorite_rounded,
                              value: wishlistItems.length.toString(),
                              label: "Wishlist",
                              color: Colors.red.shade600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text("Reviews feature coming soon"),
                                  backgroundColor: Colors.amber.shade700,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            child: _buildStatItem(
                              icon: Icons.star_rounded,
                              value: "8",
                              label: "Reviews",
                              color: Colors.amber.shade600,
                            ),
                          ),
                        ),

                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // OPTIONS SECTION
                if (isLoading)
                  _buildOptionsShimmer()
                else
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildOptionItem(
                          icon: Icons.shopping_bag_outlined,
                          title: "My Orders",
                          subtitle: "Check your order history",
                          color: Colors.blue.shade600,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MyOrdersScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1, indent: 20, endIndent: 20),
                        _buildOptionItem(
                          icon: Icons.favorite_outline_rounded,
                          title: "My Wishlist",
                          subtitle: "Your saved favorite items",
                          color: Colors.red.shade600,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const WishlistScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1, indent: 20, endIndent: 20),
                        _buildOptionItem(
                          icon: Icons.notifications_outlined,
                          title: "Notifications",
                          subtitle: "Manage your alerts",
                          color: Colors.purple.shade600,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text("Notifications feature coming soon"),
                                backgroundColor: Colors.purple.shade600,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            );
                          },
                        ),

                        const Divider(height: 1, indent: 20, endIndent: 20),
                        _buildOptionItem(
                          icon: Icons.settings_outlined,
                          title: "Settings",
                          subtitle: "App preferences",
                          color: Colors.grey.shade600,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text("Settings feature coming soon"),
                                backgroundColor: Colors.grey.shade600,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            );
                          },
                        ),

                        const Divider(height: 1, indent: 20, endIndent: 20),

                        _buildOptionItem(
                          icon: Icons.privacy_tip_outlined,
                          title: "Privacy Policy",
                          subtitle: "View our privacy details",
                          color: Colors.green.shade600,
                          onTap: () {
                            print("hello1");
                            if (settingsData == null) return;
                            print("hello2");
                            showPolicyPopup(
                              context: context,
                              title: "Privacy Policy",
                              content: settingsData!["privacy_policy"] ?? "",
                              updatedAt: settingsData!["updated_at"] ?? "",
                              email: settingsData!["shop_email"] ?? "",
                              phone: null,
                              address: null,
                            );
                          },
                        ),

                        Divider(height: 1, indent: 20, endIndent: 20),

                        _buildOptionItem(
                          icon: Icons.info_outline,
                          title: "Disclaimer",
                          subtitle: "Read our disclaimer",
                          color: Colors.orange.shade600,
                          onTap: () {
                            print("hello1");
                            if (settingsData == null) return;
                            print("hello2");
                            showPolicyPopup(
                              context: context,
                              title: "Disclaimer",
                              content: settingsData!["discamer"] ?? "",
                              updatedAt: settingsData!["updated_at"] ?? "",
                              email: settingsData!["shop_email"] ?? "",
                              phone: settingsData!["shop_phone"] ?? "",
                              address: settingsData!["shop_address"] ?? "",
                            );
                          },
                        ),

                        Divider(height: 1, indent: 20, endIndent: 20),
                        _buildOptionItem(
                          icon: Icons.description_outlined,
                          title: "Terms & Conditions",
                          subtitle: "Read terms of use",
                          color: Colors.blue.shade600,
                          onTap: () {
                            if (settingsData == null) return;
                            showPolicyPopup(
                              context: context,
                              title: "Terms & Conditions",
                              content: settingsData!["terms_conditions"] ?? "",
                              updatedAt: settingsData!["updated_at"] ?? "",
                              email: settingsData!["shop_email"] ?? "",
                              phone: settingsData!["shop_phone"] ?? "",
                              address: settingsData!["shop_address"] ?? "",
                            );
                          },
                        ),

                        const Divider(height: 1, indent: 20, endIndent: 20),

                        // NEW: About Us Option
                        _buildOptionItem(
                          icon: Icons.business_rounded,
                          title: "About Us",
                          subtitle: "Learn more about our company",
                          color: Colors.purple.shade600,
                          onTap: () {
                            if (settingsData == null) return;
                            showPolicyPopup(
                              context: context,
                              title: "About Us",
                              content: settingsData!["about_us"] ?? "",
                              updatedAt: settingsData!["updated_at"] ?? "",
                              email: settingsData!["shop_email"] ?? "",
                              phone: settingsData!["shop_phone"] ?? "",
                              address: settingsData!["shop_address"] ?? "",
                            );
                          },
                        ),

                        const Divider(height: 1, indent: 20, endIndent: 20),

                        // NEW: Refund Policy Option
                        _buildOptionItem(
                          icon: Icons.currency_exchange_rounded,
                          title: "Refund Policy",
                          subtitle: "Our refund and return policy",
                          color: Colors.amber.shade700,
                          onTap: () {
                            if (settingsData == null) return;
                            showPolicyPopup(
                              context: context,
                              title: "Refund Policy",
                              content: settingsData!["refund_policy"] ?? "",
                              updatedAt: settingsData!["updated_at"] ?? "",
                              email: settingsData!["shop_email"] ?? "",
                              phone: settingsData!["shop_phone"] ?? "",
                              address: settingsData!["shop_address"] ?? "",
                            );
                          },
                        ),


                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // LOGOUT BUTTON
                if (!isLoading)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: logout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          foregroundColor: Colors.red.shade700,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 24,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.red.shade200, width: 1),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.logout_rounded, size: 20),
                        label: Text(
                          "Logout",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isMultiline = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: Colors.green.shade700,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: isMultiline ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: color,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade900,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: Colors.grey.shade600,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}