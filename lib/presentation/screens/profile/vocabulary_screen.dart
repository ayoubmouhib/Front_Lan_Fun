import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../config/theme.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/vocabulary_model.dart';
import '../../controllers/vocabulary_controller.dart';
import '../../widgets/common/empty_state.dart';

/// "My Vocabulary" — lets the user save new words with a translation, an
/// optional example sentence and an optional recorded audio pronunciation,
/// then browse, play back and delete saved entries.
class VocabularyScreen extends StatelessWidget {
  const VocabularyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<VocabularyController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Vocabulary'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddSheet(context, ctrl),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add word', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: Obx(() {
        if (ctrl.isLoading.value && ctrl.entries.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (ctrl.entries.isEmpty) {
          return EmptyState(
            icon: Icons.menu_book_outlined,
            title: 'No words yet',
            subtitle: 'Tap "Add word" to start building your personal vocabulary list.',
          );
        }

        return RefreshIndicator(
          onRefresh: ctrl.loadEntries,
          color: AppColors.primary,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: ctrl.entries.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _VocabularyCard(entry: ctrl.entries[i], ctrl: ctrl),
          ),
        );
      }),
    );
  }

  void _openAddSheet(BuildContext context, VocabularyController ctrl) {
    VocabularyAddSheet.show(context, ctrl: ctrl);
  }
}

// ─── Entry card ───────────────────────────────────────────────────────────────

class _VocabularyCard extends StatelessWidget {
  const _VocabularyCard({required this.entry, required this.ctrl});

  final VocabularyEntryModel entry;
  final VocabularyController ctrl;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subColor = isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant;

    return Material(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.word,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                      const SizedBox(height: 2),
                      Text(entry.translation,
                          style: TextStyle(fontSize: 14, color: subColor, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                if (entry.languageName != null) _LanguageChip(name: entry.languageName!),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded, color: AppColors.error.withValues(alpha: 0.7), size: 20),
                  onPressed: () => _confirmDelete(context),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (entry.example != null && entry.example!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '"${entry.example}"',
                  style: TextStyle(fontSize: 13, color: subColor, fontStyle: FontStyle.italic),
                ),
              ),
            ],
            if (entry.hasAudio) ...[
              const SizedBox(height: 10),
              Obx(() {
                final playing = ctrl.playingEntryId.value == entry.id;
                return GestureDetector(
                  onTap: () => ctrl.playEntryAudio(entry),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        playing ? 'Playing…' : 'Pronunciation',
                        style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    Get.dialog(AlertDialog(
      title: const Text('Delete word?'),
      content: Text('"${entry.word}" will be removed from your vocabulary.'),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            Get.back();
            ctrl.deleteEntry(entry);
          },
          child: const Text('Delete', style: TextStyle(color: AppColors.error)),
        ),
      ],
    ));
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(name, style: const TextStyle(color: AppColors.secondary, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

// ─── Add word sheet ───────────────────────────────────────────────────────────

class VocabularyAddSheet extends StatefulWidget {
  const VocabularyAddSheet({super.key, required this.ctrl, this.initialWord});

  final VocabularyController ctrl;
  final String? initialWord;

  /// Opens the "Add a new word" sheet, optionally pre-filling the word field —
  /// used both from the vocabulary screen's FAB and from "Save to vocabulary"
  /// long-press actions on chat messages.
  static void show(BuildContext context, {required VocabularyController ctrl, String? initialWord}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VocabularyAddSheet(ctrl: ctrl, initialWord: initialWord),
    );
  }

  @override
  State<VocabularyAddSheet> createState() => _VocabularyAddSheetState();
}

class _VocabularyAddSheetState extends State<VocabularyAddSheet> {
  final _wordCtrl = TextEditingController();
  final _translationCtrl = TextEditingController();
  final _exampleCtrl = TextEditingController();
  int? _languageId;

  @override
  void dispose() {
    _wordCtrl.dispose();
    _translationCtrl.dispose();
    _exampleCtrl.dispose();
    widget.ctrl.discardRecording();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialWord != null) {
      _wordCtrl.text = widget.initialWord!;
    }
    final langs = widget.ctrl.myLanguages;
    if (langs.isNotEmpty) {
      _languageId = langs.first.languageId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final ctrl = widget.ctrl;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text('Add a new word',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 18),

              _Field(label: 'Word', controller: _wordCtrl, hint: 'e.g. serendipity', icon: Icons.text_fields_rounded),
              const SizedBox(height: 14),
              _Field(
                label: 'Translation / meaning',
                controller: _translationCtrl,
                hint: 'e.g. a happy accident',
                icon: Icons.translate_rounded,
              ),
              const SizedBox(height: 14),
              _Field(
                label: 'Example sentence (optional)',
                controller: _exampleCtrl,
                hint: 'Use it in a sentence…',
                maxLines: 2,
                icon: Icons.short_text_rounded,
              ),

              if (ctrl.myLanguages.isNotEmpty) ...[
                const SizedBox(height: 12),
                _LanguagePicker(
                  languages: ctrl.myLanguages,
                  selectedId: _languageId,
                  onSelected: (id, name) => setState(() => _languageId = id),
                ),
              ],

              const SizedBox(height: 16),
              _RecordingControls(ctrl: ctrl),

              const SizedBox(height: 22),
              Obx(() => SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: ctrl.isSaving.value ? null : _submit,
                      child: ctrl.isSaving.value
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                            )
                          : const Text('Save word',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final word = _wordCtrl.text.trim();
    final translation = _translationCtrl.text.trim();
    if (word.isEmpty || translation.isEmpty) {
      Get.snackbar('Missing details', 'Please fill in both the word and its translation.',
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
      return;
    }

    final ok = await widget.ctrl.addEntry(
      word: word,
      translation: translation,
      example: _exampleCtrl.text,
      languageId: _languageId,
    );
    if (ok && mounted) Get.back();
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.controller, this.hint, this.maxLines = 1, this.icon});
  final String label;
  final TextEditingController controller;
  final String? hint;
  final int maxLines;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputBg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final border = isDark ? AppColors.darkOutline : AppColors.lightOutline;
    final iconColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            filled: true,
            fillColor: inputBg,
            prefixIcon: icon == null
                ? null
                : Padding(
                    padding: EdgeInsets.only(top: maxLines > 1 ? 0 : 0),
                    child: Icon(icon, size: 19, color: iconColor),
                  ),
            prefixIconConstraints: const BoxConstraints(minWidth: 46, minHeight: 0),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            hintStyle: TextStyle(color: iconColor, fontSize: 14, fontWeight: FontWeight.w400),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: border, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: border, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
            ),
          ),
        ),
      ],
    );
  }
}

