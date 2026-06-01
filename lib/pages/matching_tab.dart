import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/app_style.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/neon_card.dart';

enum MatchingState {
  chooseProfile,
  inputVariables,
  showResults,
}

class MatchingTab extends StatefulWidget {
  const MatchingTab({super.key});

  @override
  State<MatchingTab> createState() => _MatchingTabState();
}

class _MatchingTabState extends State<MatchingTab> {
  MatchingState _currentState = MatchingState.chooseProfile;
  String _profileType = 'Firma'; // 'Firma' or 'Idee'

  // Input Controllers for "Am deja Firmă"
  final _cuiCtrl = TextEditingController();
  bool _cuiVerifying = false;
  bool _cuiVerified = false;

  // Search hard criteria parameters
  String _userCaen = '';
  String _userLocatie = 'Urban';
  int _userVechime = 0;

  // Selected Option titles for display
  String _domeniuName = 'IT / Tehnologie';

  // Mock company name (from OpenAPI.ro simulation)
  String _companyName = '';

  // Firestore results
  List<QueryDocumentSnapshot> _eligibleGrants = [];
  bool _searchingGrants = false;

  @override
  void dispose() {
    _cuiCtrl.dispose();
    super.dispose();
  }

  // Simulate CUI verification (OpenAPI.ro mock data)
  Future<void> _verifyCUI() async {
    final cui = _cuiCtrl.text.trim();
    if (cui.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vă rugăm să introduceți un CUI valid.')),
      );
      return;
    }

    setState(() {
      _cuiVerifying = true;
      _cuiVerified = false;
    });

