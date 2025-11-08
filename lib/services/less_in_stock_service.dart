import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/product_model.dart';
import '../baseapi.dart';

class LessInStockService {
  Future<List<ProductModel>> fetchLessInStock() async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/less-in-stock");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => ProductModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load less in stock products");
    }
  }
}
