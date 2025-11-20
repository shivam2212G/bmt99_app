import 'dart:convert';
import 'package:http/http.dart' as http;

import '../baseapi.dart';
import '../model/product_model.dart';

class NewProductService {
  Future<List<ProductModel>> fetchNewProducts() async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/new-products");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => ProductModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load new products");
    }
  }
}
