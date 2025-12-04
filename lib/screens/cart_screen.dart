import 'dart:convert';
import 'dart:math' as math;

import 'package:bmt99_app/screens/profile_screen.dart';
import 'package:bmt99_app/widget/MainNavigation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get_connect/http/src/multipart/form_data.dart' hide FormData;
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

import '../services/cart_service.dart';
import '../baseapi.dart';
import '../services/payment_service.dart';
import '../widget/bottom_navigation_bar.dart';
import '../model/product_model.dart';
import 'order_success_screen.dart';
import 'product_details_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:dio/dio.dart';

import 'category_screen.dart';
import 'home_screen.dart';
import 'new_products.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  CartScreenState createState() => CartScreenState();
}

class CartScreenState extends State<CartScreen> {
  String? name, email, avatar;

  bool loading = true;

  List<dynamic> cartItems = [];
  int count = 0;
  Map<int, int> itemQuantities = {}; // Track quantities locally

  String selectedAddress = ""; // ⭐ FIX HERE
  String selectedPhone = "";

  late PaymentService paymentService;

  @override
  void initState() {
    super.initState();
    paymentService = PaymentService(
      onPaymentSuccess: _onPaymentSuccess,
      onPaymentFailed: _onPaymentFailed,
    );
    loadCart();
    loadUserData();
  }

  @override
  void dispose() {
    paymentService.dispose();
    super.dispose();
  }

