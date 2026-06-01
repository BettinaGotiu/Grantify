import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/friends_service.dart';
import '../core/app_style.dart';

class FriendRequestsWidget extends StatelessWidget {
  const FriendRequestsWidget({super.key});

  void _showRequestsDialog(BuildContext context, List<dynamic> requestIds) {
    final friendsService = FriendsService();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.black, width: 2),
          ),
          title: Container(
            padding: const EdgeInsets.all(8),
            decoration: AppStyle.cartoonDecoration(
              color: AppStyle.primaryYellow,
              borderRadius: 6,
              shadowOffset: const Offset(2, 2),
            ),
            child: const Text(
              'Cereri de Prietenie',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
          content: requestIds.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    "Nu ai cereri noi de prietenie.",
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                )
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: requestIds.length,
                    itemBuilder: (context, index) {
                      String senderId = requestIds[index];

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(senderId)
                            .get(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const ListTile(title: Text("Încărcare..."));
                          }

                          var data =
                              snapshot.data!.data() as Map<String, dynamic>?;

                          String username = data?['username'] ?? 'Utilizator Necunoscut';
                          String email = data?['email'] ?? 'Fără email';
                          String photoUrl = data?['profilePic'] ?? 'assets/profile_pics/pic1.png';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: AppStyle.cartoonDecoration(
                              color: Colors.grey[50]!,
                              borderRadius: 8,
                              shadowOffset: const Offset(1, 1),
                            ),
                            child: ListTile(
                              leading: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.black, width: 1),
                                ),
                                child: CircleAvatar(
                                  backgroundImage: AssetImage(photoUrl),
                                  backgroundColor: Colors.grey[300],
                                ),
                              ),
                              title: Text(
                                username,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              subtitle: Text(
                                email,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Decline Button
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: AppStyle.accentRed,
                                    ),
                                    onPressed: () async {
                                      await friendsService.declineFriendRequest(
                                        senderId,
                                      );
                                      if (context.mounted) Navigator.pop(context);
                                    },
                                  ),
                                  // Accept Button
                                  IconButton(
                                    icon: const Icon(
                                      Icons.check,
                                      color: AppStyle.accentGreen,
                                    ),
                                    onPressed: () async {
                                      await friendsService.acceptFriendRequest(
                                        senderId,
                                      );
                                      if (context.mounted) Navigator.pop(context);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Închide', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final friendsService = FriendsService();
    String? currentId = friendsService.currentUserId;

    if (currentId == null) return const SizedBox();

    return StreamBuilder<DocumentSnapshot>(
      stream: friendsService.getUserData(currentId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () => _showRequestsDialog(context, []),
          );
        }

        var data = snapshot.data!.data() as Map<String, dynamic>?;
        List<dynamic> requests = data?['friendRequests'] ?? [];

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(
                requests.isNotEmpty
                    ? Icons.notifications_active
                    : Icons.notifications_none,
                color: requests.isNotEmpty ? AppStyle.accentRed : Colors.black,
                size: 26,
              ),
              onPressed: () => _showRequestsDialog(context, requests),
            ),
            if (requests.isNotEmpty)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppStyle.accentRed,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${requests.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
