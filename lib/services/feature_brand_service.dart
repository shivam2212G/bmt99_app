import 'dart:convert';
import 'package:http/http.dart' as http;

import '../baseapi.dart';
import '../model/feature_brand_model.dart';

class FeatureBrandService {
  Future<List<FeatureBrandModel>> fetchFeatureBrands() async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/feature-brands");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => FeatureBrandModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to fetch featured brands");
    }
  }
}
