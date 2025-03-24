import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import '../hive_models/friend_hive_model.dart';
import '../models/user_model.dart';

class PersonsPage extends StatefulWidget {
  @override
  _PersonsPageState createState() => _PersonsPageState();
}

class _PersonsPageState extends State<PersonsPage> {
  List<User> _users = []; // Başlangıçta boş bir liste
  late Box _friendsBox; // Hive kutusu, late kullanılabilir çünkü kutu açma işlemi initState içinde yapılacak

  @override
  void initState() {
    super.initState();
    _loadUsersFromHive();
  }

  // Hive'den kullanıcıları alacak fonksiyon
  void _loadUsersFromHive() async {
    _friendsBox = await Hive.openBox<Friend>('friends');
    setState(() {
      _users = _friendsBox.values.map((friend) {
        return User(
          name: friend.mail.toString().split("@")[0],
          mail: friend.mail,
          profileImageUrl: friend.profileImageUrl, hashedPassword: '',
        );
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kişiler'),
      ),
      body: _users.isEmpty
          ? Center(child: CircularProgressIndicator()) // Veriler yükleniyorsa gösterilecek
          : ListView(
        children: _users.map((user) {
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(user.profileImageUrl ?? ''),
            ),
            title: Text(user.name),
            subtitle: Text(user.mail),
            onTap: () {
              // Kişiye tıklandığında ChatPage'e yönlendirme
            },
          );
        }).toList(),
      ),
    );
  }
}
