import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:provider/provider.dart';
import 'package:whatslab_4_everyone_2_latest/main.dart';
import '../providers/user_mail_provider.dart';
import '../services/socket_service.dart';

class WhatsAppLogin extends StatelessWidget {
  CameraDescription? camera;

  WhatsAppLogin({
    required this.camera
  });

  @override
  Widget build(BuildContext context) {
    final userMailProvider = Provider.of<UserProvider>(context, listen: false);

    return FlutterLogin(
      title: 'WhatsLab4everyone',
      theme: LoginTheme(
        primaryColor: Color(0xFF128C7E),
        accentColor: Colors.white,
        titleStyle: TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        buttonTheme: LoginButtonTheme(
          backgroundColor: Colors.green,
          splashColor: Color(0xFF25D366),
          highlightColor: Color(0xFF25D366),
        ),
      ),
      onLogin: (loginData) async {
        print('Login: ${loginData.name}, ${loginData.password}');
        userMailProvider.setUserMail(loginData.name);
        ChatSocketService.restart(userMailProvider.userMail);
        Navigator.push(context, MaterialPageRoute(builder: (context) => WhatsAppHome(camera: camera)));
        return null;
      },
      onSignup: (signupData) async {
        print('Signup: ${signupData.name}, ${signupData.password}');
        return null;
      },
      onRecoverPassword: (email) async {
        print('Recover password for: $email');
        return null;
      },
    );
  }
}
