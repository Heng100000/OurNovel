import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../core/models/news_announcement.dart';

class NewsService {
  Future<List<NewsAnnouncement>> getNewsAnnouncements() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.newsAnnouncements),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> newsList = data['data'];
        return newsList.map((json) => NewsAnnouncement.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error fetching news: $e');
    }
    return [];
  }
}
