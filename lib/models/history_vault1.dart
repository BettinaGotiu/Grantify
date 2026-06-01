import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryVault1 {
  final String vaultId;
  final String userId;
  final Timestamp dateSaved;
  final Map<String, dynamic> userProfile; // caen, locatie, vechime
  final List<Map<String, dynamic>> matchedGrants;

  HistoryVault1({
    required this.vaultId,
    required this.userId,
    required this.dateSaved,
    required this.userProfile,
    required this.matchedGrants,
  });

  /// Factory constructor to create a HistoryVault1 instance from Firestore document data
  factory HistoryVault1.fromMap(String docId, Map<String, dynamic> map) {
    return HistoryVault1(
      vaultId: docId,
      userId: map['userId'] ?? '',
      dateSaved: map['date_saved'] ?? Timestamp.now(),
      userProfile: Map<String, dynamic>.from(map['user_profile'] ?? {}),
      matchedGrants: List<Map<String, dynamic>>.from(
        map['matched_grants'] ?? [],
      ),
    );
  }

  /// Converts the HistoryVault1 instance to a map suited for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'date_saved': dateSaved,
      'user_profile': userProfile,
      'matched_grants': matchedGrants,
    };
  }
}
