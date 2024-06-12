import 'package:cloud_firestore/cloud_firestore.dart';

class Language {
  final String id;
  final String nameInEnglish;
  final String nameInFrench;
  final String nameInSpanish;

  // Constructor
  Language({
    required this.id,
    required this.nameInEnglish,
    required this.nameInFrench,
    required this.nameInSpanish,
  });

  // Convert a Language object to a Map object so it can be stored in Firestore
  factory Language.fromMap(Map<String, dynamic> map, String documentId) {
    return Language(
      id: documentId,
      nameInEnglish: map['nameInEnglish'] ?? '',
      nameInFrench: map['nameInFrench'] ?? '',
      nameInSpanish: map['nameInSpanish'] ?? '',
    );
  }

  // Convert a Language object to a Map object
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nameInEnglish': nameInEnglish,
      'nameInFrench': nameInFrench,
      'nameInSpanish': nameInSpanish,
    };
  }
}

// Function to upload languages to Firestore
Future<void> uploadLanguages() async {
  List<Language> languages = [
    Language(
        id: 'en',
        nameInEnglish: 'English',
        nameInFrench: 'Anglais',
        nameInSpanish: 'Inglés'),
    Language(
        id: 'fr',
        nameInEnglish: 'French',
        nameInFrench: 'Français',
        nameInSpanish: 'Francés'),
    Language(
        id: 'es',
        nameInEnglish: 'Spanish',
        nameInFrench: 'Espagnol',
        nameInSpanish: 'Español'),
    Language(
        id: 'zh',
        nameInEnglish: 'Chinese',
        nameInFrench: 'Chinois',
        nameInSpanish: 'Chino'),
    Language(
        id: 'ja',
        nameInEnglish: 'Japanese',
        nameInFrench: 'Japonais',
        nameInSpanish: 'Japonés'),
    Language(
        id: 'ar',
        nameInEnglish: 'Arabic',
        nameInFrench: 'Arabe',
        nameInSpanish: 'Árabe'),
    Language(
        id: 'de',
        nameInEnglish: 'German',
        nameInFrench: 'Allemand',
        nameInSpanish: 'Alemán'),
    Language(
        id: 'it',
        nameInEnglish: 'Italian',
        nameInFrench: 'Italien',
        nameInSpanish: 'Italiano'),
    Language(
        id: 'pt',
        nameInEnglish: 'Portuguese',
        nameInFrench: 'Portugais',
        nameInSpanish: 'Portugués'),
    Language(
        id: 'ru',
        nameInEnglish: 'Russian',
        nameInFrench: 'Russe',
        nameInSpanish: 'Ruso'),
    Language(
        id: 'ko',
        nameInEnglish: 'Korean',
        nameInFrench: 'Coréen',
        nameInSpanish: 'Coreano'),
    Language(
        id: 'nl',
        nameInEnglish: 'Dutch',
        nameInFrench: 'Néerlandais',
        nameInSpanish: 'Neerlandés'),
    Language(
        id: 'sv',
        nameInEnglish: 'Swedish',
        nameInFrench: 'Suédois',
        nameInSpanish: 'Sueco'),
    Language(
        id: 'da',
        nameInEnglish: 'Danish',
        nameInFrench: 'Danois',
        nameInSpanish: 'Danés'),
    Language(
        id: 'fi',
        nameInEnglish: 'Finnish',
        nameInFrench: 'Finnois',
        nameInSpanish: 'Finés'),
    Language(
        id: 'no',
        nameInEnglish: 'Norwegian',
        nameInFrench: 'Norvégien',
        nameInSpanish: 'Noruego'),
    Language(
        id: 'pl',
        nameInEnglish: 'Polish',
        nameInFrench: 'Polonais',
        nameInSpanish: 'Polaco'),
    Language(
        id: 'tr',
        nameInEnglish: 'Turkish',
        nameInFrench: 'Turc',
        nameInSpanish: 'Turco'),
    Language(
        id: 'el',
        nameInEnglish: 'Greek',
        nameInFrench: 'Grec',
        nameInSpanish: 'Griego'),
    Language(
        id: 'he',
        nameInEnglish: 'Hebrew',
        nameInFrench: 'Hébreu',
        nameInSpanish: 'Hebreo'),
    Language(
        id: 'th',
        nameInEnglish: 'Thai',
        nameInFrench: 'Thaïlandais',
        nameInSpanish: 'Tailandés'),
    Language(
        id: 'ma',
        nameInEnglish: 'Malay',
        nameInFrench: 'Malais',
        nameInSpanish: 'Malayo'),
    Language(
        id: 'ca',
        nameInEnglish: 'Cantonese',
        nameInFrench: 'Cantonais',
        nameInSpanish: 'Cantonés'),
    Language(
        id: 'fi',
        nameInEnglish: 'Filipino',
        nameInFrench: 'Philippin',
        nameInSpanish: 'Filipino'),
    Language(
        id: 'in',
        nameInEnglish: 'Indonesian',
        nameInFrench: 'Indonésien',
        nameInSpanish: 'Indonesio'),
    Language(
        id: 'bu',
        nameInEnglish: 'Burmese',
        nameInFrench: 'Birman',
        nameInSpanish: 'Birmano'),
    Language(
        id: 'la',
        nameInEnglish: 'Lao',
        nameInFrench: 'Laotein',
        nameInSpanish: 'Laosiano'),
    Language(
        id: 'bg',
        nameInEnglish: 'Bengali',
        nameInFrench: 'Bengalí',
        nameInSpanish: 'Bengali'),
    Language(
        id: 'ur',
        nameInEnglish: 'Urdu',
        nameInFrench: 'Ourdou',
        nameInSpanish: 'Urdu'),
    Language(
        id: 'sk',
        nameInEnglish: 'Sanskrit',
        nameInFrench: 'Sanskrit',
        nameInSpanish: 'Sanskrit'),
    Language(
        id: 'pu',
        nameInEnglish: 'Punjabi',
        nameInFrench: 'Pendjabi',
        nameInSpanish: 'Punjabi'),
    Language(
        id: 'hi',
        nameInEnglish: 'Hindi',
        nameInFrench: 'Hindi',
        nameInSpanish: 'Hindi'),
    Language(
        id: 'kh',
        nameInEnglish: 'Kashmiri',
        nameInFrench: 'Cachemire',
        nameInSpanish: 'Cachemira'),
    Language(
        id: 'si',
        nameInEnglish: 'Sinhala',
        nameInFrench: 'Cinghalais',
        nameInSpanish: 'Cingalés'),
    Language(
        id: 'ta',
        nameInEnglish: 'Tamil',
        nameInFrench: 'Tamil',
        nameInSpanish: 'Tamil'),
  ];
  final firestore = FirebaseFirestore.instance;
  final batch = firestore.batch();

  for (var language in languages) {
    // Crea un documento para cada idioma en la colección 'languages'.
    var documentRef = firestore.collection('languages').doc(language.id);
    batch.set(documentRef, language.toMap());
  }
  print("printed languages");
  await batch.commit();
}
