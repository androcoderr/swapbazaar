
class User {
  String name;
  String mail;
  String profileImageUrl;
  String hashedPassword;

  User({
    required this.name,
    required this.mail,
    required this.profileImageUrl,
    required this.hashedPassword,
  });

  // fromJson yöntemi
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'] ?? 'Unknown',
      mail: json['mail'] ?? 'Unknown',
      profileImageUrl: json['imageUrl'] ?? 'no-iamge',
      hashedPassword: json['hashedPassword'] ?? 'no-psw',
    );
  }

  // toJson yöntemi
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'mail': mail,
      'imageUrl': profileImageUrl,
      'hashedPassword': hashedPassword,
    };
  }

  // Listeden JSON'a dönüştürme
  static List<Map<String, dynamic>> listToJson(List<User> users) {
    return users.map((user) => user.toJson()).toList();
  }

  // JSON'dan listeye dönüştürme
  static List<User> listFromJson(List<dynamic> jsonList) {
    return jsonList.map((json) => User.fromJson(json)).toList();
  }
}