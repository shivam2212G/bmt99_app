import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/slider_model.dart';
import '../baseapi.dart';

class SliderService {
  Future<List<SliderModel>> fetchSliders() async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/slider");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);

      return data.map((item) => SliderModel.fromJson(item)).toList();
    } else {
      throw Exception("Failed to load sliders");
    }
  }
}
