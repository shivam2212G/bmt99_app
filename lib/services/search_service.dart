import 'dart:convert';
import 'package:http/http.dart' as http;

import '../baseapi.dart';
import '../model/product_model.dart';

class SearchService {
  Future<List<ProductModel>> searchProducts({
    String? query,
    String? sort,
    int? categoryId,
    int? subCategoryId,
    int? brandId,
    int? minPrice,
    int? maxPrice,
  }) async {
    final Map<String, String> params = {};

    if (query != null && query.isNotEmpty) {
      params['query'] = query;
    }
    if (sort != null && sort.isNotEmpty) {
      params['sort'] = sort;
    }
    if (categoryId != null) {
      params['category_id'] = categoryId.toString();
    }
    if (subCategoryId != null) {
      params['sub_category_id'] = subCategoryId.toString();
    }
    if (brandId != null) {
      params['brand_id'] = brandId.toString();
    }
    if (minPrice != null) {
      params['min_price'] = minPrice.toString();
    }
    if (maxPrice != null) {
      params['max_price'] = maxPrice.toString();
    }

    final uri = Uri.parse("${ApiConfig.baseUrl}/api/search-products")
        .replace(queryParameters: params);

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => ProductModel.fromJson(e)).toList();
    } else {
      throw Exception("Search error");
    }
  }
}