class _LanguagePicker extends StatelessWidget {
  const _LanguagePicker({required this.languages, required this.selectedId, required this.onSelected});
  final List<UserLanguageModel> languages;
  final int? selectedId;
  final void Function(int id, String? name) onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Language (optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: languages.map((l) {
            final selected = selectedId == l.languageId;
            final name = l.language?.name ?? 'Language ${l.languageId}';
            return GestureDetector(
              onTap: () => onSelected(l.languageId, l.language?.name),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  name,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─── Recording controls ───────────────────────────────────────────────────────

class _RecordingControls extends StatelessWidget {
  const _RecordingControls({required this.ctrl});
  final VocabularyController ctrl;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputBg = isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant;

    return Obx(() {
      final recording = ctrl.isRecording.value;
      final recordedPath = ctrl.recordedPath.value;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: inputBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => recording ? ctrl.stopRecording() : ctrl.startRecording(),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: recording ? AppColors.error : AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  recording ? Icons.stop_rounded : Icons.mic_none_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                recording
                    ? 'Recording… ${ctrl.recordingLabel}'
                    : recordedPath != null
                        ? 'Pronunciation recorded'
                        : 'Record a pronunciation (optional)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: recording ? AppColors.error : null,
                ),
              ),
            ),
            if (!recording && recordedPath != null) ...[
              IconButton(
                icon: const Icon(Icons.play_arrow_rounded, size: 22),
                onPressed: ctrl.playRecordedPreview,
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, size: 20, color: AppColors.error.withValues(alpha: 0.7)),
                onPressed: ctrl.discardRecording,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ],
        ),
      );
    });
  }
}
