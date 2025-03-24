import 'package:flutter/material.dart';
import 'package:rxdart/subjects.dart';
import 'dart:async';

class StatusUpdate {
  final String name;
  final String? imageUrl;
  final DateTime timestamp;
  final bool isMuted;
  final List<String> updates;
  final bool isViewed;

  StatusUpdate({
    required this.name,
    this.imageUrl,
    required this.timestamp,
    required this.isMuted,
    required this.updates,
    required this.isViewed,
  });
}

class UpdatesPage extends StatefulWidget {
  const UpdatesPage({super.key});

  @override
  State<UpdatesPage> createState() => _UpdatesPageState();
}

class _UpdatesPageState extends State<UpdatesPage> {
  final BehaviorSubject<List<StatusUpdate>> _updatesSubject = BehaviorSubject<List<StatusUpdate>>();
  Timer? _timer;
  List<StatusUpdate> _currentUpdates = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _updateRandomStatus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _updatesSubject.close();
    super.dispose();
  }

  void _loadInitialData() {
    _currentUpdates = [
      StatusUpdate(
        name: 'My status',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        isMuted: false,
        updates: ['Tap to add status update'],
        isViewed: false,
      ),
      StatusUpdate(
        name: 'John Smith',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        isMuted: false,
        updates: ['Today, 10:30 AM'],
        isViewed: false,
      ),
      StatusUpdate(
        name: 'Alice Johnson',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        isMuted: false,
        updates: ['Today, 9:45 AM', 'Today, 9:50 AM'],
        isViewed: false,
      ),
      StatusUpdate(
        name: 'Work Group',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        isMuted: true,
        updates: ['3 updates'],
        isViewed: true,
      ),
    ];
    _updatesSubject.add(_currentUpdates);
  }

  void _updateRandomStatus() {
    if (_currentUpdates.isNotEmpty) {
      final randomIndex = DateTime.now().millisecond % (_currentUpdates.length - 1) + 1;
      _currentUpdates[randomIndex] = StatusUpdate(
        name: _currentUpdates[randomIndex].name,
        timestamp: DateTime.now(),
        isMuted: _currentUpdates[randomIndex].isMuted,
        updates: [..._currentUpdates[randomIndex].updates, 'Just now'],
        isViewed: false,
      );
      _updatesSubject.add(_currentUpdates);
    }
  }

  String _getTimeString(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return 'Yesterday';
    }
  }

  Widget _buildAvatar(StatusUpdate update) {
    return Stack(
      children: [
        CircleAvatar(
          backgroundColor: Colors.teal[700],
          radius: 25,
          child: update.imageUrl != null
              ? CircleAvatar(
            backgroundImage: NetworkImage(update.imageUrl!),
            radius: 24,
          )
              : Text(
            update.name[0],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (update.name == 'My status')
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.teal,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF121B22), width: 2),
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StatusUpdate>>(
      stream: _updatesSubject.stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final myStatus = snapshot.data!.first;
        final recentUpdates = snapshot.data!.skip(1).toList();

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status section
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: _buildAvatar(myStatus),
                title: Text(
                  myStatus.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  myStatus.updates.first,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 13,
                  ),
                ),
              ),

              // Recent updates header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Recent updates',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Recent updates list
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentUpdates.length,
                itemBuilder: (context, index) {
                  final update = recentUpdates[index];
                  return Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.withOpacity(0.1),
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: update.isViewed ? Colors.grey : Colors.teal,
                            width: 2,
                          ),
                        ),
                        child: _buildAvatar(update),
                      ),
                      title: Text(
                        update.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        _getTimeString(update.timestamp),
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13,
                        ),
                      ),
                      trailing: update.isMuted
                          ? Icon(
                        Icons.volume_off,
                        color: Colors.grey[400],
                        size: 20,
                      )
                          : null,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}