import 'package:flutter/material.dart';

class SearchQueryModel with ChangeNotifier {
  String? _query;

  String? get query => _query;

  void setSearchQuery(String query) {
    _query = query;
    notifyListeners();
  }
}
