import 'dart:convert';
import 'package:http/http.dart' as http;
import '../baseapi.dart';

class WishlistService {

  Future<Map<String, dynamic>> toggleWishlist({
    required int userId,
    required int productId,
  }) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/wishlist/toggle");

    final response = await http.post(url, body: {
      "user_id": userId.toString(),
      "product_id": productId.toString(),
    });

    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getWishlist(int userId) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/wishlist/$userId");

    final response = await http.get(url);
    final data = jsonDecode(response.body);

    return data["items"];
  }
}
