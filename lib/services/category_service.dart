import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/category_model.dart';
import '../baseapi.dart';

class CategoryService {
  Future<List<CategoryModel>> fetchCategories() async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/categories");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      List categories = data["categories"];

      return categories.map((e) => CategoryModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load categories");
    }
  }
}

