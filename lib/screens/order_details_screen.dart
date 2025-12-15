import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import '../baseapi.dart';

class OrderDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final List<String> cancelReasons = [
    "Changed my mind",
    "Found better price elsewhere",
    "Delivery time too long",
    "Item unavailable",
    "Shipping cost too high",
    "Ordered by mistake",
    "Payment issues",
    "Other"
  ];

  String? selectedReason;
  TextEditingController otherReasonController = TextEditingController();
  bool isLoading = false;

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

  int getStatusStep(String s) {
    switch (s) {
      case "0":
        return 0;
      case "1":
        return 1;
      case "2":
        return 2;
      case "3":
        return 3;
      default:
        return 0;
    }
  }

  void _showCancelOrderDialog() {
    selectedReason = null;
    otherReasonController.clear();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.green.shade100,
              title: const Row(
                children: [
                  Icon(Icons.cancel, color: Colors.red),
                  SizedBox(width: 8),
                  Text("Cancel Order", style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Please select a reason for cancellation:",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),

                    // Reason List
                    ...cancelReasons.map((reason) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: RadioListTile<String>(
                          title: Text(reason),
                          value: reason,
                          groupValue: selectedReason,
                          onChanged: (value) {
                            setState(() {
                              selectedReason = value;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      );
                    }).toList(),

                    // Other Reason Text Field
                    if (selectedReason == "Other")
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: TextField(
                          controller: otherReasonController,
                          decoration: const InputDecoration(
                            hintText: "Please specify your reason...",
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          maxLines: 3,
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: selectedReason == null
                      ? null
                      : () {
                    _cancelOrder();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.red.withOpacity(0.5),
                  ),
                  child: const Text("Confirm Cancel"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _cancelOrder() async {
    if (selectedReason == null) return;

    String cancelReason = selectedReason == "Other"
        ? otherReasonController.text.trim()
        : selectedReason!;

    if (cancelReason.isEmpty && selectedReason == "Other") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter cancellation reason")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final baseApi = BaseApi(); // Create instance
      final response = await baseApi.post(
        '${ApiConfig.baseUrl}/api/update-order-status',
        {
          'order_id': widget.order["order_id"],
          'cancel_reason': cancelReason,
        },
      );

      setState(() {
        isLoading = false;
      });

      if (response['status'] == true) {
        // Update the local order status
        widget.order["order_status"] = "4";
        widget.order["cancel_reason"] = cancelReason;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Order cancelled successfully"),
            backgroundColor: Colors.green[700],
          ),
        );

        // Refresh the UI
        setState(() {});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? "Failed to cancel order"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildCancelButton() {
    if (widget.order["order_status"] == "4") {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            const Icon(Icons.cancel, color: Colors.red, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Order Cancelled",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  if (widget.order["cancel_reason"] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        "Reason: ${widget.order["cancel_reason"]}",
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Only show cancel button for pending and confirmed orders
    if (widget.order["order_status"] != "0" && widget.order["order_status"] != "1") {
      return const SizedBox();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ElevatedButton.icon(
        onPressed: _showCancelOrderDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        icon: const Icon(Icons.cancel_outlined, size: 20),
        label: const Text(
          "Cancel Order",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int step = getStatusStep(widget.order["order_status"]);

    return Scaffold(
      appBar: AppBar(
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
                    "Order #${widget.order["order_id"]}",
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
                    "See where Your Items",
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
        // actions: [
        //   // Notification icon
        //   Padding(
        //     padding: const EdgeInsets.symmetric(horizontal: 4),
        //     child: IconButton(
        //       icon: Badge(
        //         label: const Text('2'),
        //         backgroundColor: Colors.red.shade400,
        //         textColor: Colors.white,
        //         smallSize: 18,
        //         child: Icon(
        //           Iconsax.notification,
        //           size: 22,
        //           color: Colors.white.withOpacity(0.95),
        //         ),
        //       ),
        //       onPressed: () {},
        //       padding: const EdgeInsets.all(8),
        //     ),
        //   ),
        //   // Search icon
        //   Padding(
        //     padding: const EdgeInsets.only(right: 12, left: 4),
        //     child: IconButton(
        //       icon: Icon(
        //         Icons.search_rounded,
        //         size: 22,
        //         color: Colors.white.withOpacity(0.95),
        //       ),
        //       onPressed: () {},
        //       padding: const EdgeInsets.all(8),
        //     ),
        //   ),
        // ],
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
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ---------------- ORDER STATUS ----------------
                    Container(
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            "Order Status: ${getStatusText(widget.order["order_status"])}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ---- Status Progress Bar ----
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              buildStep("Pending", 0, step),
                              buildStep("Confirmed", 1, step),
                              buildStep("Shipped", 2, step),
                              buildStep("Delivered", 3, step),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Cancel Button or Cancelled Status


                    // ---------------- ORDER ITEMS ----------------
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Items",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),

                          ...widget.order["items"].map<Widget>((item) {
                            final product = item["product"];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      "${ApiConfig.baseUrl}/${product["product_image"]}",
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 70,
                                          height: 70,
                                          color: Colors.grey[200],
                                          child: const Icon(Icons.image, color: Colors.grey),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product["product_name"],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),

                                        const SizedBox(height: 6),
                                        Text(
                                          "Qty: ${item["quantity"]}",
                                          style: const TextStyle(color: Colors.grey),
                                        ),

                                        const SizedBox(height: 4),
                                        Text(
                                          "₹${item["price"]}",
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ---------------- PAYMENT DETAILS ----------------
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Payment Details",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),

                          _buildInfoRow(
                            "Payment Method",
                            widget.order["payment_method"] == "0"
                                ? "Cash on Delivery"
                                : "Online Payment",
                          ),

                          _buildInfoRow(
                            "Payment Status",
                            widget.order["payment_status"] == "1" ? "Paid" : "Pending",
                            valueColor: widget.order["payment_status"] == "1"
                                ? Colors.green
                                : Colors.orange,
                          ),

                          if (widget.order["transaction_id"] != null)
                            _buildInfoRow("Transaction ID", widget.order["transaction_id"]!),

                          if (widget.order["paid_amount"] != null)
                            _buildInfoRow("Paid Amount", "₹${widget.order["paid_amount"]}"),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ---------------- ORDER SUMMARY ----------------
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Order Summary",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),

                          _buildInfoRow("Total MRP", "₹${widget.order["total_amount"]}"),
                          _buildInfoRow("Discount", "-₹${widget.order["discount_amount"]}"),
                          _buildInfoRow(
                            "Delivery Charge",
                            widget.order["delivery_charge"] == 0
                                ? "Free"
                                : "₹${widget.order["delivery_charge"]}",
                          ),

                          const Divider(),

                          _buildInfoRow(
                            "Final Amount",
                            "₹${widget.order["final_amount"]}",
                            isBold: true,
                            valueColor: Colors.green,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ---------------- ADDRESS ----------------
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.green, size: 18),
                              SizedBox(width: 8),
                              Text(
                                "Delivery Address",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.order["address"],
                              style: const TextStyle(fontSize: 14, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildCancelButton(),
                      ],
                    )

                    // const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildStep(String title, int index, int currentStep) {
    bool active = index <= currentStep;

    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: active ? Colors.green : Colors.grey.shade300,
            shape: BoxShape.circle,
            border: Border.all(
              color: active ? Colors.green : Colors.grey.shade400,
              width: 2,
            ),
          ),
          child: active
              ? const Icon(Icons.check, color: Colors.white, size: 14)
              : null,
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: active ? Colors.green : Colors.grey,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInfoRow(String title, String value,
      {bool isBold = false, Color valueColor = Colors.black}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    otherReasonController.dispose();
    super.dispose();
  }
}

class BaseApi {
  Future<Map<String, dynamic>> post(String url, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}