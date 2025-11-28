import 'dart:io';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../baseapi.dart';

class EditProfileScreen extends StatefulWidget {
  final String? name;
  final String? avatar;
  final String? phone;
  final String? address;
  final int userId;

  const EditProfileScreen({
    super.key,
    required this.userId,
    this.name,
    this.avatar,
    this.phone,
    this.address,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController addressCtrl;

  File? pickedImage;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.name ?? "");
    phoneCtrl = TextEditingController(text: widget.phone ?? "");
    addressCtrl = TextEditingController(text: widget.address ?? "");
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        pickedImage = File(picked.path);
      });
    }
  }

  Future<void> updateProfile() async {
    print("➡ Save button clicked");

    if (!_formKey.currentState!.validate()) {
      print("❌ Validation failed");
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt("user_id");

    print("🆔 USER ID = $userId");

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User ID not found! Login again")),
      );
      return;
    }

    try {
      print("📤 Preparing form data...");

      var dio = Dio();

      FormData formData = FormData.fromMap({
        "name": nameCtrl.text.trim(),
        "phone": phoneCtrl.text.trim(),
        "address": addressCtrl.text.trim(),
        if (pickedImage != null)
          "avatar": await MultipartFile.fromFile(
            pickedImage!.path,
            filename: "avatar.jpg",
          ),
      });

      print("🌐 Sending request to API...");
      print("${ApiConfig.baseUrl}/api/edit-profile/$userId");

      final response = await dio.post(
        "${ApiConfig.baseUrl}/api/edit-profile/$userId",
        data: formData,
        options: Options(
          contentType: "multipart/form-data",
        ),
      );

      print("📥 API Response = ${response.data}");

      if (response.statusCode == 200 && response.data["status"] == true) {
        final data = response.data["data"];

        // Save updated data in SharedPreferences
        await prefs.setString("name", data["name"] ?? "");
        await prefs.setString("phone", data["phone"] ?? "");
        await prefs.setString("address", data["address"] ?? "");
        await prefs.setString("avatar",
            "${ApiConfig.baseUrl}/${data["avatar"] ?? ""}");

        print("✔ Profile updated successfully in SharedPreferences");

        if (!mounted) return;

        Navigator.pop(context, true);  // ← IMPORTANT
      } else {
        print("❌ Error from API: ${response.data}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Something went wrong!")),
        );
      }
    } catch (e) {
      print("🔥 EXCEPTION OCCURRED:");
      print(e);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> getCurrentAddress() async {
    try {
      print("📍 Getting location...");

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print("❌ Location services disabled");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enable location services.")),
        );
        return;
      }

      // Permission check
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print("❌ Permission denied");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Location permission denied")),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print("❌ Permission denied forever");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Location permission permanently denied. Enable it from Settings."),
          ),
        );
        return;
      }

      // Fetch actual location
      print("⏳ Fetching GPS...");
      Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      print("✔ Got location: ${pos.latitude}, ${pos.longitude}");

      // Convert coordinates to address
      print("⏳ Converting to address...");
      List<Placemark> placemarks =
      await placemarkFromCoordinates(pos.latitude, pos.longitude);

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;

        final fullAddress =
            "${p.street}, ${p.subLocality}, ${p.locality}, ${p.administrativeArea}, ${p.postalCode}";

        print("🏠 Address = $fullAddress");

        setState(() {
          addressCtrl.text = fullAddress;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Address updated!")),
        );
      }
    } catch (e) {
      print("🔥 ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // Logo/Icon with gradient
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.edit_rounded,
                color: Colors.green,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),

            // Title with improved styling
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "EDIT PROFILE",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        "Update your information",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.85),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      TweenAnimationBuilder(
                        duration: const Duration(milliseconds: 500),
                        tween: Tween<double>(begin: 0, end: 1),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: 1 + 0.1 * math.sin(value * 2 * math.pi),
                            child: child,
                          );
                        },
                        child: const Text(
                          "✏️",
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
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
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
        toolbarHeight: 80,
        actions: [
          // Save icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.save_rounded, size: 22),
              onPressed: () {},
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(width: 12),

          // Reset icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.restart_alt_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ------------------ Avatar ------------------
              GestureDetector(
                onTap: pickImage,
                child: CircleAvatar(
                  radius: 55,
                  backgroundImage: pickedImage != null
                      ? FileImage(pickedImage!)
                      : (widget.avatar != null && widget.avatar!.isNotEmpty)
                      ? NetworkImage(widget.avatar!)
                      : null,
                  child: pickedImage == null &&
                      (widget.avatar == null || widget.avatar!.isEmpty)
                      ? const Icon(Icons.camera_alt, size: 40, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(height: 20),

              // ------------------ Name ------------------
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: "Name",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? "Enter name" : null,
              ),
              const SizedBox(height: 15),

              // ------------------ Phone ------------------
              TextFormField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Phone",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    print("📌 Use current location button tapped!");
                    getCurrentAddress();
                  },
                  icon: const Icon(Icons.my_location, color: Colors.green),
                  label: const Text(
                    "Use Current Location",
                    style: TextStyle(color: Colors.green),
                  ),
                ),
              ),

              // ------------------ Address ------------------
              TextFormField(
                controller: addressCtrl,
                minLines: 2,
                maxLines: 4,
                readOnly: true,                    // ⛔ Disable keyboard
                showCursor: false,                 // Hide blinking cursor
                enableInteractiveSelection: false, // Disable pasting/selecting
                decoration: const InputDecoration(
                  labelText: "Address",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 25),

              // ------------------ Save Button ------------------
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Save Changes",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
