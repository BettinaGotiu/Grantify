import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/neon_card.dart';
import '../core/app_style.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (_usernameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Numele de utilizator este obligatoriu')),
      );
      return;
    }
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Toate câmpurile sunt obligatorii')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );

      await cred.user?.updateDisplayName(_usernameCtrl.text.trim());

      final uid = cred.user!.uid;

      // 1. Compatibility payload for existing search and friends feature
      final legacyPayload = {
        'uid': uid,
        'username': _usernameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'profilePic': 'assets/profile_pics/pic1.png',
        'friends': [],
        'friendRequests': [],
      };
      await FirebaseFirestore.instance.collection('users').doc(uid).set(legacyPayload);
      await FirebaseFirestore.instance.collection('user_index').doc(uid).set(legacyPayload);

      // 2. New requested users1 collection initialization
      final users1Payload = {
        'email': _emailCtrl.text.trim(),
        'isAdmin': false,
        'friends': <String>[],
        'subscribed_topics': <String>[],
        'settings': <String, dynamic>{},
      };
      await FirebaseFirestore.instance.collection('users1').doc(uid).set(users1Payload);

      // 3. New sessions1 collection initialization
      await DatabaseService().createOrUpdateSession(uid, uid);

      if (!mounted) return;
      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Înregistrare eșuată')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.backgroundLight,
      appBar: AppBar(
        title: const Text('Cont Nou'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: NeonCard(
                  color: Colors.white,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Alătură-te Grantify',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Completează datele de mai jos pentru a crea un cont.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      AppTextField(
                        controller: _usernameCtrl,
                        label: 'Nume Utilizator',
                        textInputAction: TextInputAction.next,
                        prefixIcon: Icons.person_outline,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _emailCtrl,
                        label: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        prefixIcon: Icons.alternate_email,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _passCtrl,
                        label: 'Parolă',
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        prefixIcon: Icons.lock_outline,
                      ),
                      const SizedBox(height: 24),
                      AppButton(
                        label: 'Creează Cont',
                        icon: Icons.person_add_alt_1,
                        loading: _loading,
                        backgroundColor: AppStyle.accentPurple,
                        textColor: Colors.white,
                        onPressed: _signup,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
