import 'dart:convert';
import 'package:http/http.dart' as http;
import '../baseapi.dart';
import '../model/product_model.dart';

class BestOffersService {
  Future<List<ProductModel>> fetchBestOffers() async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/best-offers");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => ProductModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load best offers");
    }
  }
}
