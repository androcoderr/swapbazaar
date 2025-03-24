import 'package:flutter/material.dart';
import '../hive_models/friend_hive_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class SearchUsersPage extends StatefulWidget {
  String userMail;

  SearchUsersPage({
    required this.userMail
  });

  @override
  _SearchUsersPageState createState() => _SearchUsersPageState();
}

class _SearchUsersPageState extends State<SearchUsersPage> {
  final TextEditingController _searchController = TextEditingController();
  Future<List<User>>? _searchResults;

  void _searchUsers(String query) {
    if (query.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lütfen bir arama terimi girin')),
      );
      return;
    }

    setState(() {
      _searchResults = ApiService.searchUsers(query);
    });
  }

  void _addFriend(User user) async {
    // Hive modeline kaydetme
    final friend = Friend(
      name: widget.userMail,
      mail: user.mail,
      profileImageUrl: user.profileImageUrl ?? '',
    );

    await Friend.addFriend(friend); // Hive modelinde tanımlanacak
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${user.name} arkadaş olarak eklendi!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Kullanıcı Ara')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'E-posta ile ara',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () => _searchUsers(_searchController.text),
                ),
              ),
              onSubmitted: _searchUsers,
            ),
            SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<User>>(
                future: _searchResults,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Hata: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('Eşleşen kullanıcı bulunamadı.'));
                  } else {
                    final users = snapshot.data!;
                    return ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return ListTile(
                          leading: CircleAvatar(
                           // backgroundImage: NetworkImage(user.profileImageUrl ?? ''),
                          ),
                          title: Text(user.name),
                          subtitle: Text(user.mail),
                          trailing: IconButton(
                            icon: Icon(Icons.person_add),
                            onPressed: () => _addFriend(user),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
