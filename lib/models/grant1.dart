class Grant1 {
  final String grantId;
  final String titlu;
  final double sumaMaxima;
  final Map<String, dynamic> criteriiHard; // caen_eligibile, locatie, vechime_min_ani
  final List<String> documenteNecesare;

  Grant1({
    required this.grantId,
    required this.titlu,
    required this.sumaMaxima,
    required this.criteriiHard,
    required this.documenteNecesare,
  });

  /// Factory constructor to create a Grant1 instance from Firestore document data
  factory Grant1.fromMap(String docId, Map<String, dynamic> map) {
    return Grant1(
      grantId: docId,
      titlu: map['titlu'] ?? '',
      sumaMaxima: (map['suma_maxima'] as num?)?.toDouble() ?? 0.0,
      criteriiHard: Map<String, dynamic>.from(map['criterii_hard'] ?? {}),
      documenteNecesare: List<String>.from(map['documente_necesare'] ?? []),
    );
  }

  /// Converts the Grant1 instance to a map suited for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'titlu': titlu,
      'suma_maxima': sumaMaxima,
      'criterii_hard': criteriiHard,
      'documente_necesare': documenteNecesare,
    };
  }
}
