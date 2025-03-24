import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/user_mail_provider.dart';
import '../services/socket_service.dart';
import 'chat_page.dart';

class MessagesPage extends StatefulWidget {

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  late ChatSocketService socketService;
  late String userMail;

    List<User> _users = [
        User(
          name: 'john',
          mail: 'john@mail.com',
          hashedPassword: '123456',
          profileImageUrl: 'no'
        ),
      User(
          name: 'jade',
          mail: 'jade@mail.com',
          hashedPassword: '123456',
          profileImageUrl: 'no'
      ),
      User(
          name: 'jack',
          mail: 'jack@mail.com',
          hashedPassword: '123456',
          profileImageUrl: 'no'
      ),
    ];

    late List<int> unReadMessages;

  @override
  void initState() {
    super.initState();
    userMail = Provider.of<UserProvider>(context, listen: false).userMail;
    socketService = ChatSocketService.getInstance(userMail);

    unReadMessages = List.generate(_users.length, (a) => 0);

    socketService.chatStream.listen((newMessage) {
      for (int i = 0; i < _users.length; i++) {
        if (_users[i].mail == newMessage.fromUserMail) {
          setState(() {
            unReadMessages[i] += 1;
          });
          break;
        }
      }
    });

  }

  @override
  Widget build(BuildContext context) {
    //final userMail = Provider.of<UserProvider>(context, listen: false).userMail;
    //socketService = ChatSocketService(userMail);

    return Scaffold(
      body: ListView.builder(
        itemCount: _users.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Card(child:
                Padding(padding: EdgeInsets.symmetric(vertical: 10),child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(onPressed: () {}, icon: const CircleAvatar(child: Icon(Icons.person),)),
                    Text("${_users[index].name} I am using whatslab                         "),
                    Text("${unReadMessages[index]}" , style: const TextStyle(color: Colors.green,fontSize: 16),),
                  ]
                )
            )
            ),
            onTap: () {
              setState(() {
                unReadMessages[index] = 0;
              });
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(
                    user: _users[index],
                    socketService: socketService,
                      userMail: userMail,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
