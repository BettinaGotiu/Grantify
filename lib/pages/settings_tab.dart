import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user1.dart';
import '../services/database_service.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/neon_card.dart';
import '../core/app_style.dart';
import 'formular_admin_screen.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;

  String _currentProfilePic = 'assets/profile_pics/pic1.png';

  final List<String> _profilePics = [
    'assets/profile_pics/pic1.png',
    'assets/profile_pics/pic2.png',
    'assets/profile_pics/pic3.png',
    'assets/profile_pics/pic4.png',
    'assets/profile_pics/pic5.png',
    'assets/profile_pics/pic6.png',
  ];

  final List<String> _awsTopics = [
    'AWS Cloud Practitioner',
    'AWS Solutions Architect',
    'AWS Developer',
    'AWS SysOps',
    'Tehnologii Web',
    'Securitate Cibernetică',
  ];

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _emailCtrl.text = user.email ?? '';
    _usernameCtrl.text = user.displayName ?? '';

    // Load from users collection
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .get();
    if (snap.exists && mounted) {
      final data = snap.data()!;
      _usernameCtrl.text = (data['username'] as String?) ?? _usernameCtrl.text;
      _emailCtrl.text = (data['email'] as String?) ?? _emailCtrl.text;

      setState(() {
        _currentProfilePic =
            data['profilePic'] ?? 'assets/profile_pics/pic1.png';
      });
    }
  }

  Future<void> _save() async {
    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final username = _usernameCtrl.text.trim();
      final email = _emailCtrl.text.trim();
      final password = _passwordCtrl.text;

      // Update in Authentication
      if (username.isNotEmpty && username != user.displayName) {
        await user.updateDisplayName(username);
      }

      if (email.isNotEmpty && email != user.email) {
        await user.verifyBeforeUpdateEmail(email);
      }

      if (password.isNotEmpty) {
        await user.updatePassword(password);
      }

      // Update in Firestore
      final payload = {
        'uid': user.uid,
        'username': username.isNotEmpty ? username : user.email?.split('@')[0],
        'email': email,
        'profilePic': _currentProfilePic,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(payload, SetOptions(merge: true));

      await FirebaseFirestore.instance
          .collection('user_index')
          .doc(user.uid)
          .set(payload, SetOptions(merge: true));

      // Sync to users1
      await FirebaseFirestore.instance
          .collection('users1')
          .doc(user.uid)
          .set({
        'email': email,
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contul și poza au fost actualizate!')),
      );

      _passwordCtrl.clear();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'A apărut o eroare la salvare.')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _logout() async {
    try {
      await DatabaseService().deactivateSession(_uid);
    } catch (e) {
      debugPrint('Error deactivating session: $e');
    }
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
        title: Container(
          padding: const EdgeInsets.all(8),
          decoration: AppStyle.cartoonDecoration(
            color: AppStyle.accentRed,
            borderRadius: 6,
            shadowOffset: const Offset(2, 2),
          ),
          child: const Text(
            'Ștergere Cont?',
            style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
        content: const Text(
          'Această acțiune este permanentă și vă va șterge toate datele din baza de date.',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anulează', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppStyle.accentRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Colors.black, width: 2),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Șterge definitiv'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await DatabaseService().deleteSession(_uid);
      await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
      await FirebaseFirestore.instance.collection('user_index').doc(user.uid).delete();
      await FirebaseFirestore.instance.collection('users1').doc(user.uid).delete();
      
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ?? 'Ștergerea a eșuat, vă rugăm să vă reconectați și să reîncercați.',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SETĂRI CONT & INTERESE'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: StreamBuilder<User1?>(
          stream: DatabaseService().streamUser(_uid),
          builder: (context, userSnap) {
            final user1 = userSnap.data;
            final bool isAdmin = user1?.isAdmin ?? false;
            final List<String> subscribedTopics = user1?.subscribedTopics ?? [];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 525),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Admin conditional button
                      if (isAdmin) ...[
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const FormularAdminScreen()),
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 100),
                            margin: const EdgeInsets.only(bottom: 20),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: AppStyle.cartoonDecoration(
                              color: AppStyle.primaryYellow,
                              borderRadius: 12,
                              shadowOffset: const Offset(4, 4),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.admin_panel_settings, color: Colors.black, size: 24),
                                SizedBox(width: 8),
                                Text(
                                  'Deschide Panou Admin',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // Management Profil card
                      NeonCard(
                        color: Colors.white,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              "Alege o poză de profil:",
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 100,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _profilePics.length,
                                itemBuilder: (context, index) {
                                  String pic = _profilePics[index];
                                  bool isSelected = pic == _currentProfilePic;

                                  return GestureDetector(
                                    onTap: () => setState(() => _currentProfilePic = pic),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 100),
                                      margin: const EdgeInsets.only(right: 12, bottom: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(
                                          color: isSelected
                                              ? AppStyle.accentPurple
                                              : Colors.black,
                                          width: isSelected ? 3 : 2,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: isSelected
                                            ? const [
                                                BoxShadow(
                                                  color: Colors.black,
                                                  offset: Offset(2, 2),
                                                  blurRadius: 0,
                                                )
                                              ]
                                            : null,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(9),
                                        child: Image.asset(
                                          pic,
                                          height: 80,
                                          width: 80,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Divider(color: Colors.black, thickness: 1.5, height: 24),
                            
                            AppTextField(
                              controller: _usernameCtrl,
                              label: 'Nume Utilizator',
                              prefixIcon: Icons.person_outline,
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _emailCtrl,
                              label: 'Email',
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: Icons.alternate_email,
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _passwordCtrl,
                              label: 'Parolă nouă (opțional)',
                              obscureText: true,
                              prefixIcon: Icons.password_outlined,
                            ),
                            const SizedBox(height: 24),

                            AppButton(
                              label: 'Salvează modificările',
                              onPressed: _save,
                              loading: _loading,
                              backgroundColor: AppStyle.primaryYellow,
                              textColor: Colors.black,
                              icon: Icons.save_outlined,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // AWS Topics and Web Development checklist card
                      NeonCard(
                        color: Colors.white,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.cloud_done_outlined, color: Colors.black),
                                SizedBox(width: 8),
                                Text(
                                  'Topice AWS & Interese Core',
                                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Abonați-vă la topicele de interes pentru a primi notificări personalizate.',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
                            ),
                            const SizedBox(height: 12),
                            const Divider(color: Colors.black, thickness: 1.5),
                            const SizedBox(height: 8),
                            
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _awsTopics.map((topic) {
                                final bool isSubscribed = subscribedTopics.contains(topic);
                                return GestureDetector(
                                  onTap: () => DatabaseService().toggleSubscribedTopic(_uid, topic),
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

                      // Logout & Account Delete buttons card
                      NeonCard(
                        color: Colors.white,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppButton(
                              label: 'Deconectare',
                              onPressed: _logout,
                              backgroundColor: Colors.white,
                              textColor: Colors.black,
                              icon: Icons.logout,
                            ),
                            const SizedBox(height: 12),
                            AppButton(
                              label: 'Șterge contul',
                              onPressed: _deleteAccount,
                              backgroundColor: AppStyle.accentRed,
                              textColor: Colors.white,
                              icon: Icons.delete_outline,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
