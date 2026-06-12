import '../datasources/remote/vocabulary_api.dart';
import '../models/vocabulary_model.dart';

class VocabularyRepository {
  VocabularyRepository(this._api);

  final VocabularyApi _api;

  Future<List<VocabularyEntryModel>> getEntries() => _api.getEntries();

  Future<VocabularyEntryModel> createEntry({
    required String word,
    required String translation,
    String? example,
    int? languageId,
  }) =>
      _api.createEntry(word: word, translation: translation, example: example, languageId: languageId);

  Future<VocabularyEntryModel> updateEntry(
    int id, {
    String? word,
    String? translation,
    String? example,
    int? languageId,
  }) =>
      _api.updateEntry(id, word: word, translation: translation, example: example, languageId: languageId);

  Future<VocabularyEntryModel> uploadAudio(int id, String filePath) => _api.uploadAudio(id, filePath);

  Future<void> deleteEntry(int id) => _api.deleteEntry(id);
}
