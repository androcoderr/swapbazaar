import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:provider/provider.dart';
import 'package:whatslab_4_everyone_2_latest/hive_models/chat_hive_model.dart';
import 'package:whatslab_4_everyone_2_latest/hive_models/friend_hive_model.dart';
import 'package:whatslab_4_everyone_2_latest/pages/calls_page.dart';
import 'package:whatslab_4_everyone_2_latest/pages/camera_page.dart';
import 'package:whatslab_4_everyone_2_latest/pages/communities_page.dart';
import 'package:whatslab_4_everyone_2_latest/pages/login_page.dart';
import 'package:whatslab_4_everyone_2_latest/pages/messages_page.dart';
import 'package:whatslab_4_everyone_2_latest/pages/persons_page.dart';
import 'package:whatslab_4_everyone_2_latest/pages/profile_page.dart';
import 'package:whatslab_4_everyone_2_latest/pages/search_friends_page.dart';
import 'package:whatslab_4_everyone_2_latest/pages/updates_page.dart';
import 'package:whatslab_4_everyone_2_latest/providers/search_query_provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:whatslab_4_everyone_2_latest/providers/user_mail_provider.dart';
import 'package:whatslab_4_everyone_2_latest/providers/user_name_provider.dart';
import 'package:whatslab_4_everyone_2_latest/services/chat_service.dart';
import 'package:whatslab_4_everyone_2_latest/services/socket_service.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  await Hive.initFlutter();
  Hive.registerAdapter(ChatAdapter());
  Hive.registerAdapter(FriendAdapter());
  //Hive.registerAdapter(ChatMessageAdapter());
  //Hive.registerAdapter(BalloonMessageAdapter());

  Gemini.init(apiKey: 'AIzaSyDt1Hy_jOeb7msxbKDsvguNBIWYvs2reFk');

  final chatService = ChatService();
  await chatService.init();

  initializeDateFormatting().then((_) => runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SearchQueryModel()),
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(create: (context) => UserNameProvider()),
      ],
      child: MyApp(camera: firstCamera),
    ),
  ));
}

class MyApp extends StatelessWidget with WidgetsBindingObserver{
  MyApp({super.key,required this.camera});
  CameraDescription? camera;


  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Directionality(
      textDirection: TextDirection.ltr,
      child: WhatsAppLogin(camera: camera,) //WhatsAppHome(camera: camera,),
    ),
  );
}

class WhatsAppHome extends StatefulWidget {
  WhatsAppHome({super.key,required this.camera});
  CameraDescription? camera;

  @override
  State<WhatsAppHome> createState() => _WhatsAppHomeState();
}

class _WhatsAppHomeState extends State<WhatsAppHome> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    MessagesPage(),
    const UpdatesPage(),
    const CommunitiesPage(),
    const CallsPage(),
  ];

  bool isSearching = false; // Arama durumu için değişken

  @override
  Widget build(BuildContext context) {
    final userMailProvider = Provider.of<UserProvider>(context,listen: false);
    final query = Provider.of<SearchQueryModel>(context);

    // actionsPerPage: Hangi sekme için hangi action'lar gösterilecek
    Map<int, List<int>> actionsPerPage = {
      0: [0, 1, 2],
      1: [2],
      2: [2],
      3: [2],
    };

    // Tüm actions için tanımlamalar
    Map<int, Widget> actions = {
      0: IconButton(
        icon: const Icon(Icons.camera_alt_sharp, color: Colors.white),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => PhotoCapturePage(camera: widget.camera)));
        },
      ),
      1: IconButton(
        icon: const Icon(Icons.search, color: Colors.white),
        onPressed: () {
          setState(() {
            isSearching = true; // Arama moduna geçiş
          });
        },
      ),
      2: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == "profile") {
              Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage()));
            }
            else if (value == "add-friend") {
              Navigator.push(context, MaterialPageRoute(builder: (context) => SearchUsersPage(userMail: userMailProvider.userMail,)));
            }
            else if (value == "persons") {
              Navigator.push(context,
                MaterialPageRoute(builder: (context) => PersonsPage())
              );
            }
          },
          itemBuilder: (context) => [
          PopupMenuItem(
          value: "profile",
          child: Row(
            children: [
              Icon(Icons.person, color: Colors.greenAccent),
              SizedBox(width: 10),
              Text("Profile page"),
            ],
          ),
          ),
            PopupMenuItem(
              value: "add-friend",
              child: Row(
                children: [
                  Icon(Icons.people, color: Colors.green),
                  SizedBox(width: 10),
                  Text("Add friend page"),
                ],
              ),
            ),
            PopupMenuItem(
              value: "persons",
              child: Row(
                children: [
                  Icon(Icons.people_outline_rounded, color: Colors.green),
                  SizedBox(width: 10),
                  Text("Persons page"),
                ],
              ),
            ),
      ]
        ,),
    };



    // Dinamik olarak actions oluştur
    List<Widget> _getActions(int index) {
      if (isSearching) {
        // Arama durumunda sadece SearchBar ve Close ikonu
        return [
          Expanded(
            child: TextField(
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Search...',
                hintStyle: TextStyle(color: Colors.white54),
                border: InputBorder.none,
              ),
              onChanged: (value) {
                query.setSearchQuery(value);
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              setState(() {
                isSearching = false; // Aramayı kapat
              });
            },
          ),
        ];
      }

      // Normal durumdaki action ikonları
      List<Widget> result = [];
      List<int>? actionKeys = actionsPerPage[index];
      actionKeys?.forEach((i) {
        if (actions.containsKey(i)) {
          result.add(actions[i]!);
        }
      });
      return result;
    }

    // Her sekmeye özel FloatingActionButton tanımları
    List<Widget?> floatActionButtons = [
      FloatingActionButton(
        heroTag: 'floatactionbutton1', // chats
        backgroundColor: Colors.greenAccent,
        onPressed: () {
       //   Navigator.push(
       //       context, MaterialPageRoute(builder: (context) => const PersonsPage()));
        },
        child: const Icon(Icons.message),
      ),
      FloatingActionButton(
        heroTag: 'floatactionbutton2', // updates
        backgroundColor: Colors.greenAccent,
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
      null,
      FloatingActionButton(
        heroTag: 'floatactionbutton4', // calls
        backgroundColor: Colors.greenAccent,
        onPressed: () {},
        child: const Icon(Icons.call),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade300,
        title: isSearching
            ? null // Arama sırasında başlık gizlenir
            : const Text(
          'WhatsLab',
          style: TextStyle(color: Colors.white),
        ),
        actions: _getActions(_selectedIndex), // Dinamik action ikonları
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      floatingActionButton: floatActionButtons[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        indicatorColor: Colors.green.shade300,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: Icon(Icons.update),
            label: 'Updates',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups),
            label: 'Communities',
          ),
          NavigationDestination(
            icon: Icon(Icons.call),
            label: 'Calls',
          ),
        ],
      ),
    );
  }
}
