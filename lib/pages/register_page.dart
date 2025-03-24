import 'package:flutter/material.dart';
import 'package:rxdart/subjects.dart';
import 'dart:async';
import 'package:whatslab_4_everyone_2_latest/models/user_model.dart';

import 'package:whatslab_4_everyone_2_latest/models/user_model.dart';

class Group {  final String name;
final int memberCount;
final String lastMessage;
final DateTime lastMessageTime;
final int unreadCount;
List<User> users;

Group({
  required this.name,
  required this.memberCount,
  required this.lastMessage,
  required this.lastMessageTime,
  required this.unreadCount,
  this.users = const [], // Varsayılan boş liste
});

factory Group.fromJson(Map<String, dynamic> json) => Group(
  name: json['name'] as String,
  memberCount: json['memberCount'] as int,
  lastMessage: json['lastMessage'] as String,
  lastMessageTime: DateTime.parse(json['lastMessageTime'] as String),
  unreadCount: json['unreadCount'] as int,
  users: List<User>.from(json['users']?.map((u) => User.fromJson(u as Map<String, dynamic>)) ?? const []),
);

Map<String, dynamic> toJson() => {
  'name': name,
  'memberCount': memberCount,
  'lastMessage': lastMessage,
  'lastMessageTime': lastMessageTime.toIso8601String(),
  'unreadCount': unreadCount,
  'users': User.listToJson(users),
};

static List<Group> fromJsonList(List<dynamic> jsonList) =>
    jsonList.map((json) => Group.fromJson(json as Map<String, dynamic>)).toList();

static List<Map<String, dynamic>> toJsonList(List<Group> list) =>
    list.map((group) => group.toJson()).toList();
}

class Community {
  final String communityId;
  String name;
  final String? imageUrl;
  final String description;
  final int memberCount;
  final List<Group> groups;
  final DateTime lastActivity;
  final bool hasUnread;
  List<User> users = [];

  Community(this.communityId, {
    required this.name,
    this.imageUrl,
    required this.description,
    required this.memberCount,
    required this.groups,
    required this.lastActivity,
    required this.hasUnread,
    required this.users,// Varsayılan boş liste
  });

  factory Community.fromJson(Map<String, dynamic> json) => Community(
    json['communityId'] as String,
    name: json['name'] as String,
    imageUrl: json['imageUrl'] as String?,
    description: json['description'] as String,
    memberCount: json['memberCount'] as int,
    groups: List<Group>.from(json['groups']?.map((g) => Group.fromJson(g as Map<String, dynamic>)) ?? const []),
    lastActivity: DateTime.parse(json['lastActivity'] as String),
    hasUnread: json['hasUnread'] as bool,
    users: List<User>.from(json['users']?.map((u) => User.fromJson(u as Map<String, dynamic>)) ?? const []),
  );

  Map<String, dynamic> toJson() => {
    'communityId': communityId,
    'name': name,
    'imageUrl': imageUrl,
    'description': description,
    'memberCount': memberCount,
    'groups': Group.toJsonList(groups),
    'lastActivity': lastActivity.toIso8601String(),
    'hasUnread': hasUnread,
    'users': User.listToJson(users),
  };

  static List<Community> fromJsonList(List<dynamic> jsonList) =>
      jsonList.map((json) => Community.fromJson(json as Map<String, dynamic>)).toList();

  static List<Map<String, dynamic>> toJsonList(List<Community> list) =>
      list.map((community) => community.toJson()).toList();
}


class CommunitiesPage extends StatefulWidget {
  const CommunitiesPage({super.key});

  @override
  State<CommunitiesPage> createState() => _CommunitiesPageState();
}

