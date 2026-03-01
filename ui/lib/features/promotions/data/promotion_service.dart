import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../core/models/event.dart';
import '../../../core/models/promotion.dart';

class PromotionService {
  Future<List<EventModel>> getEvents() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.events),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> eventList = data['data'];
        return eventList.map((json) => EventModel.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error fetching events: $e');
    }
    return [];
  }

  Future<List<PromotionModel>> getPromotions() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.promotions),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> promotionList = data['data'];
        return promotionList.map((json) => PromotionModel.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error fetching promotions: $e');
    }
    return [];
  }

  Future<EventModel?> getEventDetails(int id) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.events}/$id'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return EventModel.fromJson(data['data']);
      }
    } catch (e) {
      print('Error fetching event details: $e');
    }
    return null;
  }
}
