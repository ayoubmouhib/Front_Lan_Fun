import 'package:dio/dio.dart';

import '../../models/vocabulary_model.dart';
import 'api_client.dart';

class VocabularyApi {
  VocabularyApi(this._client);
  final ApiClient _client;

  // GET /vocabulary
  Future<List<VocabularyEntryModel>> getEntries() async {
    final res = await _client.get('/vocabulary');
    return (res.data as List<dynamic>)
        .map((e) => VocabularyEntryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // POST /vocabulary
  Future<VocabularyEntryModel> createEntry({
    required String word,
    required String translation,
    String? example,
    int? languageId,
  }) async {
    final res = await _client.post('/vocabulary', data: {
      'word': word,
      'translation': translation,
      if (example != null && example.isNotEmpty) 'example': example,
      if (languageId != null) 'language_id': languageId,
    });
    return VocabularyEntryModel.fromJson(res.data as Map<String, dynamic>);
  }

  // PATCH /vocabulary/:id
  Future<VocabularyEntryModel> updateEntry(
    int id, {
    String? word,
    String? translation,
    String? example,
    int? languageId,
  }) async {
    final res = await _client.patch('/vocabulary/$id', data: {
      if (word != null) 'word': word,
      if (translation != null) 'translation': translation,
      if (example != null) 'example': example,
      if (languageId != null) 'language_id': languageId,
    });
    return VocabularyEntryModel.fromJson(res.data as Map<String, dynamic>);
  }

  // POST /vocabulary/:id/audio — multipart audio upload
  Future<VocabularyEntryModel> uploadAudio(int id, String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final res = await _client.post('/vocabulary/$id/audio', data: formData);
    return VocabularyEntryModel.fromJson(res.data as Map<String, dynamic>);
  }

  // DELETE /vocabulary/:id
  Future<void> deleteEntry(int id) async {
    await _client.delete('/vocabulary/$id');
  }
}
