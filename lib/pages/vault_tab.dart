import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/app_style.dart';
import '../widgets/neon_card.dart';

class VaultTab extends StatefulWidget {
  const VaultTab({super.key});

  @override
  State<VaultTab> createState() => _VaultTabState();
}

class _VaultTabState extends State<VaultTab> {
  final String _uid = FirebaseAuth.instance.currentUser!.uid;

  // Formats date into standard European day/month/year format
  String _formatSavedDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day/$month/$year';
  }

  // Opens a custom stateful checklist wireframe popup showing required documents
  void _showDetailsDialog(BuildContext context, String grantTitle, List<String> docs) {
    List<bool> checkedStates = List.generate(docs.length, (_) => false);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                child: Text(
                  grantTitle,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
              ),
              content: docs.isEmpty
                  ? const Text(
                      'Nu sunt documente înregistrate în baza de date.',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    )
                  : SizedBox(
                      width: double.maxFinite,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'CHECKLIST DOCUMENTE NECESARE:',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.black54),
                          ),
                          const SizedBox(height: 8),
                          Flexible(
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: docs.length,
                              itemBuilder: (context, index) {
                                return CheckboxListTile(
                                  activeColor: AppStyle.accentPurple,
                                  title: Text(
                                    docs[index],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      decoration: checkedStates[index]
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                  value: checkedStates[index],
                                  onChanged: (bool? val) {
                                    setDialogState(() {
                                      checkedStates[index] = val ?? false;
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Închide',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Deletes an entry from historyvault1 collection
  Future<void> _deleteVaultItem(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('historyvault1').doc(docId).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Proiect eliminat!'),
          backgroundColor: Colors.black,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare la ștergerea analizei: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VAULT-UL MEU'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('historyvault1')
              .where('userId', isEqualTo: _uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Nicio analiză salvată în Firebase Firestore',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                
                final Timestamp timestamp = data['date_saved'] ?? Timestamp.now();
                final dateStr = _formatSavedDate(timestamp);
                
                final userProfile = data['user_profile'] ?? {};
                final caen = userProfile['caen'] ?? '';
                final location = userProfile['locatie'] ?? '';
                final vechime = userProfile['vechime'] ?? 0;

                final List<dynamic> matchedList = data['matched_grants'] ?? [];
                
                // Fetch first matched grant specs
                String grantTitle = 'Fond Potrivit';
                List<String> docsNeeded = [];
                if (matchedList.isNotEmpty) {
                  final firstMatch = matchedList[0] as Map<String, dynamic>;
                  grantTitle = firstMatch['titlu'] ?? 'Fond Potrivit';
                  docsNeeded = List<String>.from(firstMatch['documente_necesare'] ?? []);
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: AppStyle.cartoonDecoration(
                    color: Colors.white,
                    borderRadius: 12,
                    shadowOffset: const Offset(4, 4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Date saved
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Salvat la: $dateStr',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54),
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: AppStyle.cartoonDecoration(
                              color: AppStyle.primaryYellow,
                              borderRadius: 4,
                              shadowOffset: const Offset(1, 1),
                            ),
                            child: const Icon(Icons.bookmark, size: 14),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Associated Grant Name
                      Text(
                        grantTitle,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black),
                      ),
                      const SizedBox(height: 8),

                      // Profile variables
                      Text(
                        'Profil utilizat: CAEN $caen | Locație $location | Vechime $vechime ani',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.black, thickness: 1.5, height: 16),

                      // Actions section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Button 1: Vezi Detalii (checklist)
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.black, width: 2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onPressed: () => _showDetailsDialog(context, grantTitle, docsNeeded),
                            icon: const Icon(Icons.playlist_add_check, color: Colors.black, size: 18),
                            label: const Text(
                              'Vezi Detalii',
                              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Button 2: Șterge
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppStyle.accentRed,
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.black, width: 2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              elevation: 0,
                            ),
                            onPressed: () => _deleteVaultItem(doc.id),
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text(
                              'Șterge',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
