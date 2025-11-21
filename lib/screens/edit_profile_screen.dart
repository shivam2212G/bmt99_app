import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
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




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
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

              // ------------------ Address ------------------
              TextFormField(
                controller: addressCtrl,
                minLines: 2,
                maxLines: 4,
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
