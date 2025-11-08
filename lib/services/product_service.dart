import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/product_model.dart';
import '../baseapi.dart';

class ProductService {
  Future<List<ProductModel>> getProductsByCategory(int categoryId) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/products/$categoryId");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => ProductModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load products");
    }
  }

  Future<List<ProductModel>> getProductsBySubcategory(int subCatId) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/products/$subCatId");

    final response = await http.get(url);

    final List data = jsonDecode(response.body);

    return data.map((e) => ProductModel.fromJson(e)).toList();
  }

}
