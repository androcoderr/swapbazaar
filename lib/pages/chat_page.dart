import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:provider/provider.dart';
import 'package:whatslab_4_everyone_2_latest/components/poll.dart';
import 'package:whatslab_4_everyone_2_latest/services/gemini_api_service.dart';
import '../hive_models/chat_hive_model.dart';
import '../models/chat_message_model.dart';
import '../models/user_model.dart';
import '../providers/user_mail_provider.dart';
import '../services/chat_service.dart';
import '../services/socket_service.dart';
import '../static/emoji_map.dart';

class ChatPage extends StatefulWidget {
  final User user;
  final ChatSocketService socketService;
  final String userMail;

  ChatPage({required this.user, required this.socketService,required this.userMail});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<ChatMessage> messages = [];
  late TextEditingController textEditingController;
  final ChatService chatService = ChatService();
  final ScrollController _scrollController = ScrollController(); // ScrollController ekleyin
  StreamSubscription? _chatSubscription; // Stream subscription'ı tutmak için
  bool isOtherPersonWriting = false;

  @override
  void initState() {
    super.initState();
    textEditingController = TextEditingController();

    try {
      widget.socketService.chatStream.listen(
            (newMessage) {
          if (mounted &&
              newMessage.fromUserMail.isNotEmpty &&
              newMessage.toUserMail.isNotEmpty) {
            if ((newMessage.fromUserMail == widget.user.mail &&
                newMessage.toUserMail == widget.userMail) ||
                (newMessage.toUserMail == widget.user.mail &&
                    newMessage.fromUserMail == widget.userMail)) {

              if (newMessage.content == '..') {
                setState(() {
                  isOtherPersonWriting = true;
                });
              }
              else if (newMessage.content == '[free]') {
                setState(() {
                  isOtherPersonWriting = false;
                });
              }
              else {
                setState(() {
                  isOtherPersonWriting = false;
                });
                setState(() {
                  messages.add(newMessage);
                });
              }

            }
          }
        },
        onError: (error) {
          print('Stream error: $error');
        },
      );
    } catch (e) {
      print('Error setting up chat stream: $e');
    }

    loadMessages();
  }

  @override
  void dispose() {
    textEditingController.dispose();
    _scrollController.dispose();
    _chatSubscription?.cancel(); // Stream subscription'ı temizle

    if (messages.isNotEmpty) {
      List<Chat> saveChats = messages.map((msg) => Chat(
        fromUserMail: msg.fromUserMail,
        toUserMail: msg.toUserMail,
        content: msg.content,
      )).toList();

      chatService.saveMessagesIfNew(saveChats);
    }

    super.dispose();
  }

