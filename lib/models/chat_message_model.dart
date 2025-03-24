
class ChatMessage {
  String fromUserMail;
  String toUserMail;
  String content;
  MessageType messageType = MessageType.TEXT;

  ChatMessage({
    required this.fromUserMail,
    required this.toUserMail,
    required this.content,
  });

  // fromJson yöntemi
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      fromUserMail: json['fromUserMail'],
      toUserMail: json['toUserMail'],
      content: json['content'],
    );
  }

  // toJson yöntemi
  Map<String, dynamic> toJson() {
    return {
      'fromUserMail': fromUserMail,
      'toUserMail': toUserMail,
      'content': content,
    };
  }

  // Listeden JSON'a dönüştürme
  static List<Map<String, dynamic>> listToJson(List<ChatMessage> chats) {
    return chats.map((chat) => chat.toJson()).toList();
  }

  // JSON'dan listeye dönüştürme
  static List<ChatMessage> listFromJson(List<dynamic> jsonList) {
    return jsonList.map((json) => ChatMessage.fromJson(json)).toList();
  }
}

enum MessageType {
  TEXT,
  POLL,
  IMAGE,
  VIDEO,
  CONTACT,
  FILE,
  LOCATION,
}