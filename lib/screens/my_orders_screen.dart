import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../baseapi.dart';
import 'order_details_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  bool loading = true;
  List<dynamic> orders = [];

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  Future<void> loadOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt("user_id");

    final url = Uri.parse("${ApiConfig.baseUrl}/api/orders/$userId");
    final response = await http.get(url);

    print("ORDERS API: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        orders = data["orders"] ?? [];
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  String getStatusText(String s) {
    switch (s) {
      case "0":
        return "Pending";
      case "1":
        return "Confirmed";
      case "2":
        return "Shipped";
      case "3":
        return "Delivered";
      case "4":
        return "Cancelled";
      case "5":
        return "Returned";
      default:
        return "Pending";
    }
  }

  Color getStatusColor(String s) {
    switch (s) {
      case "0":
        return Colors.orange;
      case "1":
        return Colors.blue;
      case "2":
        return Colors.purple;
      case "3":
        return Colors.green;
      case "4":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Orders"),
        backgroundColor: Colors.green,
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
          ? Center(
        child: Text(
          "No Orders Yet",
          style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderDetailsScreen(order: order),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order ID
                  Text(
                    "Order #${order["order_id"]}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Status
                  Row(
                    children: [
                      Icon(Icons.circle,
                          size: 12,
                          color: getStatusColor(order["order_status"])),
                      const SizedBox(width: 6),
                      Text(
                        getStatusText(order["order_status"]),
                        style: TextStyle(
                          fontSize: 14,
                          color:
                          getStatusColor(order["order_status"]),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Amount
                  Text(
                    "₹${order["final_amount"]}",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Date
                  Text(
                    order["created_at"]
                        .toString()
                        .substring(0, 10),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Items preview
                  SizedBox(
                    height: 70,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: order["items"].length,
                      itemBuilder: (_, i) {
                        final product =
                        order["items"][i]["product"];

                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              "${ApiConfig.baseUrl}/${product["product_image"]}",
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
