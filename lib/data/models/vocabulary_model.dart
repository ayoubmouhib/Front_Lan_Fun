import '../../config/constants.dart';

/// A single saved vocabulary entry: a word with its translation, an optional
/// example sentence and an optional recorded audio pronunciation.
class VocabularyEntryModel {
  const VocabularyEntryModel({
    required this.id,
    required this.word,
    required this.translation,
    this.example,
    this.audioPath,
    this.languageId,
    this.languageName,
    this.languageIsoCode,
    required this.createdAt,
  });

  final int id;
  final String word;
  final String translation;
  final String? example;
  final String? audioPath;
  final int? languageId;
  final String? languageName;
  final String? languageIsoCode;
  final DateTime createdAt;

  bool get hasAudio => audioPath != null && audioPath!.isNotEmpty;

  String? get audioUrl =>
      hasAudio ? '${AppConstants.apiBaseUrl}/uploads/vocabulary-audio/$audioPath' : null;

  factory VocabularyEntryModel.fromJson(Map<String, dynamic> j) {
    final lang = j['language'] as Map<String, dynamic>?;
    return VocabularyEntryModel(
      id: j['id'] as int,
      word: j['word'] as String? ?? '',
      translation: j['translation'] as String? ?? '',
      example: j['example'] as String?,
      audioPath: j['audio_path'] as String?,
      languageId: j['language_id'] as int?,
      languageName: lang?['name'] as String?,
      languageIsoCode: lang?['iso_code'] as String?,
      createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
