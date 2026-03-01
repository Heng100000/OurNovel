import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../core/models/banner.dart';

class BannerService {
  Future<List<BannerModel>> getBanners() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.banners),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> bannerList = data['data'];
        return bannerList.map((json) => BannerModel.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error fetching banners: $e');
    }
    return [];
  }
}
