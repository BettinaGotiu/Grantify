import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:itec/services/friends_service.dart';

import '../models/friend.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/neon_card.dart';
import '../widgets/friend_requests_widget.dart';
import '../core/app_style.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _searchCtrl = TextEditingController();
  bool _searching = false;
  List<Friend> _results = const [];

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  // Stream which reads friends from the users collection
  Stream<List<Friend>> _friendsStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .snapshots()
        .asyncMap((doc) async {
          if (!doc.exists) return [];

          final data = doc.data() as Map<String, dynamic>;
          final List<dynamic> friendIds = data['friends'] ?? [];
          if (friendIds.isEmpty) return [];

          List<Friend> friendsList = [];

          for (String id in friendIds) {
            final fDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(id)
                .get();
            if (fDoc.exists) {
              final fData = fDoc.data()!;
              friendsList.add(
                Friend.fromJson({
                  'uid': id,
                  'username':
                      fData['username'] ??
                      fData['email']?.split('@')[0] ??
                      'Unknown Player',
                  'email': fData['email'] ?? '',
                  'profilePic':
                      fData['profilePic'] ?? 'assets/profile_pics/pic1.png',
                }),
              );
            }
          }
          return friendsList;
        });
  }

  Future<void> _searchUsers() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) {
      setState(() => _results = const []);
      return;
    }

    setState(() => _searching = true);

    try {
      final byEmail = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: q)
          .limit(10)
          .get();

      final byUsername = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: q)
          .limit(10)
          .get();

      final docs = [...byEmail.docs, ...byUsername.docs];
      final seen = <String>{};
      final users = <Friend>[];

      for (final doc in docs) {
        if (doc.id == _uid || seen.contains(doc.id)) continue;
        seen.add(doc.id);

        final dData = doc.data();
        users.add(
          Friend.fromJson({
            'uid': doc.id,
            'username':
                dData['username'] ?? dData['email']?.split('@')[0] ?? 'Unknown',
            'email': dData['email'] ?? '',
            'profilePic':
                dData['profilePic'] ?? 'assets/profile_pics/pic1.png',
          }),
        );
      }

      if (mounted) {
        setState(() => _results = users);
      }
    } finally {
      if (mounted) {
        setState(() => _searching = false);
      }
    }
  }

  Future<void> _sendRequest(Friend target) async {
    final friendsService = FriendsService();
    await friendsService.sendFriendRequest(target.uid);

    if (!mounted) return;

    setState(() {
      _results.removeWhere((f) => f.uid == target.uid);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cerere de prietenie trimisă lui ${target.username}!'),
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PRIETENI'),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: FriendRequestsWidget(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                children: [
                  // Căutare Prieteni
                  NeonCard(
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.person_search, color: Colors.black),
                            SizedBox(width: 8),
                            Text(
                              'Caută Prieteni Noi',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _searchCtrl,
                          label: 'Introdu email sau username exact',
                          prefixIcon: Icons.search,
                        ),
                        const SizedBox(height: 16),
                        AppButton(
                          label: 'Caută',
                          onPressed: _searchUsers,
                          loading: _searching,
                          backgroundColor: AppStyle.primaryYellow,
                          textColor: Colors.black,
                          icon: Icons.person_search,
                        ),
                        if (_results.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Divider(color: Colors.black, thickness: 1.5),
                          ..._results.map(
                            (f) => Container(
                              margin: const EdgeInsets.only(top: 8),
                              decoration: AppStyle.cartoonDecoration(
                                color: Colors.grey[50]!,
                                borderRadius: 8,
                                shadowOffset: const Offset(2, 2),
                              ),
                              child: ListTile(
                                leading: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.black, width: 1.5),
                                  ),
                                  child: CircleAvatar(
                                    backgroundImage: AssetImage(f.profilePic),
                                    onBackgroundImageError: (exception, stackTrace) {},
                                    backgroundColor: Colors.grey[300],
                                  ),
                                ),
                                title: Text(
                                  f.username,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                  ),
                                ),
                                subtitle: Text(
                                  f.email,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.person_add_alt_1,
                                    color: AppStyle.accentPurple,
                                    size: 26,
                                  ),
                                  onPressed: () => _sendRequest(f),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Lista Prieteni Curenți
                  NeonCard(
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.people, color: Colors.black),
                            SizedBox(width: 8),
                            Text(
                              'Prietenii Tăi',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        StreamBuilder<List<Friend>>(
                          stream: _friendsStream(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            if (snapshot.hasError) {
                              return const Padding(
                                padding: EdgeInsets.all(8),
                                child: Text(
                                  'Eroare la încărcarea prietenilor.',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: AppStyle.accentRed),
                                ),
                              );
                            }

                            final friends = snapshot.data ?? [];

                            if (friends.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Text(
                                  'Nu ai adăugat niciun prieten încă.',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            }

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: friends.length,
                              itemBuilder: (_, i) {
                                final f = friends[i];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: AppStyle.cartoonDecoration(
                                    color: Colors.white,
                                    borderRadius: 10,
                                    shadowOffset: const Offset(2, 2),
                                  ),
                                  child: ListTile(
                                    leading: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.black, width: 1.5),
                                      ),
                                      child: CircleAvatar(
                                        backgroundImage: AssetImage(f.profilePic),
                                        onBackgroundImageError: (exception, stackTrace) {},
                                        backgroundColor: Colors.grey[300],
                                      ),
                                    ),
                                    title: Text(
                                      f.username,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: Colors.black,
                                      ),
                                    ),
                                    subtitle: Text(
                                      f.email,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.message,
                                        color: AppStyle.accentPurple,
                                      ),
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Chat-ul cu ${f.username} va fi disponibil curând!',
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
