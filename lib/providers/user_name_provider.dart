import 'package:flutter/material.dart';

class UserNameProvider with ChangeNotifier {
  String _username = 'jade';

  String get username => _username;

  void setUsername(String username) {
    _username = username;
    notifyListeners();
  }
}
