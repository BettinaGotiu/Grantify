import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../core/app_style.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/neon_card.dart';

class FormularAdminScreen extends StatefulWidget {
  const FormularAdminScreen({super.key});

  @override
  State<FormularAdminScreen> createState() => _FormularAdminScreenState();
}

class _FormularAdminScreenState extends State<FormularAdminScreen> {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _caenCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _docsCtrl = TextEditingController();

  String _locationOption = 'Ambele'; // 'Urban', 'Rural', 'Ambele'
  bool _loading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _caenCtrl.dispose();
    _ageCtrl.dispose();
    _docsCtrl.dispose();
    super.dispose();
  }

  Future<void> _uploadGrant() async {
    final title = _titleCtrl.text.trim();
    final amountText = _amountCtrl.text.trim();
    final caenText = _caenCtrl.text.trim();
    final ageText = _ageCtrl.text.trim();
    final docsText = _docsCtrl.text.trim();

    if (title.isEmpty || amountText.isEmpty || caenText.isEmpty || ageText.isEmpty || docsText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vă rugăm să completați toate câmpurile!')),
      );
      return;
    }

    final double? amount = double.tryParse(amountText);
    final int? age = int.tryParse(ageText);

    if (amount == null || age == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Suma maximă și vechimea minimă trebuie să fie numere valide!')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // Split and clean CAEN values
      List<String> caenEligibile = caenText
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      // Location list mapping
      List<String> locatiiList;
      if (_locationOption == 'Urban') {
        locatiiList = ['Urban'];
      } else if (_locationOption == 'Rural') {
        locatiiList = ['Rural'];
      } else {
        locatiiList = ['Urban', 'Rural'];
      }

      // Split and clean document list
      List<String> documenteList = docsText
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final payload = {
        'titlu': title,
        'suma_maxima': amount,
        'criterii_hard': {
          'caen_eligibile': caenEligibile,
          'locatie': locatiiList,
          'vechime_min_ani': age,
        },
        'documente_necesare': documenteList,
      };

      await FirebaseFirestore.instance.collection('grants1').add(payload);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grant încărcat cu succes în Firestore!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare la încărcare: $e')),
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
        title: const Text('PANOU ADMIN FONDURI'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 550),
              child: NeonCard(
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: AppStyle.cartoonDecoration(
                        color: AppStyle.primaryYellow,
                        borderRadius: 8,
                        shadowOffset: const Offset(2, 2),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.admin_panel_settings, color: Colors.black),
                          SizedBox(width: 8),
                          Text(
                            'ADAUGE GRANT NOU',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    AppTextField(
                      controller: _titleCtrl,
                      label: 'Titlu Program Grant',
                      prefixIcon: Icons.title,
                    ),
                    const SizedBox(height: 16),

                    AppTextField(
                      controller: _amountCtrl,
                      label: 'Suma Maximă Program (€)',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: Icons.euro,
                    ),
                    const SizedBox(height: 16),

                    AppTextField(
                      controller: _caenCtrl,
                      label: 'Coduri CAEN eligibile (ex: 6201, 6202)',
                      prefixIcon: Icons.code,
                    ),
                    const SizedBox(height: 6),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                        'Separați codurile prin virgulă.',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Custom Location Dropdown Selection
                    const Text(
                      'Locație Permisă (Criteriu Hard):',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _locationOption,
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                          onChanged: (String? newVal) {
                            if (newVal != null) {
                              setState(() => _locationOption = newVal);
                            }
                          },
                          items: const [
                            DropdownMenuItem(value: 'Urban', child: Text('Doar Urban')),
                            DropdownMenuItem(value: 'Rural', child: Text('Doar Rural')),
                            DropdownMenuItem(value: 'Ambele', child: Text('Ambele (Urban & Rural)')),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    AppTextField(
                      controller: _ageCtrl,
                      label: 'Vechime Minimă în Ani a Firmei',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.calendar_today,
                    ),
                    const SizedBox(height: 16),

                    AppTextField(
                      controller: _docsCtrl,
                      label: 'Documente Necesare (ex: Plan Afaceri, CUI)',
                      prefixIcon: Icons.file_copy,
                    ),
                    const SizedBox(height: 6),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                        'Separați documentele solicitate prin virgulă.',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54),
                      ),
                    ),
                    const SizedBox(height: 24),

                    AppButton(
                      label: 'Încarcă Grant în Firestore',
                      onPressed: _uploadGrant,
                      loading: _loading,
                      backgroundColor: AppStyle.accentPurple,
                      textColor: Colors.white,
                      icon: Icons.cloud_upload_outlined,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