  void loadMessages() async {
    if (messages.isNotEmpty) return;

    try {
      if (widget.user.mail != null) {
        List<Chat> loadedMessages = await chatService.loadMessagesForUser(widget.user.mail);
        if (mounted) { // Widget hala mount edilmiş mi kontrol et
          setState(() {
            messages.addAll(loadedMessages.map((chat) => ChatMessage(
              fromUserMail: chat.fromUserMail,
              toUserMail: chat.toUserMail,
              content: chat.content,
            )));
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      print('Error loading messages: $e');
    }
  }

  void _scrollToBottom() {
    if (!mounted) return; // mounted kontrolü

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _sendIsOtherWriting() {
    if (textEditingController.text.isNotEmpty && widget.socketService != null) {
      final newMessage = ChatMessage(
        fromUserMail: widget.userMail,
        toUserMail: widget.user.mail,
        content: "..",
      );

      try {
        widget.socketService.sendMessage(newMessage);
      } catch (e) {
        print('Error sending message: $e');
      }
    }
  }

  void _sendFree() {
    final newMessage = ChatMessage(
      fromUserMail: widget.userMail,
      toUserMail: widget.user.mail,
      content: "[free]",
    );

    try {
      widget.socketService.sendMessage(newMessage);
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  void _sendMessage() {
    if (textEditingController.text.isNotEmpty && widget.socketService != null) {
      final newMessage = ChatMessage(
        fromUserMail: widget.userMail,
        toUserMail: widget.user.mail,
        content: textEditingController.text,
      );

      setState(() {
        messages.add(newMessage);
      });

      try {
        widget.socketService.sendMessage(newMessage);
      } catch (e) {
        print('Error sending message: $e');
        // Hata durumunda kullanıcıya bilgi verilebilir
      }

      textEditingController.clear();
      _scrollToBottom();
    }
  }

  void _showAttachmentDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Render taşmasını engellemek için önemli.
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          height: MediaQuery.of(context).size.height * 0.4, // Ekran boyutuna göre ayarlanır.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Expanded(
                child: GridView(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  children: [
                    _buildOption(Icons.insert_drive_file, 'File', Colors.red,(){
                      
                    }),
                    _buildOption(Icons.photo, 'Photo', Colors.green,() {}),
                    _buildOption(Icons.location_on, 'Location', Colors.blue,(){}),
                    _buildOption(Icons.poll, 'Poll', Colors.orange,(){
                      showPollCreationDialog(context, (pollData) {
                        _addPollMessage(pollData);
                        ChatMessage newPollChatMessage = ChatMessage(fromUserMail: widget.userMail, toUserMail: widget.user.mail, content: pollData);
                        widget.socketService.sendMessage(newPollChatMessage);
                      });
                    }),
                    _buildOption(Icons.person, 'Contact', Colors.purple,(){}),
                    _buildOption(Icons.info_outlined, 'Ask gemini', Colors.blue,() async {
                      String prompt = "Gemini, en fazla 3 cümle kurmanı istiyorum ve bana bu text'i daha iyi hale getir. İşte text:";
                      String text = textEditingController.text;

                      String fullPrompt = "$prompt $text";

                      textEditingController.clear();

                      Gemini.instance.prompt(parts: [
                        Part.text(fullPrompt),
                      ]).then((value) {
                        print(value?.output);
                        setState(() {
                          textEditingController.text = value!.output!;
                        });
                      }).catchError((e) {
                        print('error ${e}');
                      });

                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOption(IconData icon, String label, Color color,dynamic onTap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(child: CircleAvatar(
          radius: 30,
          backgroundColor: color.withOpacity(0.2),
          child: Icon(
            icon,
            size: 30,
            color: color,
          ),
        ) , onTap: () {onTap();},),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }



  void showUserDetails(BuildContext context, String name, String email, String profileImageUrl) {
    showDialog(
      context: context,
      barrierDismissible: true, // Dışarıya tıklandığında kapanmasını sağlar
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(profileImageUrl),
                  radius: 50, // Daha büyük profil resmi
                ),
                SizedBox(height: 16),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[800],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context); // Dialog'ı kapat
                      },
                      icon: Icon(Icons.chat),
                      label: Text("Mesaj"),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black, backgroundColor: Colors.grey[200],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context); // Dialog'ı kapat
                      },
                      icon: Icon(Icons.info_outline),
                      label: Text("Daha Fazla"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showPollCreationDialog(BuildContext context, Function(String) onPollCreated) {
    final TextEditingController questionController = TextEditingController();
    final TextEditingController optionsController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Create Poll"),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: questionController,
                  decoration: const InputDecoration(
                    labelText: "Question",
                    hintText: "Enter your poll question",
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: optionsController,
                  decoration: const InputDecoration(
                    labelText: "Options (comma-separated)",
                    hintText: "Option1, Option2, Option3",
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dialogu kapat
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final question = questionController.text.trim();
                final options = optionsController.text.trim();

                if (question.isNotEmpty && options.isNotEmpty) {
                  onPollCreated("$question|$options"); // Veriyi formatlayıp geri döndür
                  Navigator.of(context).pop(); // Dialogu kapat
                }
              },
              child: const Text("Create"),
            ),
          ],
        );
      },
    );
  }

  void _addPollMessage(String pollData) {
    final pollMessage = ChatMessage(
      fromUserMail: widget.userMail,
      toUserMail: widget.user.mail,
      content: pollData, // "Question|Option1,Option2,Option3" formatında
    );

    pollMessage.messageType = MessageType.POLL;

    setState(() {
      messages.add(pollMessage); // Mesaj listesine ekle
    });

    // ListView'in en alta kayması için bir kontrol:
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  void showEmojiPicker(BuildContext context, TextEditingController controller) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        // Emoji isimleri ve sembolleri

        // Arama filtresi için liste
        List<MapEntry<String, String>> filteredEmojis = emojiMap.entries.toList();

        return StatefulBuilder(
          builder: (context, setState) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    onChanged: (value) {
                      // Arama işlemi
                      setState(() {
                        filteredEmojis = emojiMap.entries
                            .where((entry) =>
                            entry.key.toLowerCase().contains(value.toLowerCase()))
                            .toList();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search emoji...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: filteredEmojis.length,
                    itemBuilder: (context, index) {
                      final emoji = filteredEmojis[index];
                      return GestureDetector(
                        onTap: () {
                          // Emoji seçimi
                          controller.text += emoji.value;
                          controller.selection = TextSelection.fromPosition(
                            TextPosition(offset: controller.text.length),
                          );
                          //Navigator.pop(context); // Modal'ı kapat
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              emoji.value,
                              style: TextStyle(fontSize: 30),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }




  @override
  Widget build(BuildContext context) {
    final userMail = Provider.of<UserProvider>(context, listen: false).userMail;


    return Scaffold(
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 40.0, left: 20.0), // Konum ayarı
        child: Align(
          alignment: Alignment.bottomLeft,
          child: isOtherPersonWriting
              ? FloatingActionButton.small( // Küçük FAB
            onPressed: () {},
            child: Icon(
              Icons.message_outlined,
              color: Colors.grey,
              size: 20, // Daha küçük bir simge
            ),
            backgroundColor: Colors.blueGrey,
          )
              : null,
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.teal[800], // WhatsApp'ın yeşil tonu
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            GestureDetector(
              onTap: () {
                showUserDetails(
                  context,
                  widget.user.name,
                  widget.user.mail,
                  widget.user.profileImageUrl,
                );
              },
              child: CircleAvatar(
                backgroundImage: NetworkImage(widget.user.profileImageUrl),
                radius: 20,
              ),
            ),
            SizedBox(width: 10), // Profil resmi ile ad arasında boşluk
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.user.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  "Çevrimiçi", // Örnek bir durum
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.videocam, color: Colors.white),
            onPressed: () {
              // Video arama işlevi
            },
          ),
          IconButton(
            icon: Icon(Icons.call, color: Colors.white),
            onPressed: () {
              // Sesli arama işlevi
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == "delete") {
                chatService.removeAllChat(widget.user.mail);
                setState(() {
                  messages.clear();
                });
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: "delete",
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 10),
                    Text("Sohbeti Sil"),
                  ],
                ),
              ),
            ],
            icon: Icon(Icons.more_vert, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          // Mesaj listesi
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isMine = message.fromUserMail == userMail;
                return Align(
                  alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: EdgeInsets.all(10),
                    margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    decoration: BoxDecoration(
                      color: isMine ? Colors.greenAccent : Colors.grey[300],
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                        bottomLeft: isMine ? Radius.circular(10) : Radius.zero,
                        bottomRight: isMine ? Radius.zero : Radius.circular(10),
                      ),
                    ),
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: 280, // İstediğiniz maksimum genişliği buraya girin
                        ),
                        child: message.content.contains('|')
                            ? SimplePollWidget(
                          question: message.content.split('|')[0],
                          options: message.content.split('|')[1].split(','),
                        )
                            : Text(message.content,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 10,
                        ),
                      ),
                  ),
                );
              },
            ),
          ),
          // Mesaj gönderme alanı
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                IconButton(icon: Icon(Icons.emoji_emotions), onPressed: () {
                  showEmojiPicker(context, textEditingController);
                }),
                IconButton(icon: Icon(Icons.attach_file), onPressed: (){_showAttachmentDetails(context);}),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      controller: textEditingController,
                      decoration: InputDecoration(
                        hintText: 'Type a message',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onChanged: (value) {
                        if (textEditingController.text.isEmpty) {
                          _sendFree();
                        }
                        _sendIsOtherWriting();
                      },
                    ),
                  ),
                ),
                SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: CircleAvatar(
                    backgroundColor: Colors.teal,
                    child: Icon(
                      textEditingController.text.isNotEmpty ? Icons.send : Icons.mic,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
