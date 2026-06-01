import 'dart:convert';
import 'package:http/http.dart' as http;

const String kApiGatewayId = '';
const String kNewsBaseUrl =
    'https://$kApiGatewayId.execute-api.us-east-1.amazonaws.com/news';

class NewsService {
  // Singleton pattern pentru a folosi aceeași instanță peste tot
  static final NewsService _instance = NewsService._internal();
  factory NewsService() => _instance;
  NewsService._internal();

  // Memoria cache locală (rămâne în RAM pe durata sesiunii)
  List<Map<String, dynamic>>? _cachedNews;

  Future<List<Map<String, dynamic>>> getNews(
    List<String> topics, {
    bool forceRefresh = false,
  }) async {
    if (topics.isEmpty) return [];

    // Dacă avem deja date în cache și NU am cerut refresh forțat, returnăm direct cache-ul
    if (_cachedNews != null && !forceRefresh) {
      print("--- REZULTAT DIN CACHE LOCAL ---");
      return _cachedNews!;
    }

    // Altfel, facem apelul de rețea
    print("--- APEL DE REȚEA CĂTRE AWS ---");
    final topicsParam = topics.join(',');
    final url = Uri.parse('$kNewsBaseUrl?topics=$topicsParam');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> parsed = jsonDecode(response.body);
        _cachedNews = parsed.cast<Map<String, dynamic>>(); // Salvăm în cache
        return _cachedNews!;
      } else {
        return _cachedNews ??
            []; // Dacă pică serverul, returnează ce era în cache
      }
    } catch (e) {
      return _cachedNews ??
          []; // În caz de eroare, nu crăpăm, dăm ce avem salvat
    }
  }
}