  Future<String?> _getCurrentAddress() async {
    try {
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Location permission denied")),
          );
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Location permission permanently denied. Enable from settings.",
            ),
          ),
        );
        return null;
      }

      // Get current position
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address from coordinates
      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );

      if (placemarks.isEmpty) return null;

      final p = placemarks.first;

      final address =
          "${p.name ?? ""}, ${p.subLocality ?? ""}, ${p.locality ?? ""}, "
          "${p.administrativeArea ?? ""}, ${p.postalCode ?? ""}";

      return address;
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to get location: $e")));
      return null;
    }
  }

  Future<bool> _saveAddressAndPhone(String phone, String address) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt("user_id");

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login required")),
        );
        return false;
      }

      final dio = Dio();

      final formData = FormData.fromMap({
        "phone": phone,
        "address": address,
        // name & avatar optional, backend will ignore if not sent
      });

      final response = await dio.post(
        "${ApiConfig.baseUrl}/api/edit-profile/$userId",
        data: formData,
        options: Options(contentType: "multipart/form-data"),
      );

      print("EDIT PROFILE FROM CART: ${response.data}");

      if (response.statusCode == 200 && response.data["status"] == true) {
        final data = response.data["data"];

        await prefs.setString("phone", data["phone"] ?? "");
        await prefs.setString("address", data["address"] ?? "");

        // Update in memory too
        selectedPhone = data["phone"] ?? "";
        selectedAddress = data["address"] ?? "";

        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update profile")),
        );
        return false;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating profile: $e")),
      );
      return false;
    }
  }


  // 🎉 PAYMENT SUCCESS
  void _onPaymentSuccess(String paymentId) async {
    print("PAYMENT SUCCESS: $paymentId");

    await placeOrder(
      paymentMethod: 1, // Online Payment
      transactionId: paymentId,
      paidAmount: getTotalPrice().toInt(),
    );
  }

  // ❌ PAYMENT FAILED
  void _onPaymentFailed(String? message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Payment Failed: $message")));
  }

  Future<void> placeOrder({
    required int paymentMethod, // 0 = COD, 1 = Online
    String? transactionId,
    int? paidAmount,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt("user_id");

    final url = Uri.parse("${ApiConfig.baseUrl}/api/place-order");

    final body = {
      "user_id": userId.toString(),
      "payment_method": paymentMethod.toString(),
      "address": selectedAddress, // From popup
      "phone": selectedPhone,
    };

    if (paymentMethod == 1) {
      body["transaction_id"] = transactionId!;
      body["paid_amount"] = paidAmount.toString();
    }

    print("ORDER REQ: $body");

    final response = await http.post(url, body: body);
    print("ORDER RES: ${response.body}");

    if (response.statusCode == 201) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OrderSuccessScreen()),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Order failed")));
    }
  }

  void showPaymentDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final savedAddress = prefs.getString("address") ?? "";
    final savedPhone = prefs.getString("phone") ?? "";

    String selectedMethod = "cod"; // Default

    // Local mutable copies for the bottom sheet
    String address = savedAddress;
    String phone = savedPhone;
    bool isSaving = false;

    // Also store in class-level variables (used by placeOrder())
    selectedAddress = address;
    selectedPhone = phone;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bool isMissing = address.trim().isEmpty || phone.trim().isEmpty;
            final bool canConfirm = !isMissing && !isSaving;

            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                color: Colors.green.shade50
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Confirm Order",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isMissing)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: const Text(
                              "Address & Phone required",
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ---------------- ADDRESS ----------------
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Delivery Address",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: address.isEmpty
                              ? Colors.red.shade200
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              address.isEmpty
                                  ? "No address set. Tap below to use current location."
                                  : address,
                              style: TextStyle(
                                fontSize: 13,
                                color: address.isEmpty
                                    ? Colors.red.shade400
                                    : Colors.grey.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: isSaving
                            ? null
                            : () async {
                          setModalState(() => isSaving = true);
                          final locAddress = await _getCurrentAddress();
                          setModalState(() => isSaving = false);

                          if (locAddress != null) {
                            setModalState(() {
                              address = locAddress;
                              selectedAddress = locAddress;
                            });
                          }
                        },
                        icon: const Icon(Icons.my_location, size: 18),
                        label: Text(
                          isSaving ? "Getting location..." : "Use current location",
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ---------------- PHONE ----------------
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Phone Number",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    TextField(
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.phone),
                        hintText: "Enter phone number",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: phone.isEmpty
                                ? Colors.red.shade200
                                : Colors.grey.shade300,
                          ),
                        ),
                      ),
                      onChanged: (val) {
                        setModalState(() {
                          phone = val;
                          selectedPhone = val;
                        });
                      },
                      controller: TextEditingController.fromValue(
                        TextEditingValue(
                          text: phone,
                          selection: TextSelection.collapsed(
                            offset: phone.length,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ---------------- PAYMENT METHOD ----------------
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Payment Method",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),

                    RadioListTile(
                      value: "cod",
                      groupValue: selectedMethod,
                      title: const Text("Cash on Delivery"),
                      onChanged: (v) =>
                          setModalState(() => selectedMethod = v.toString()),
                    ),

                    RadioListTile(
                      value: "online",
                      groupValue: selectedMethod,
                      title: const Text("Online Payment (Razorpay)"),
                      onChanged: (v) =>
                          setModalState(() => selectedMethod = v.toString()),
                    ),

                    const SizedBox(height: 10),

                    // ---------------- CONFIRM BUTTON ----------------
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: !canConfirm
                            ? null
                            : () async {
                          // 1) Save phone + address via edit-profile
                          setModalState(() => isSaving = true);
                          final ok =
                          await _saveAddressAndPhone(phone, address);
                          setModalState(() => isSaving = false);

                          if (!ok) return;

                          // Close bottom sheet
                          Navigator.pop(context);

                          // 2) Proceed to payment / COD
                          if (selectedMethod == "cod") {
                            await placeOrder(
                              paymentMethod: 0,
                              transactionId: null,
                              paidAmount: null,
                            );
                          } else {
                            startOnlinePayment();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canConfirm
                              ? Colors.green.shade600
                              : Colors.grey.shade400,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isSaving
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Text(
                          "Confirm Order",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }


  void startOnlinePayment() async {
    final prefs = await SharedPreferences.getInstance();

    paymentService.openCheckout(
      amount: (getTotalPrice() * 100).toInt(), // to paise
      userEmail: prefs.getString('email') ?? "",
      userName: prefs.getString('name') ?? "User",
      userPhone: prefs.getString('phone') ?? "",
    );
  }

  Future<void> updateAllCartBeforeOrder() async {
    final prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt("user_id");
    if (userId == null) return;

    List<Map<String, dynamic>> items = [];

    itemQuantities.forEach((cartId, qty) {
      items.add({"cart_id": cartId, "quantity": qty});
    });

    await CartService().updateAllCartItems(userId, items);
  }

  Future<void> loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt("user_id");

    if (userId == null) {
      setState(() => loading = false);
      return;
    }

    final data = await CartService().getCart(userId);

    setState(() {
      cartItems = data["items"];
      count = data["count"];

      // Initialize quantities (assuming backend doesn't provide quantity)
      for (var item in cartItems) {
        final cartId = item["cart_id"];
        itemQuantities[cartId] =
            item["quantity"] ?? 1; // ⭐ load correct quantity
      }

      loading = false;
    });
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('name');
      email = prefs.getString('email');
      avatar = prefs.getString('avatar');
    });
  }

  Future<void> removeItem(int cartId) async {
    bool success = await CartService().removeCartItem(cartId);

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Removed from cart")));

      loadCart(); // refresh list
    }
  }

  void updateQuantity(int cartId, int newQuantity) {
    if (newQuantity < 1) return;

    setState(() {
      itemQuantities[cartId] = newQuantity;
    });

    // TODO: Update quantity in backend when API is ready
    // CartService().updateCartQuantity(cartId, newQuantity);
  }

  double getTotalPrice() {
    double total = 0;
    for (var item in cartItems) {
      final product = ProductModel.fromJson(item["product"]);
      final quantity = itemQuantities[item["cart_id"]] ?? 1;
      total += (product.productPrice * quantity);
    }
    return total;
  }

  double getTotalMrp() {
    double total = 0;
    for (var item in cartItems) {
      final product = ProductModel.fromJson(item["product"]);
      final quantity = itemQuantities[item["cart_id"]] ?? 1;
      total += (product.productMrp * quantity);
    }
    return total;
  }

  double getTotalDiscount() {
    return getTotalMrp() - getTotalPrice();
  }

  // Shimmer effect for cart items
  Widget _buildCartItemShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 4, // Show 4 shimmer items
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Shimmer Image
              Shimmer(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(12),
                    ),
                  ),
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Shimmer Title
                      Shimmer(
                        child: Container(
                          width: double.infinity,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Shimmer(
                        child: Container(
                          width: 120,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Shimmer(
                        child: Container(
                          width: 80,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Quantity controls shimmer
                      Row(
                        children: [
                          Shimmer(
                            child: Container(
                              width: 60,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const Spacer(),
                          Shimmer(
                            child: Container(
                              width: 100,
                              height: 29,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Shimmer Delete Button
              Shimmer(
                child: Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Shimmer effect for checkout section
  Widget _buildCheckoutSectionShimmer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Price breakdown shimmer
          for (int i = 0; i < 4; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Shimmer(
                    child: Container(
                      width: 100,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Shimmer(
                    child: Container(
                      width: 60,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Checkout button shimmer
          Shimmer(
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            "Your cart is empty",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            "Add some items to get started",
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const MainNavigation(initialIndex: 0),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text("Continue Shopping"),
          ),
        ],
      ),
    );
  }

  Widget _buildCartList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: cartItems.length,
      itemBuilder: (context, index) {
        final item = cartItems[index];
        final productJson = item["product"];
        final cartId = item["cart_id"];
        final product = ProductModel.fromJson(productJson);
        final quantity = itemQuantities[cartId] ?? 1;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailsScreen(product: product),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                // Product Image
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(12),
                  ),
                  child: Image.network(
                    "${ApiConfig.baseUrl}/${product.productImage}",
                    height: 120,
                    width: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 120,
                        width: 120,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image, color: Colors.grey),
                      );
                    },
                  ),
                ),

                // Product Info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name
                        Text(
                          product.productName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 6),

                        // Price + MRP
                        Row(
                          children: [
                            Text(
                              "₹${product.productPrice}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "₹${product.productMrp}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ),

                        // Discount
                        if (product.productDiscount > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              "${product.productDiscount}% OFF",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                        const SizedBox(height: 8),

                        // Quantity Controls
                        Row(
                          children: [
                            Text(
                              "Qty:",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              height: 29,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  // Decrease Button
                                  IconButton(
                                    onPressed: () =>
                                        updateQuantity(cartId, quantity - 1),
                                    icon: Icon(
                                      Icons.remove,
                                      size: 18,
                                      color: quantity <= 1
                                          ? Colors.grey
                                          : Colors.green,
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    constraints: const BoxConstraints(),
                                  ),

                                  // Quantity Display
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.symmetric(
                                        vertical: BorderSide(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      quantity.toString(),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),

                                  // Increase Button
                                  IconButton(
                                    onPressed: () =>
                                        updateQuantity(cartId, quantity + 1),
                                    icon: const Icon(
                                      Icons.add,
                                      size: 18,
                                      color: Colors.green,
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Delete button
                IconButton(
                  onPressed: () => removeItem(cartId),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCheckoutSection() {
    final totalMrp = getTotalMrp();
    final totalPrice = getTotalPrice();
    final totalDiscount = getTotalDiscount();
    final deliveryCharge = totalPrice > 500 ? 0 : 40;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.shade100,
            Colors.green.shade200,
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Price Breakdown
          _buildPriceRow("Total MRP", "₹${totalMrp.toStringAsFixed(2)}"),
          _buildPriceRow(
            "Discount",
            "-₹${totalDiscount.toStringAsFixed(2)}",
            isDiscount: true,
          ),
          _buildPriceRow(
            "Delivery Charge",
            deliveryCharge == 0
                ? "FREE"
                : "₹${deliveryCharge.toStringAsFixed(2)}",
          ),

          const Divider(height: 20),

          _buildPriceRow(
            "Total Amount",
            "₹${(totalPrice + deliveryCharge).toStringAsFixed(2)}",
            isTotal: true,
          ),

          const SizedBox(height: 16),

          // Checkout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await updateAllCartBeforeOrder();

                // 🔥 Now call placeOrder API
                // showOrderConfirmSheet();          // open popup
                showPaymentDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: const Text(
                "PROCEED TO CHECKOUT",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    String value, {
    bool isDiscount = false,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.black : Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isDiscount
                  ? Colors.red
                  : (isTotal ? Colors.green : Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                Icons.shopping_cart,
                color: Colors.green,
                size: 24,
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
                    "MY CART",
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
                    "Bucket List",
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
          Padding(
            padding: const EdgeInsets.only(right: 12, left: 4),
            child: IconButton(
              icon: Icon(
                Icons.search_rounded,
                size: 22,
                color: Colors.white.withOpacity(0.95),
              ),
              onPressed: () {},
              padding: const EdgeInsets.all(8),
            ),
          ),
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
        child: Column(
          children: [
            Expanded(
              child: loading
                  ? _buildCartItemShimmer() // Use shimmer instead of loader
                  : cartItems.isEmpty
                  ? _buildEmptyCart()
                  : _buildCartList(),
            ),

            // Checkout Section
            if (loading && cartItems.isNotEmpty)
              _buildCheckoutSectionShimmer()
            else if (!loading && cartItems.isNotEmpty)
              _buildCheckoutSection(),
          ],
        ),
      ),
    );
  }
}
