import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../data/datasources/local/storage_service.dart';
import '../../data/datasources/remote/api_client.dart';
import '../../data/datasources/remote/vocabulary_api.dart';
import '../../data/models/user_model.dart';
import '../../data/models/vocabulary_model.dart';
import '../../data/repositories/vocabulary_repository.dart';

/// Drives the "My Vocabulary" feature: lets the signed-in user save new
/// words with a translation, an example sentence and an optional recorded
/// audio pronunciation, then browse, play back and delete saved entries.
class VocabularyController extends GetxController {
  static VocabularyController get to => Get.find();

  late final VocabularyRepository _repo;
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();

  final entries = <VocabularyEntryModel>[].obs;
  final isLoading = false.obs;
  final isSaving = false.obs;
  final errorMessage = Rx<String?>(null);

  // Languages the user is learning — offered when tagging a new entry
  final myLanguages = <UserLanguageModel>[].obs;

  // ─── Recording state ──────────────────────────────────────────────────────
  final isRecording = false.obs;
  final recordedPath = Rx<String?>(null);
  final recordSeconds = 0.obs;

  // ─── Playback state ───────────────────────────────────────────────────────
  final playingEntryId = Rx<int?>(null);

  @override
  void onInit() {
    super.onInit();
    _repo = VocabularyRepository(VocabularyApi(ApiClient.instance));
    _loadLanguages();
    loadEntries();
    _player.onPlayerComplete.listen((_) => playingEntryId.value = null);
  }

  @override
  void onClose() {
    _recorder.dispose();
    _player.dispose();
    super.onClose();
  }

  Future<void> _loadLanguages() async {
    final user = await StorageService.instance.getCachedUser();
    if (user == null) return;
    myLanguages.value = user.learningLanguages.isNotEmpty ? user.learningLanguages : user.languages;
  }

  // ─── Entries ──────────────────────────────────────────────────────────────

  Future<void> loadEntries() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      entries.value = await _repo.getEntries();
    } catch (e) {
      errorMessage.value = ApiClient.parseError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> addEntry({
    required String word,
    required String translation,
    String? example,
    int? languageId,
  }) async {
    isSaving.value = true;
    try {
      var entry = await _repo.createEntry(
        word: word.trim(),
        translation: translation.trim(),
        example: (example?.trim().isEmpty ?? true) ? null : example!.trim(),
        languageId: languageId,
      );

      final path = recordedPath.value;
      if (path != null) {
        entry = await _repo.uploadAudio(entry.id, path);
      }

      entries.insert(0, entry);
      _resetRecording();
      Get.snackbar('Word saved', '"${entry.word}" was added to your vocabulary.',
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
      return true;
    } catch (e) {
      Get.snackbar('Could not save word', ApiClient.parseError(e),
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16), isDismissible: true);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> deleteEntry(VocabularyEntryModel entry) async {
    final previous = entries.toList();
    entries.removeWhere((e) => e.id == entry.id);
    try {
      await _repo.deleteEntry(entry.id);
    } catch (e) {
      entries.value = previous;
      Get.snackbar('Could not delete', ApiClient.parseError(e),
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
    }
  }

  // ─── Recording (for the add-entry sheet) ─────────────────────────────────

  Future<void> startRecording() async {
    if (isRecording.value) return;
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      Get.snackbar('Microphone permission needed', 'Allow microphone access to record pronunciation.',
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
      return;
    }
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/vocab_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
    recordedPath.value = null;
    isRecording.value = true;
    recordSeconds.value = 0;
    _tickRecording();
  }

  void _tickRecording() async {
    while (isRecording.value) {
      await Future.delayed(const Duration(seconds: 1));
      if (isRecording.value) recordSeconds.value++;
    }
  }

  Future<void> stopRecording() async {
    if (!isRecording.value) return;
    final path = await _recorder.stop();
    isRecording.value = false;
    recordedPath.value = path;
  }

  Future<void> discardRecording() async {
    if (isRecording.value) {
      await _recorder.cancel();
      isRecording.value = false;
    }
    final path = recordedPath.value;
    if (path != null) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
    recordedPath.value = null;
    recordSeconds.value = 0;
  }

  void _resetRecording() {
    recordedPath.value = null;
    recordSeconds.value = 0;
    isRecording.value = false;
  }

  // ─── Playback ─────────────────────────────────────────────────────────────

  Future<void> playEntryAudio(VocabularyEntryModel entry) async {
    final url = entry.audioUrl;
    if (url == null) return;
    if (playingEntryId.value == entry.id) {
      await _player.stop();
      playingEntryId.value = null;
      return;
    }
    try {
      await _player.stop();
      playingEntryId.value = entry.id;
      await _player.play(UrlSource(url));
    } catch (e) {
      playingEntryId.value = null;
      Get.snackbar('Playback error', ApiClient.parseError(e),
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
    }
  }

  Future<void> playRecordedPreview() async {
    final path = recordedPath.value;
    if (path == null) return;
    await _player.stop();
    await _player.play(DeviceFileSource(path));
  }

  String get recordingLabel {
    final s = recordSeconds.value;
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }
}
