import 'dart:io';

import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  String _userMail = '@mail.com';
  File? _profileImage = null;

  File? get profileImage => _profileImage;

  void setProfileImage(File file) {
    _profileImage = file;
  }

  String get userMail => _userMail;

  void setUserMail(String mail) {
    _userMail = mail;
    notifyListeners();
  }
}
