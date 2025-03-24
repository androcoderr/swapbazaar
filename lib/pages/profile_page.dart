import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../providers/user_mail_provider.dart';
import '../providers/user_name_provider.dart';
import '../services/socket_service.dart';
import '../services/user_api_service.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  
  void _showEditModal(BuildContext context) {
    final userNameProvider = Provider.of<UserNameProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final TextEditingController nameController = TextEditingController(text: userNameProvider.username);
    final TextEditingController emailController = TextEditingController(text: userProvider.userMail);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Profili Düzenle',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // Kullanıcı Adı
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Kullanıcı Adı',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // E-posta
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'E-posta',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // Profil Resmi
              ElevatedButton.icon(
                onPressed: () async {
                  final ImagePicker picker = ImagePicker();
                  final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    userProvider.setProfileImage(File(pickedFile.path));
                  }
                },
                icon: const Icon(Icons.image),
                label: const Text('Profil Resmi Seç'),
              ),
              const SizedBox(height: 16),
              // Kaydet Butonu
              ElevatedButton(
                onPressed: () async {
                  try {
                    final result = await UserApiService.updateUser(
                      mail: userProvider.userMail,
                      name: nameController.text,
                      profileImageUrl: 'save',
                      hashedPassword: 'newhashedpassword',
                    );

                    print('Güncellenen Kullanıcı: $result');
                  } catch (e) {
                    print('Hata: $e');
                  }
                  userNameProvider.setUsername(nameController.text);
                  userProvider.setUserMail(emailController.text);

                  ChatSocketService.restart(nameController.text);

                  Navigator.pop(context);
                },
                child: const Text('Kaydet'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profil Resmi
            Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                return CircleAvatar(
                  radius: 50,
                  backgroundImage: userProvider.profileImage != null
                      ? FileImage(userProvider.profileImage!)
                      : null,
                );
              },
            ),
            const SizedBox(height: 16),
            // Kullanıcı Adı
            Consumer<UserNameProvider>(
              builder: (context, userNameProvider, child) {
                return Text(
                  userNameProvider.username,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            // Durum
            const Text(
              'Bu benim durumum',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            // E-posta
            Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                return ListTile(
                  leading: const Icon(Icons.email),
                  title: const Text('E-posta'),
                  subtitle: Text(userProvider.userMail),
                );
              },
            ),
            const SizedBox(height: 16),
            // Düzenle Butonu
            ElevatedButton(
              onPressed: () => _showEditModal(context),
              child: const Text('Düzenle'),
            ),
          ],
        ),
      ),
    );
  }

}

