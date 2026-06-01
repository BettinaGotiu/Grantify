class User1 {
  final String userId;
  final String email;
  final bool isAdmin;
  final List<String> friends;
  final List<String> subscribedTopics;
  final Map<String, dynamic> settings;

  User1({
    required this.userId,
    required this.email,
    required this.isAdmin,
    required this.friends,
    required this.subscribedTopics,
    required this.settings,
  });

  /// Factory constructor to create a User1 instance from Firestore document data
  factory User1.fromMap(String docId, Map<String, dynamic> map) {
    return User1(
      userId: docId,
      email: map['email'] ?? '',
      isAdmin: map['isAdmin'] ?? false,
      friends: List<String>.from(map['friends'] ?? []),
      subscribedTopics: List<String>.from(map['subscribed_topics'] ?? []),
      settings: Map<String, dynamic>.from(map['settings'] ?? {}),
    );
  }

  /// Converts the User1 instance to a map suited for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'isAdmin': isAdmin,
      'friends': friends,
      'subscribed_topics': subscribedTopics,
      'settings': settings,
    };
  }
}