    // Simulate 1 second network delay
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _cuiVerifying = false;
      _cuiVerified = true;
      // Mocked data retrieved from OpenAPI.ro
      _companyName = 'DANTE INTERNATIONAL S.A.';
      _userCaen = '6201'; // IT / Tehnologie
      _userLocatie = 'Urban';
      _userVechime = 2;
    });
  }

  // Fetch from grants1 and run the deterministic local filter
  Future<void> _searchFunds() async {
    setState(() {
      _searchingGrants = true;
      _currentState = MatchingState.showResults;
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance.collection('grants1').get();
      final allGrantsDocs = querySnapshot.docs;

      // Deterministic filter algorithm
      List<QueryDocumentSnapshot> eligibile = allGrantsDocs.where((doc) {
        Map<String, dynamic> criterii = doc.data();
        
        // Extract criteria safely
        Map<String, dynamic> criteriiHard = criterii['criterii_hard'] ?? {};
        List<dynamic> caenEligibile = criteriiHard['caen_eligibile'] ?? [];
        List<dynamic> locatiiEligibile = [];
        
        // Handle location string or list
        var locVal = criteriiHard['locatie'];
        if (locVal is List) {
          locatiiEligibile = locVal;
        } else if (locVal is String) {
          locatiiEligibile = [locVal];
        }

        int vechimeMinima = (criteriiHard['vechime_min_ani'] ?? 0) as int;

        bool matchCaen = caenEligibile.contains(_userCaen);
        bool matchLocatie = locatiiEligibile.isEmpty || locatiiEligibile.contains(_userLocatie);
        bool matchVechime = _userVechime >= vechimeMinima;

        return matchCaen && matchLocatie && matchVechime;
      }).toList();

      setState(() {
        _eligibleGrants = eligibile;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare la procesarea algoritmului: $e')),
        );
      }
    } finally {
      setState(() {
        _searchingGrants = false;
      });
    }
  }

  // Saves a project analysis to historyvault1
  Future<void> _saveToVault(Map<String, dynamic> grantData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final payload = {
        'userId': user.uid,
        'date_saved': Timestamp.now(),
        'user_profile': {
          'caen': _userCaen,
          'locatie': _userLocatie,
          'vechime': _userVechime,
        },
        'matched_grants': [
          {
            'titlu': grantData['titlu'] ?? '',
            'suma_maxima': (grantData['suma_maxima'] as num?)?.toDouble() ?? 0.0,
            'documente_necesare': List<String>.from(grantData['documente_necesare'] ?? []),
          }
        ]
      };

      await FirebaseFirestore.instance.collection('historyvault1').add(payload);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Proiect salvat în baza de date!'),
          backgroundColor: AppStyle.accentGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare la salvare în Vault: $e')),
      );
    }
  }

  // Resets search states and variables
  void _resetFlow() {
    setState(() {
      _currentState = MatchingState.chooseProfile;
      _cuiCtrl.clear();
      _cuiVerified = false;
      _companyName = '';
      _userCaen = '';
      _userLocatie = 'Urban';
      _userVechime = 0;
      _eligibleGrants = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CALCULATOR ELIGIBILITATE'),
        centerTitle: true,
        actions: [
          if (_currentState != MatchingState.chooseProfile)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black),
              tooltip: 'Resetează Căutarea',
              onPressed: _resetFlow,
            )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 550),
              child: _buildStateWidget(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStateWidget() {
    switch (_currentState) {
      case MatchingState.chooseProfile:
        return _buildChooseProfileState();
      case MatchingState.inputVariables:
        return _buildInputVariablesState();
      case MatchingState.showResults:
        return _buildShowResultsState();
    }
  }

  // --- STAREA 1: Ecran de Start (Alegere Profil) ---
  Widget _buildChooseProfileState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Alegeți profilul dumneavoastră:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        
        // Card "Am deja o firmă"
        GestureDetector(
          onTap: () {
            setState(() {
              _profileType = 'Firma';
              _currentState = MatchingState.inputVariables;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: AppStyle.cartoonDecoration(
              color: Colors.white,
              borderRadius: 12,
              shadowOffset: const Offset(4, 4),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: AppStyle.cartoonDecoration(
                    color: AppStyle.primaryYellow,
                    borderRadius: 50,
                    shadowOffset: const Offset(1, 1),
                  ),
                  child: const Icon(Icons.business, size: 40, color: Colors.black),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Am deja Firmă',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Verifică eligibilitatea folosind datele oficiale extrase direct prin codul CUI.',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Card "Am o idee de afaceri"
        GestureDetector(
          onTap: () {
            setState(() {
              _profileType = 'Idee';
              _currentState = MatchingState.inputVariables;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: AppStyle.cartoonDecoration(
              color: Colors.white,
              borderRadius: 12,
              shadowOffset: const Offset(4, 4),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: AppStyle.cartoonDecoration(
                    color: AppStyle.accentPurple,
                    borderRadius: 50,
                    shadowOffset: const Offset(1, 1),
                  ),
                  child: const Icon(Icons.lightbulb_outline, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Am o idee de afaceri',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Calculează eligibilitatea introducând manual domeniul, locația și vechimea planificată.',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- STAREA 2: Ecranul de Input ---
  Widget _buildInputVariablesState() {
    if (_profileType == 'Firma') {
      return _buildFirmaInputWidget();
    } else {
      return _buildIdeeInputWidget();
    }
  }

  // Input view for "Am deja Firmă"
  Widget _buildFirmaInputWidget() {
    return SingleChildScrollView(
      child: NeonCard(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: AppStyle.cartoonDecoration(
                color: AppStyle.primaryYellow,
                borderRadius: 8,
                shadowOffset: const Offset(2, 2),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business_center, color: Colors.black),
                  SizedBox(width: 8),
                  Text(
                    'PROFIL: FIRMĂ ÎNREGISTRATĂ',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            AppTextField(
              controller: _cuiCtrl,
              label: 'Introduceți Codul de Identificare CUI',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.search,
            ),
            const SizedBox(height: 16),

            AppButton(
              label: 'Verifică CUI',
              onPressed: _cuiVerifying ? null : _verifyCUI,
              loading: _cuiVerifying,
              backgroundColor: AppStyle.accentPurple,
              textColor: Colors.white,
              icon: Icons.done_all,
            ),
            
            // OpenAPI.ro mock confirmation box – Company Info Card
            if (_cuiVerified) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppStyle.cartoonDecoration(
                  color: Colors.white,
                  borderRadius: 12,
                  shadowOffset: const Offset(3, 3),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Success header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: AppStyle.cartoonDecoration(
                        color: AppStyle.accentGreen,
                        borderRadius: 8,
                        shadowOffset: const Offset(2, 2),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.verified, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'FIRMĂ VERIFICATĂ – OpenAPI.ro',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Company Name – prominent display
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: AppStyle.cartoonDecoration(
                        color: AppStyle.primaryYellow,
                        borderRadius: 8,
                        shadowOffset: const Offset(2, 2),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.business, color: Colors.black, size: 24),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'DENUMIRE FIRMĂ',
                                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.black54),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _companyName,
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: Colors.black, thickness: 1.5),
                    const SizedBox(height: 10),

                    // Extracted data rows
                    _buildDataRow(Icons.code, 'COD CAEN', '$_userCaen (Dezvoltare Software)'),
                    const SizedBox(height: 8),
                    _buildDataRow(Icons.location_city, 'LOCAȚIE', _userLocatie),
                    const SizedBox(height: 8),
                    _buildDataRow(Icons.calendar_today, 'VECHIME', '$_userVechime ani'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Căutare Fonduri Disponibile',
                onPressed: _searchFunds,
                backgroundColor: AppStyle.accentGreen,
                textColor: Colors.black,
                icon: Icons.search,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Input view for "Am o idee de afaceri"
  Widget _buildIdeeInputWidget() {
    return SingleChildScrollView(
      child: NeonCard(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: AppStyle.cartoonDecoration(
                color: AppStyle.accentPurple,
                borderRadius: 8,
                shadowOffset: const Offset(2, 2),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lightbulb, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'PROFIL: IDEE DE AFACERI',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Dropdown 1: Domeniu / CAEN
            const Text(
              'Selectați domeniul de activitate:',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _domeniuName,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                  onChanged: (String? newVal) {
                    if (newVal != null) {
                      setState(() {
                        _domeniuName = newVal;
                        if (newVal == 'IT / Tehnologie') {
                          _userCaen = '6201';
                        } else if (newVal == 'Producție / Fabrică') {
                          _userCaen = '4120';
                        } else {
                          _userCaen = '9602';
                        }
                      });
                    }
                  },
                  items: const [
                    DropdownMenuItem(value: 'IT / Tehnologie', child: Text('IT / Tehnologie (CAEN 6201)')),
                    DropdownMenuItem(value: 'Producție / Fabrică', child: Text('Producție / Fabrică (CAEN 4120)')),
                    DropdownMenuItem(value: 'Servicii Populație', child: Text('Servicii Populație (CAEN 9602)')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Dropdown 2: Locatie
            const Text(
              'Locația desfășurării activității:',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _userLocatie,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                  onChanged: (String? newVal) {
                    if (newVal != null) {
                      setState(() => _userLocatie = newVal);
                    }
                  },
                  items: const [
                    DropdownMenuItem(value: 'Urban', child: Text('Urban (Oraș)')),
                    DropdownMenuItem(value: 'Rural', child: Text('Rural (Sat)')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Dropdown 3: Vechime (implicit 0)
            const Text(
              'Vechimea firmei (implicit 0 ani pentru start-up):',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _userVechime,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                  onChanged: (int? newVal) {
                    if (newVal != null) {
                      setState(() => _userVechime = newVal);
                    }
                  },
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Start-up nou (0 ani)')),
                    DropdownMenuItem(value: 1, child: Text('1 an de activitate')),
                    DropdownMenuItem(value: 2, child: Text('2 ani de activitate')),
                    DropdownMenuItem(value: 3, child: Text('3+ ani de activitate')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            AppButton(
              label: 'Căutare Fonduri Disponibile',
              onPressed: () {
                // Initialize userCaen if not set
                if (_userCaen.isEmpty) {
                  _userCaen = '6201'; // Default
                }
                _searchFunds();
              },
              backgroundColor: AppStyle.primaryYellow,
              textColor: Colors.black,
              icon: Icons.search,
            ),
          ],
        ),
      ),
    );
  }

  // --- STAREA 3: Ecranul de Rezultate (Algoritmul de Filtrare) ---
  Widget _buildShowResultsState() {
    if (_searchingGrants) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppStyle.accentPurple),
             SizedBox(height: 16),
            Text(
              'Filtrare criterii hard în baza de date...',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Query criteria summary tag
        Container(
          padding: const EdgeInsets.all(12),
          decoration: AppStyle.cartoonDecoration(
            color: Colors.white,
            borderRadius: 8,
            shadowOffset: const Offset(2, 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'REZULTAT CĂUTARE PROFIL UTILIZATOR:',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.black54),
              ),
              const SizedBox(height: 4),
              Text(
                'CAEN: $_userCaen | Locație: $_userLocatie | Vechime: $_userVechime ani',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.black),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Expanded(
          child: _eligibleGrants.isEmpty
              ? Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: AppStyle.cartoonDecoration(
                      color: Colors.white,
                      borderRadius: 12,
                      shadowOffset: const Offset(3, 3),
                    ),
                    child: const Text(
                      'Nu s-au găsit fonduri europene potrivite criteriilor hard.',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _eligibleGrants.length,
                  itemBuilder: (context, index) {
                    final doc = _eligibleGrants[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final title = data['titlu'] ?? '';
                    final double amount = (data['suma_maxima'] as num?)?.toDouble() ?? 0.0;
                    final caens = (data['criterii_hard']?['caen_eligibile'] as List<dynamic>?)?.join(', ') ?? '';

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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Solid Neobrutalist Badge: STATUS ELIGIBIL
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                decoration: AppStyle.cartoonDecoration(
                                  color: AppStyle.accentGreen,
                                  borderRadius: 6,
                                  shadowOffset: const Offset(1, 1),
                                ),
                                child: const Text(
                                  'STATUS: ELIGIBIL',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Suma Maximă Finanțare: €${amount.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppStyle.accentPurple),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Coduri CAEN Eligibile: $caens',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: Colors.black, thickness: 1.5, height: 16),
                          const SizedBox(height: 4),
                          
                          AppButton(
                            label: 'Salvează Proiect în Vault',
                            onPressed: () => _saveToVault(data),
                            backgroundColor: AppStyle.primaryYellow,
                            textColor: Colors.black,
                            icon: Icons.bookmark_add_outlined,
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 8),
        AppButton(
          label: 'Înapoi la Profil',
          onPressed: _resetFlow,
          backgroundColor: Colors.white,
          textColor: Colors.black,
          icon: Icons.chevron_left,
        ),
      ],
    );
  }

  /// Helper widget: displays a single data row with icon + label + value
  Widget _buildDataRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.black54),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.black54),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.black),
          ),
        ),
      ],
    );
  }
}
