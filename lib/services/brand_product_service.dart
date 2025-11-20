import 'dart:convert';
import 'package:http/http.dart' as http;

import '../baseapi.dart';
import '../model/product_model.dart';

class BrandProductService {
  Future<List<ProductModel>> fetchProductsByBrand(int brandId) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/productbyBrandId/$brandId");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((p) => ProductModel.fromJson(p)).toList();
    } else {
      throw Exception("Failed to load brand products");
    }
  }
}