class _CommunitiesPageState extends State<CommunitiesPage> {
  final BehaviorSubject<List<Community>> _communitiesSubject = BehaviorSubject<List<Community>>();
  Timer? _timer;
  List<Community> _currentCommunities = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _timer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _updateRandomCommunity();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _communitiesSubject.close();
    super.dispose();
  }

  void _addNewCommunity() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Community Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  final newCommunity = Community(
                    '1', // Örnek communityId, gerçek bir ID mekanizması kullanabilirsiniz
                    name: nameController.text,
                    description: descriptionController.text,
                    memberCount: 0, // Başlangıçta 0, sonradan güncellenebilir
                    groups: [], // Başlangıçta boş, gerektiğinde gruplar eklenebilir
                    lastActivity: DateTime.now(),
                    hasUnread: false, users: [],
                  );

                  // Eski verileri alıp yeni community'i ekleyerek listeyi güncelliyoruz.
                  final updatedCommunities = List<Community>.from(_communitiesSubject.value ?? []);

                  updatedCommunities.add(newCommunity);

                  // Güncellenmiş listeyi stream'e ekliyoruz.
                  _communitiesSubject.add(updatedCommunities);

                  // Modal sheet'i kapat
                  Navigator.pop(context);
                },
                child: const Text('Add Community'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _loadInitialData() {
    _currentCommunities = [
      Community(
        '0',
        name: 'University Campus',
        description: 'Official community for university students and staff',
        memberCount: 1250,
        lastActivity: DateTime.now().subtract(const Duration(minutes: 5)),
        hasUnread: true,
        groups: [
          Group(
            name: 'General Announcements',
            memberCount: 1250,
            lastMessage: 'Next week\'s schedule is now available',
            lastMessageTime: DateTime.now().subtract(const Duration(minutes: 5)),
            unreadCount: 2,
          ),
          Group(
            name: 'Student Activities',
            memberCount: 856,
            lastMessage: 'Basketball tournament registration open',
            lastMessageTime: DateTime.now().subtract(const Duration(hours: 1)),
            unreadCount: 0,
          ),
        ], users: [],
      ),
      Community(
        '2',
        name: 'Neighborhood Watch',
        description: 'Community updates and safety alerts',
        memberCount: 450,
        lastActivity: DateTime.now().subtract(const Duration(hours: 2)),
        hasUnread: false,
        groups: [
          Group(
            name: 'Safety Alerts',
            memberCount: 450,
            lastMessage: 'Monthly community meeting tomorrow',
            lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
            unreadCount: 0,
          ),
        ], users: [],
      ),
      Community(
        '3',
        name: 'Tech Enthusiasts',
        description: 'Discussions about latest technology',
        memberCount: 780,
        lastActivity: DateTime.now().subtract(const Duration(minutes: 30)),
        hasUnread: true,
        groups: [
          Group(
            name: 'AI Discussions',
            memberCount: 456,
            lastMessage: 'Check out this new AI model!',
            lastMessageTime: DateTime.now().subtract(const Duration(minutes: 30)),
            unreadCount: 5,
          ),
          Group(
            name: 'Programming Help',
            memberCount: 634,
            lastMessage: 'Anyone familiar with Flutter?',
            lastMessageTime: DateTime.now().subtract(const Duration(hours: 1)),
            unreadCount: 1,
          ),
        ], users: [],
      ),
    ];

    // Eski verilerle birlikte başlatıyoruz.
    _communitiesSubject.add(_currentCommunities);
  }


  void _updateRandomCommunity() {
    if (_currentCommunities.isNotEmpty) {
      final randomCommunityIndex = DateTime.now().millisecond % _currentCommunities.length;
      final randomGroupIndex = DateTime.now().millisecond %
          _currentCommunities[randomCommunityIndex].groups.length;

      final updatedGroups = List<Group>.from(_currentCommunities[randomCommunityIndex].groups);
      updatedGroups[randomGroupIndex] = Group(
        name: updatedGroups[randomGroupIndex].name,
        memberCount: updatedGroups[randomGroupIndex].memberCount,
        lastMessage: 'New update ${DateTime.now().minute}',
        lastMessageTime: DateTime.now(),
        unreadCount: updatedGroups[randomGroupIndex].unreadCount + 1,
      );

      _currentCommunities[randomCommunityIndex] = Community(
        '4',
        name: _currentCommunities[randomCommunityIndex].name,
        description: _currentCommunities[randomCommunityIndex].description,
        memberCount: _currentCommunities[randomCommunityIndex].memberCount,
        groups: updatedGroups,
        lastActivity: DateTime.now(),
        hasUnread: true,
        imageUrl: _currentCommunities[randomCommunityIndex].imageUrl, users: [],
      );

      _communitiesSubject.add(_currentCommunities);
    }
  }

  String _getTimeString(DateTime timestamp) {
    final now = DateTime.now();
    if (timestamp.day == now.day) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (timestamp.day == now.day - 1) {
      return 'Yesterday';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  Widget _buildCommunityAvatar(Community community) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.teal[700],
        borderRadius: BorderRadius.circular(16),
      ),
      width: 50,
      height: 50,
      child: community.imageUrl != null
          ? Image.network(community.imageUrl!)
          : Center(
        child: Text(
          community.name[0],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Community>>(
      stream: _communitiesSubject.stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          children: [
            // New Community Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListTile(
                leading: Container(
                  decoration: BoxDecoration(
                    color: Colors.teal[700],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  width: 50,
                  height: 50,
                  child: const Icon(
                    Icons.groups,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                title: const Text(
                  'New community',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  _addNewCommunity();
                },
              ),
            ),

            const Divider(color: Colors.grey, height: 1),

            // Communities List
            ...snapshot.data!.map((community) => ExpansionTile(
              leading: _buildCommunityAvatar(community),
              title: Text(
                community.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                '${community.memberCount} members',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 13,
                ),
              ),
              children: [
                ...community.groups.map((group) => ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 8,
                  ),
                  title: Text(
                    group.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    group.lastMessage,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _getTimeString(group.lastMessageTime),
                        style: TextStyle(
                          color: group.unreadCount > 0
                              ? Colors.teal[400]
                              : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      if (group.unreadCount > 0) ...[
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.teal[400],
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            group.unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                )),
              ],
            )),
          ],
        );
      },
    );
  }
}