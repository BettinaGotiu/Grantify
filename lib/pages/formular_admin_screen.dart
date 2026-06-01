import 'dart:convert';
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
  // Toggle between Manual (0) and JSON (1)
  int _selectedMode = 0;

  // ── Manual form controllers ──
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _caenCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _docsCtrl = TextEditingController();
  String _locationOption = 'Ambele';
  bool _loadingManual = false;

  // ── JSON form controller ──
  final _jsonCtrl = TextEditingController();
  bool _loadingJson = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _caenCtrl.dispose();
    _ageCtrl.dispose();
    _docsCtrl.dispose();
    _jsonCtrl.dispose();
    super.dispose();
  }

  // ── MANUAL UPLOAD ──
  Future<void> _uploadGrantManual() async {
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

    setState(() => _loadingManual = true);

    try {
      List<String> caenEligibile = caenText
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      List<String> locatiiList;
      if (_locationOption == 'Urban') {
        locatiiList = ['Urban'];
      } else if (_locationOption == 'Rural') {
        locatiiList = ['Rural'];
      } else {
        locatiiList = ['Urban', 'Rural'];
      }

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
        setState(() => _loadingManual = false);
      }
    }
  }

  // ── JSON UPLOAD ──
  Future<void> _uploadGrantFromJson() async {
    final jsonText = _jsonCtrl.text.trim();

    if (jsonText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vă rugăm să lipiți un JSON valid!')),
      );
      return;
    }

    setState(() => _loadingJson = true);

    try {
      final dynamic decoded = jsonDecode(jsonText);

      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('JSON-ul trebuie să fie un obiect {}');
      }

      // Validate required keys
      final requiredKeys = ['titlu', 'suma_maxima', 'criterii_hard', 'documente_necesare'];
      for (final key in requiredKeys) {
        if (!decoded.containsKey(key)) {
          throw FormatException('Lipsește cheia obligatorie: "$key"');
        }
      }

      await FirebaseFirestore.instance.collection('grants1').add(decoded);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Grant JSON încărcat cu succes în Firestore!'),
          backgroundColor: AppStyle.accentGreen,
        ),
      );
      _jsonCtrl.clear();
      Navigator.pop(context);
    } on FormatException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('JSON invalid: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare la încărcare JSON: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loadingJson = false);
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Mode Selector: Manual vs JSON ──
                  Container(
                    decoration: AppStyle.cartoonDecoration(
                      color: Colors.white,
                      borderRadius: 12,
                      shadowOffset: const Offset(3, 3),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedMode = 0),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: _selectedMode == 0 ? AppStyle.primaryYellow : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.black,
                                  width: _selectedMode == 0 ? 2 : 0,
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.edit_document, size: 18, color: Colors.black),
                                  SizedBox(width: 6),
                                  Text(
                                    'MANUAL',
                                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedMode = 1),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: _selectedMode == 1 ? AppStyle.accentPurple : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.black,
                                  width: _selectedMode == 1 ? 2 : 0,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.data_object, size: 18,
                                      color: _selectedMode == 1 ? Colors.white : Colors.black),
                                  const SizedBox(width: 6),
                                  Text(
                                    'JSON',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                      color: _selectedMode == 1 ? Colors.white : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Show the selected form ──
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _selectedMode == 0 ? _buildManualForm() : _buildJsonForm(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── MANUAL FORM (existing) ──
  Widget _buildManualForm() {
    return NeonCard(
      key: const ValueKey('manual'),
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
                  'COMPLETARE MANUALĂ',
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
            onPressed: _uploadGrantManual,
            loading: _loadingManual,
            backgroundColor: AppStyle.accentPurple,
            textColor: Colors.white,
            icon: Icons.cloud_upload_outlined,
          ),
        ],
      ),
    );
  }

  // ── JSON FORM (new) ──
  Widget _buildJsonForm() {
    return NeonCard(
      key: const ValueKey('json'),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: AppStyle.cartoonDecoration(
              color: AppStyle.accentPurple,
              borderRadius: 8,
              shadowOffset: const Offset(2, 2),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.data_object, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'ÎNCĂRCARE JSON',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'Lipiți structura JSON a grantului mai jos:',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
          ),
          const SizedBox(height: 8),
          const Text(
            'Chei obligatorii: titlu, suma_maxima, criterii_hard, documente_necesare',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          const SizedBox(height: 12),

          // JSON text area
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: TextField(
              controller: _jsonCtrl,
              maxLines: 12,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: '{\n'
                    '  "titlu": "Grant Digitalizare",\n'
                    '  "suma_maxima": 50000,\n'
                    '  "criterii_hard": {\n'
                    '    "caen_eligibile": ["6201"],\n'
                    '    "locatie": ["Urban"],\n'
                    '    "vechime_min_ani": 1\n'
                    '  },\n'
                    '  "documente_necesare": ["CUI", "Plan"]\n'
                    '}',
                hintStyle: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[400],
                  fontFamily: 'monospace',
                ),
                contentPadding: const EdgeInsets.all(12),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 24),

          AppButton(
            label: 'Parsează și Încarcă în Firestore',
            onPressed: _uploadGrantFromJson,
            loading: _loadingJson,
            backgroundColor: AppStyle.accentGreen,
            textColor: Colors.black,
            icon: Icons.upload_file,
          ),
        ],
      ),
    );
  }
}
