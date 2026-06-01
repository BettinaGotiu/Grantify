import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user1.dart';
import '../models/session1.dart';
import '../models/history_vault1.dart';
import '../models/grant1.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Collection References ---
  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _firestore.collection('users1');

  CollectionReference<Map<String, dynamic>> get _sessionsCol =>
      _firestore.collection('sessions1');

  CollectionReference<Map<String, dynamic>> get _historyCol =>
      _firestore.collection('historyvault1');

  CollectionReference<Map<String, dynamic>> get _grantsCol =>
      _firestore.collection('grants1');

  // --- Sessions1 Operations ---

  /// Creates a new active session or updates an existing session document in Firestore
  Future<void> createOrUpdateSession(String sessionId, String userId) async {
    final now = Timestamp.now();
    final sessionData = Session1(
      sessionId: sessionId,
      userId: userId,
      loginTimestamp: now,
      lastActive: now,
      isActive: true,
    );
    await _sessionsCol.doc(sessionId).set(sessionData.toMap(), SetOptions(merge: true));
  }

  /// Marks a session as inactive (isActive = false) upon logout
  Future<void> deactivateSession(String sessionId) async {
    await _sessionsCol.doc(sessionId).update({
      'is_active': false,
      'last_active': Timestamp.now(),
    });
  }

  /// Deletes a session document entirely from Firestore
  Future<void> deleteSession(String sessionId) async {
    await _sessionsCol.doc(sessionId).delete();
  }

  // --- Grants1 Operations ---

  /// Adds a new grant to the grants1 collection (for administrators)
  Future<void> addGrant(Grant1 grant) async {
    // If grantId is empty, Firestore can auto-generate it or we can set it.
    // We set using the specified grantId.
    final docRef = grant.grantId.isEmpty
        ? _grantsCol.doc()
        : _grantsCol.doc(grant.grantId);

    final finalGrant = Grant1(
      grantId: docRef.id,
      titlu: grant.titlu,
      sumaMaxima: grant.sumaMaxima,
      criteriiHard: grant.criteriiHard,
      documenteNecesare: grant.documenteNecesare,
    );

    await docRef.set(finalGrant.toMap());
  }

  /// Retrieves a stream of all grants in grants1
  Stream<List<Grant1>> streamGrants() {
    return _grantsCol.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Grant1.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // --- HistoryVault1 Operations ---

  /// Saves or updates a matching/profile analysis in historyvault1
  Future<void> saveAnalysis(HistoryVault1 vault) async {
    final docRef = vault.vaultId.isEmpty
        ? _historyCol.doc()
        : _historyCol.doc(vault.vaultId);

    final finalVault = HistoryVault1(
      vaultId: docRef.id,
      userId: vault.userId,
      dateSaved: Timestamp.now(),
      userProfile: vault.userProfile,
      matchedGrants: vault.matchedGrants,
    );

    await docRef.set(finalVault.toMap());
  }

  /// Deletes an analysis entry from historyvault1 by its document ID
  Future<void> deleteAnalysis(String vaultId) async {
    await _historyCol.doc(vaultId).delete();
  }

  /// Stream of user-specific saved history vaults from historyvault1
  Stream<List<HistoryVault1>> streamUserHistory(String userId) {
    return _historyCol
        .where('userId', isEqualTo: userId)
        .orderBy('date_saved', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return HistoryVault1.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // --- Users1 / Subscribed Topics Operations ---

  /// Toggles a topic in the subscribed_topics field within the users1 collection.
  /// If the topic exists, it is removed; if it does not, it is added.
  Future<void> toggleSubscribedTopic(String userId, String topic) async {
    final userDocRef = _usersCol.doc(userId);
    
    // We retrieve the document first to check the current subscription state
    final docSnap = await userDocRef.get();
    
    if (docSnap.exists) {
      final data = docSnap.data();
      final List<dynamic> subscribed = data?['subscribed_topics'] ?? [];
      
      if (subscribed.contains(topic)) {
        // Topic exists, remove it
        await userDocRef.update({
          'subscribed_topics': FieldValue.arrayRemove([topic]),
        });
      } else {
        // Topic does not exist, add it
        await userDocRef.update({
          'subscribed_topics': FieldValue.arrayUnion([topic]),
        });
      }
    } else {
      // Document does not exist yet, create it with the topic subscribed
      final newUser = User1(
        userId: userId,
        email: '',
        isAdmin: false,
        friends: [],
        subscribedTopics: [topic],
        settings: {},
      );
      await userDocRef.set(newUser.toMap());
    }
  }

  /// Streams user data from the users1 collection
  Stream<User1?> streamUser(String userId) {
    return _usersCol.doc(userId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return User1.fromMap(doc.id, doc.data()!);
    });
  }
}
