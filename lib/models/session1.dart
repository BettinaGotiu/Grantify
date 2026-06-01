import 'package:cloud_firestore/cloud_firestore.dart';

class Session1 {
  final String sessionId;
  final String userId;
  final Timestamp loginTimestamp;
  final Timestamp lastActive;
  final bool isActive;

  Session1({
    required this.sessionId,
    required this.userId,
    required this.loginTimestamp,
    required this.lastActive,
    required this.isActive,
  });

  /// Factory constructor to create a Session1 instance from Firestore document data
  factory Session1.fromMap(String docId, Map<String, dynamic> map) {
    return Session1(
      sessionId: docId,
      userId: map['userId'] ?? '',
      loginTimestamp: map['login_timestamp'] ?? Timestamp.now(),
      lastActive: map['last_active'] ?? Timestamp.now(),
      isActive: map['is_active'] ?? false,
    );
  }

  /// Converts the Session1 instance to a map suited for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'login_timestamp': loginTimestamp,
      'last_active': lastActive,
      'is_active': isActive,
    };
  }
}
