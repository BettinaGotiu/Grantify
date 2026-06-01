import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart';
import '../core/app_style.dart';
import '../models/user1.dart';
import '../models/grant1.dart';
import '../services/database_service.dart';
import '../services/news_service.dart';
import '../widgets/neon_card.dart';

class HomeNewsTab extends StatefulWidget {
  const HomeNewsTab({super.key});

  @override
  State<HomeNewsTab> createState() => _HomeNewsTabState();
}

class _HomeNewsTabState extends State<HomeNewsTab> {
  final DatabaseService _db = DatabaseService();
  final NewsService _newsService = NewsService();
  final String _uid = FirebaseAuth.instance.currentUser!.uid;

  bool _newsExpanded = false;
  bool _grantsExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GRANTIFY ACASĂ'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.black),
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: 'Grantify',
                applicationVersion: '2.0.0',
                applicationLegalese: 'Stil vizual: Mobbin Neobrutalist.',
              );
            },
          )
        ],
      ),
      body: StreamBuilder<User1?>(
        stream: _db.streamUser(_uid),
        builder: (context, userSnap) {
          final user = userSnap.data;
          final List<String> subscribedTopics = user?.subscribedTopics ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ═══════════════════════════════════════
                // SECȚIUNEA 1: CARDUL DE ȘTIRI AWS
                // ═══════════════════════════════════════
                _buildNewsSection(subscribedTopics),
                const SizedBox(height: 20),

                // ═══════════════════════════════════════
                // SECȚIUNEA 2: CARDUL DE GRANTURI
                // ═══════════════════════════════════════
                _buildGrantsSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── NEWS SECTION ──
  Widget _buildNewsSection(List<String> subscribedTopics) {
    return NeonCard(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row with refresh button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.newspaper, color: Colors.black, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Știri Financiare',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                ],
              ),
              Row(
                children: [
                  // 🔄 Refresh button to force reload from API
                  GestureDetector(
                    onTap: () => setState(() {}),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: AppStyle.cartoonDecoration(
                        color: Colors.white,
                        borderRadius: 6,
                        shadowOffset: const Offset(2, 2),
                      ),
                      child: const Icon(Icons.refresh, size: 18, color: Colors.black),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // ⬆️⬇️ Expand/Collapse button
                  GestureDetector(
                    onTap: () => setState(() => _newsExpanded = !_newsExpanded),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: AppStyle.cartoonDecoration(
                        color: _newsExpanded ? AppStyle.primaryYellow : Colors.white,
                        borderRadius: 6,
                        shadowOffset: const Offset(2, 2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _newsExpanded ? Icons.expand_less : Icons.expand_more,
                            size: 18,
                            color: Colors.black,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _newsExpanded ? 'Restrânge' : 'Extinde',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.black, thickness: 1.5),
          const SizedBox(height: 8),

          // Content area
          if (subscribedTopics.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: AppStyle.cartoonDecoration(
                      color: AppStyle.primaryYellow,
                      borderRadius: 50,
                      shadowOffset: const Offset(2, 2),
                    ),
                    child: const Icon(Icons.notifications_off, size: 32, color: Colors.black),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Mergi la Setări și abonează-te\nla topice pentru a vedea știri',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _newsService.getNews(subscribedTopics),
              builder: (context, newsSnap) {
                if (newsSnap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: CircularProgressIndicator(color: AppStyle.accentPurple),
                    ),
                  );
                }

                final newsList = newsSnap.data ?? [];

                if (newsList.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    alignment: Alignment.center,
                    child: const Text(
                      'Nu sunt știri disponibile momentan.',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
                    ),
                  );
                }

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  constraints: _newsExpanded
                      ? const BoxConstraints()
                      : const BoxConstraints(maxHeight: 350),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: _newsExpanded
                        ? const NeverScrollableScrollPhysics()
                        : const ClampingScrollPhysics(),
                    itemCount: newsList.length,
                    itemBuilder: (context, index) {
                      final newsItem = newsList[index];
                      return _NewsCard(newsItem: newsItem);
                    },
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ── GRANTS SECTION ──
  Widget _buildGrantsSection() {
    return NeonCard(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row
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
              GestureDetector(
                onTap: () => setState(() => _grantsExpanded = !_grantsExpanded),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: AppStyle.cartoonDecoration(
                    color: _grantsExpanded ? AppStyle.primaryYellow : Colors.white,
                    borderRadius: 6,
                    shadowOffset: const Offset(2, 2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _grantsExpanded ? Icons.expand_less : Icons.expand_more,
                        size: 18,
                        color: Colors.black,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _grantsExpanded ? 'Restrânge' : 'Extinde',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.black, thickness: 1.5),
          const SizedBox(height: 8),

          // Grants content
          StreamBuilder<List<Grant1>>(
            stream: _db.streamGrants(),
            builder: (context, grantsSnap) {
              if (grantsSnap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final grants = grantsSnap.data ?? [];

              if (grants.isEmpty) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  alignment: Alignment.center,
                  child: const Text(
                    'Nu există granturi în baza de date.',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
                  ),
                );
              }

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: _grantsExpanded ? 500.0 : 250.0,
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  itemCount: grants.length,
                  itemBuilder: (context, index) {
                    final grant = grants[index];
                    final caens = (grant.criteriiHard['caen_eligibile'] as List<dynamic>?)
                            ?.join(', ') ??
                        'Toate';

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
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900, fontSize: 16),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: AppStyle.cartoonDecoration(
                                  color: AppStyle.primaryYellow,
                                  borderRadius: 6,
                                  shadowOffset: const Offset(1, 1),
                                ),
                                child: Text(
                                  '€${grant.sumaMaxima.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900, fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Divider(height: 12),
                          const SizedBox(height: 4),
                          Text(
                            'Criterii hard (Eligibilitate):',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: Colors.grey[800]),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '• CAEN: $caens\n'
                            '• Locație: ${grant.criteriiHard['locatie'] ?? 'Toate'}\n'
                            '• Vechime minimă: ${grant.criteriiHard['vechime_min_ani'] ?? 0} ani',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                height: 1.4),
                          ),
                          if (grant.documenteNecesare.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Documente necesare:',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.grey[800]),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '• ${grant.documenteNecesare.join('\n• ')}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// ── Individual News Card widget ──
/// Afișează titlul și topicul din răspunsul API, apoi încarcă markdown din S3.
class _NewsCard extends StatelessWidget {
  final Map<String, dynamic> newsItem;
  const _NewsCard({required this.newsItem});

  @override
  Widget build(BuildContext context) {
    final String? fileUrl = newsItem['file_url'];
    final String title = newsItem['title'] ?? 'Fără titlu';
    final String topic = newsItem['topic'] ?? 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: AppStyle.cartoonDecoration(
        color: Colors.white,
        borderRadius: 12,
        shadowOffset: const Offset(3, 3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔴 TITLU DIN API
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),

          // 🔵 TOPIC TAG
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppStyle.primaryYellow,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              topic.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 10,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.black26),
          const SizedBox(height: 8),

          // 🟢 MARKDOWN DIN S3
          if (fileUrl == null || fileUrl.isEmpty)
            const Text(
              'URL fișier lipsă din API răspuns.',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppStyle.accentRed),
            )
          else
            FutureBuilder<String>(
              future: _loadMarkdown(fileUrl),
              builder: (context, mdSnap) {
                if (mdSnap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppStyle.accentPurple,
                        ),
                      ),
                    ),
                  );
                }

                if (mdSnap.hasError || !mdSnap.hasData) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Eroare la încărcarea fișierului markdown din S3.',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppStyle.accentRed,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'S3 URL: $fileUrl',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                      if (mdSnap.hasError)
                        Text(
                          'Detalii: ${mdSnap.error}',
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppStyle.accentRed,
                          ),
                        ),
                    ],
                  );
                }

                return MarkdownBody(
                  data: mdSnap.data!,
                  styleSheet: MarkdownStyleSheet(
                    h1: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: Colors.black,
                    ),
                    h2: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      color: Colors.black,
                    ),
                    h3: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: Colors.black,
                    ),
                    p: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                    listBullet: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    strong: const TextStyle(fontWeight: FontWeight.w900),
                    blockquoteDecoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black, width: 1),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  /// Fetches raw Markdown text from an S3 public URL
  Future<String> _loadMarkdown(String url) async {
    print(
      '\n📄 [S3 MARKDOWN] Încarcă de la: $url\n',
    );
    try {
      final content = await http.read(Uri.parse(url));
      print('✅ [S3 MARKDOWN] Reușit - ${content.length} bytes\n');
      return content;
    } catch (e) {
      print('❌ [S3 MARKDOWN] Eroare: $e\n');
      rethrow;
    }
  }
}
