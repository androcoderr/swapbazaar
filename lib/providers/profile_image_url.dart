import 'package:flutter/material.dart';

class ProfileImageUrlProvider with ChangeNotifier {
  String _profileImageUrl = 'no';

  String get profileImageUrl => _profileImageUrl;

  void setUsername(String profileImageUrl) {
    _profileImageUrl = profileImageUrl;
    notifyListeners();
  }
}
