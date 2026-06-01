import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';
import '../models/user1.dart';
import '../models/history_vault1.dart';
import '../models/grant1.dart';
import '../widgets/neon_card.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../core/app_style.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _db = DatabaseService();
  final String _uid = FirebaseAuth.instance.currentUser!.uid;

  // Form controllers for creating a new grant (Admin Only)
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _caenCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _docsCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _caenCtrl.dispose();
    _locationCtrl.dispose();
    _ageCtrl.dispose();
    _docsCtrl.dispose();
    super.dispose();
  }

  // Helper to simulate and save a new analysis history
  Future<void> _simulateNewAnalysis() async {
    final List<Map<String, dynamic>> mockMatchedGrants = [
      {
        'titlu': 'Grant Digitalizare IMM 2026',
        'suma_maxima': 50000.0,
        'cota_finantare': '90%',
      },
      {
        'titlu': 'Startup Nation - Tech Focus',
        'suma_maxima': 40000.0,
        'cota_finantare': '100%',
      }
    ];

    final mockVault = HistoryVault1(
      vaultId: '', // DatabaseService will generate a new document ID
      userId: _uid,
      dateSaved: Timestamp.now(),
      userProfile: {
        'caen': '6201 (Dezvoltare software)',
        'locatie': 'Urban (Cluj-Napoca)',
        'vechime': '2 ani',
      },
      matchedGrants: mockMatchedGrants,
    );

    try {
      await _db.saveAnalysis(mockVault);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Analiză simulată salvată în History Vault!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare la salvare: $e')),
      );
    }
  }

  // Opens a dialog to create a new grant
  void _showAddGrantDialog() {
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
              'Adaugă Grant Nou',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  AppTextField(controller: _titleCtrl, label: 'Titlu Grant'),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _amountCtrl,
                    label: 'Sumă Maximă (€)',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(controller: _caenCtrl, label: 'CAEN-uri eligibile (separate prin virgulă)'),
                  const SizedBox(height: 12),
                  AppTextField(controller: _locationCtrl, label: 'Locație eligibilă (ex: Toate, Urban)'),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _ageCtrl,
                    label: 'Vechime minimă firmă (ani)',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(controller: _docsCtrl, label: 'Documente necesare (separate prin virgulă)'),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Anulează', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppStyle.accentPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Colors.black, width: 2),
                ),
              ),
              onPressed: () async {
                final title = _titleCtrl.text.trim();
                final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0.0;
                final caenList = _caenCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                final location = _locationCtrl.text.trim();
                final age = int.tryParse(_ageCtrl.text.trim()) ?? 0;
                final docsList = _docsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

                if (title.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Titlul este obligatoriu.')),
                  );
                  return;
                }

                final newGrant = Grant1(
                  grantId: '',
                  titlu: title,
                  sumaMaxima: amount,
                  criteriiHard: {
                    'caen_eligibile': caenList,
                    'locatie': location.isEmpty ? 'Toate' : location,
                    'vechime_min_ani': age,
                  },
                  documenteNecesare: docsList,
                );

                try {
                  await _db.addGrant(newGrant);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Grant adăugat cu succes!')),
                    );
                  }
                  _titleCtrl.clear();
                  _amountCtrl.clear();
                  _caenCtrl.clear();
                  _locationCtrl.clear();
                  _ageCtrl.clear();
                  _docsCtrl.clear();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Eroare la salvare: $e')),
                    );
                  }
                }
              },
              child: const Text('Salvează'),
            ),
          ],
        );
      },
    );
  }

  // Toggles the local user's admin role for demonstration purposes in Firestore
  Future<void> _toggleAdminRole(bool currentVal) async {
    await FirebaseFirestore.instance
        .collection('users1')
        .doc(_uid)
        .set({'isAdmin': !currentVal}, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GRANTIFY DASHBOARD'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.black),
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: 'Grantify',
                applicationVersion: '1.2.0',
                applicationLegalese: 'Visual Style: Mobbin Neobrutalist.',
              );
            },
          )
        ],
      ),
      body: StreamBuilder<User1?>(
        stream: _db.streamUser(_uid),
        builder: (context, userSnap) {
          final user = userSnap.data;
          final bool isAdmin = user?.isAdmin ?? false;
          final List<String> subscribedTopics = user?.subscribedTopics ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Profil Utilizator Card (users1)
                NeonCard(
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: AppStyle.cartoonDecoration(
                                  color: AppStyle.accentPurple,
                                  borderRadius: 8,
                                  shadowOffset: const Offset(1, 1),
                                ),
                                child: const Icon(Icons.person, color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Profilul Meu',
                                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                                  ),
                                  Text(
                                    FirebaseAuth.instance.currentUser?.email ?? 'Fără Email',
                                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // Simulated Admin Toggle Switch
                          Row(
                            children: [
                              const Text(
                                'Mod Admin:',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              Switch(
                                activeTrackColor: AppStyle.accentPurple,
                                value: isAdmin,
                                onChanged: (val) => _toggleAdminRole(isAdmin),
                              ),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Colors.black, thickness: 1.5),
                      const SizedBox(height: 8),
                      const Text(
                        'Interese & Topice Abonate (Toggles):',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      // Topice interactive (subscribed_topics Toggle)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          'Tech Startups',
                          'Green Energy',
                          'Digitalizare IMM',
                          'Inovare & Cercetare',
                        ].map((topic) {
                          final bool isSubscribed = subscribedTopics.contains(topic);
                          return GestureDetector(
                            onTap: () => _db.toggleSubscribedTopic(_uid, topic),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 100),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: AppStyle.cartoonDecoration(
                                color: isSubscribed ? AppStyle.primaryYellow : Colors.white,
                                borderRadius: 8,
                                shadowOffset: isSubscribed ? const Offset(1, 1) : const Offset(3, 3),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isSubscribed ? Icons.check_box : Icons.check_box_outline_blank,
                                    size: 16,
                                    color: Colors.black,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    topic,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Colectia History Vault Card (historyvault1)
                NeonCard(
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.folder_shared_outlined, color: Colors.black, size: 24),
                              SizedBox(width: 8),
                              Text(
                                'History Vault (Analize Salvate)',
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: AppStyle.accentPurple, size: 30),
                            tooltip: 'Simulează Analiză Nouă',
                            onPressed: _simulateNewAnalysis,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      StreamBuilder<List<HistoryVault1>>(
                        stream: _db.streamUserHistory(_uid),
                        builder: (context, historySnap) {
                          if (historySnap.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final history = historySnap.data ?? [];
                          if (history.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              alignment: Alignment.center,
                              child: const Text(
                                'Nu ai analize salvate în vault.\nApasă pe + pentru a simula una!',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: history.length,
                            itemBuilder: (context, index) {
                              final vault = history[index];
                              final dateStr = vault.dateSaved.toDate().toString().split('.')[0];
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: AppStyle.cartoonDecoration(
                                  color: Colors.grey[50]!,
                                  borderRadius: 8,
                                  shadowOffset: const Offset(2, 2),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Analiză din $dateStr',
                                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Profil: CAEN ${vault.userProfile['caen']}, Locație: ${vault.userProfile['locatie']}, Vechime: ${vault.userProfile['vechime']}',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Granturi Potrivite (${vault.matchedGrants.length}): ${vault.matchedGrants.map((g) => g['titlu'] ?? '').join(', ')}',
                                            style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: AppStyle.accentRed),
                                      onPressed: () => _db.deleteAnalysis(vault.vaultId),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Colectia Grants Showcase Card (grants1)
                NeonCard(
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.monetization_on_outlined, color: Colors.black, size: 24),
                              SizedBox(width: 8),
                              Text(
                                'Granturi Disponibile',
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                              ),
                            ],
                          ),
                          // Display admin button if role is activated
                          if (isAdmin)
                            AppButton(
                              label: 'Adaugă Grant',
                              icon: Icons.add,
                              backgroundColor: AppStyle.accentGreen,
                              textColor: Colors.black,
                              onPressed: _showAddGrantDialog,
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      StreamBuilder<List<Grant1>>(
                        stream: _db.streamGrants(),
                        builder: (context, grantsSnap) {
                          if (grantsSnap.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final grants = grantsSnap.data ?? [];
                          if (grants.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              alignment: Alignment.center,
                              child: Column(
                                children: [
                                  const Text(
                                    'Nu există granturi în baza de date.',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
                                  ),
                                  if (!isAdmin)
                                    const Text(
                                      'Activează Mod Admin de mai sus pentru a adăuga granturi!',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppStyle.accentPurple),
                                    ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: grants.length,
                            itemBuilder: (context, index) {
                              final grant = grants[index];
                              final caens = (grant.criteriiHard['caen_eligibile'] as List<dynamic>?)?.join(', ') ?? 'Toate';
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: AppStyle.cartoonDecoration(
                                  color: Colors.white,
                                  borderRadius: 10,
                                  shadowOffset: const Offset(3, 3),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            grant.titlu,
                                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: AppStyle.cartoonDecoration(
                                            color: AppStyle.primaryYellow,
                                            borderRadius: 6,
                                            shadowOffset: const Offset(1, 1),
                                          ),
                                          child: Text(
                                            '€${grant.sumaMaxima.toStringAsFixed(0)}',
                                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    const Divider(height: 12),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Criterii hard (Eligibilitate):',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey[800]),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '• CAEN: $caens\n'
                                      '• Locație: ${grant.criteriiHard['locatie'] ?? 'Toate'}\n'
                                      '• Vechime minimă: ${grant.criteriiHard['vechime_min_ani'] ?? 0} ani',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.4),
                                    ),
                                    if (grant.documenteNecesare.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'Documente necesare:',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey[800]),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '• ${grant.documenteNecesare.join('\n• ')}',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black54),
                                      ),
                                    ],
                                  ],
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
          );
        },
      ),
    );
  }
}
