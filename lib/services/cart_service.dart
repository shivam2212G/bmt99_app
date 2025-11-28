import 'dart:convert';
import 'package:http/http.dart' as http;
import '../baseapi.dart';

class CartService {
  Future<Map<String, dynamic>> addToCart({
    required int userId,
    required int productId,
    int quantity = 1
  }) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/cart/add");

    print("API URL: $url");
    print("Sending: user_id=$userId, product_id=$productId");

    final response = await http.post(
      url,
      body: {
        "user_id": userId.toString(),
        "product_id": productId.toString(),
        'quantity': quantity.toString(),
      },
    );

    print("Status Code: ${response.statusCode}");
    print("Response Body: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error: ${response.body}");
    }
  }

  // 🔥 GET CART ITEMS
  Future<Map<String, dynamic>> getCart(int userId) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/cart/$userId");

    final response = await http.get(url);

    return jsonDecode(response.body);
  }

  // 🔥 DELETE CART ITEM
  Future<bool> removeCartItem(int cartId) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/cart/remove/$cartId");

    final response = await http.delete(url);

    return response.statusCode == 200;
  }

  Future<bool> updateAllCartItems(int userId, List<Map<String, dynamic>> items) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/cart/update-all");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": userId,
        "items": items
      }),
    );

    return response.statusCode == 200;
  }


}
