import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class ApiService {
  static const String _baseUrl = 'http://10.0.2.2:3000';

  static Future<List<User>> searchUsers(String query) async {
    final url = Uri.parse('$_baseUrl/api/user/search?query=$query');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => User.fromJson(e)).toList();
    } else {
      throw Exception('Kullanıcıları ararken hata oluştu.');
    }
  }
}