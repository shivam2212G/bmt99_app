import 'package:flutter/material.dart';
import '../baseapi.dart';

class OrderDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderDetailsScreen({super.key, required this.order});

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

  @override
  Widget build(BuildContext context) {
    int step = getStatusStep(order["order_status"]);

    return Scaffold(
      appBar: AppBar(
        title: Text("Order #${order["order_id"]}"),
        backgroundColor: Colors.green,
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------- ORDER STATUS ----------------
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                children: [
                  const Text(
                    "Order Status",
                    style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

            const SizedBox(height: 10),

            // ---------------- ORDER ITEMS ----------------
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Items",
                    style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  ...order["items"].map<Widget>((item) {
                    final product = item["product"];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              "${ApiConfig.baseUrl}/${product["product_image"]}",
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 10),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product["product_name"],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),

                                const SizedBox(height: 4),
                                Text("Qty: ${item["quantity"]}"),

                                const SizedBox(height: 4),
                                Text(
                                  "₹${item["price"]}",
                                  style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold),
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

            const SizedBox(height: 10),

            // ---------------- PAYMENT DETAILS ----------------
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Payment Details",
                    style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  buildInfoRow("Payment Method",
                      order["payment_method"] == "0" ? "Cash on Delivery" : "Online Payment"),

                  buildInfoRow("Payment Status",
                      order["payment_status"] == "1" ? "Paid" : "Pending"),

                  if (order["transaction_id"] != null)
                    buildInfoRow("Transaction ID", order["transaction_id"]),

                  if (order["paid_amount"] != null)
                    buildInfoRow("Paid Amount", "₹${order["paid_amount"]}"),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ---------------- ORDER SUMMARY ----------------
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Order Summary",
                    style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  buildInfoRow("Total MRP", "₹${order["total_amount"]}"),
                  buildInfoRow("Discount", "-₹${order["discount_amount"]}"),
                  buildInfoRow("Delivery Charge",
                      order["delivery_charge"] == 0 ? "Free" : "₹${order["delivery_charge"]}"),

                  const Divider(),

                  buildInfoRow("Final Amount", "₹${order["final_amount"]}",
                      isBold: true),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ---------------- ADDRESS ----------------
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Delivery Address",
                    style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  Text(order["address"],
                      style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget buildStep(String title, int index, int currentStep) {
    bool active = index <= currentStep;

    return Column(
      children: [
        CircleAvatar(
          radius: 10,
          backgroundColor: active ? Colors.green : Colors.grey.shade400,
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: active ? Colors.green : Colors.grey,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget buildInfoRow(String title, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 14, color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
