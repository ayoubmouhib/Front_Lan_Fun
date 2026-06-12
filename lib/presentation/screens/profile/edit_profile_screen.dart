import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../config/constants.dart';
import '../../../config/theme.dart';
import '../../controllers/profile_controller.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _locationCtrl;

  int? _selectedAge;

  @override
  void initState() {
    super.initState();
    final c = ProfileController.to;
    _firstNameCtrl = TextEditingController(text: c.user.value?.firstName ?? '');
    _lastNameCtrl  = TextEditingController(text: c.user.value?.lastName  ?? '');
    _bioCtrl       = TextEditingController(text: c.bio.value);
    _locationCtrl  = TextEditingController(text: c.location.value);
    _selectedAge   = c.user.value?.age;
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _bioCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  // ─── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final c = ProfileController.to;

    if (c.selectedInterestIds.length < AppConstants.minInterests) {
      Get.snackbar(
        'Interests Required',
        'Select at least ${AppConstants.minInterests} interests',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }

    final ok = await c.saveProfile(
      firstName:    _firstNameCtrl.text.trim(),
      lastName:     _lastNameCtrl.text.trim(),
      age:          _selectedAge,
      bioText:      _bioCtrl.text.trim(),
      locationText: _locationCtrl.text.trim(),
      interestIds:  c.selectedInterestIds.toList(),
    );

    if (ok) {
      Get.back();
      Get.snackbar(
        'Profile Updated',
        'Your changes have been saved',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c      = ProfileController.to;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: BackButton(onPressed: Get.back),
        actions: [
          Obx(() => TextButton(
            onPressed: c.isSaving.value ? null : _save,
            child: c.isSaving.value
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
          )),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [

            // ── Avatar picker ─────────────────────────────────────────
            Obx(() => _AvatarPicker(
                  initials: c.user.value?.fullName ?? '?',
                  imageUrl: c.user.value?.profilePictureUrl,
                  isUploading: c.isUploadingAvatar.value,
                  onTap: c.pickAndUploadAvatar,
                )),
            const SizedBox(height: 32),

            // ── Personal information ──────────────────────────────────
            const _SectionLabel('Personal Information'),
            const SizedBox(height: 14),

            _InputField(
              controller: _firstNameCtrl,
              label: 'First Name',
              icon: Icons.badge_outlined,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'First name is required' : null,
            ),
            const SizedBox(height: 14),

            _InputField(
              controller: _lastNameCtrl,
              label: 'Last Name',
              icon: Icons.badge_outlined,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Last name is required' : null,
            ),
            const SizedBox(height: 14),

            _AgeDropdown(
              value: _selectedAge,
              isDark: isDark,
              onChanged: (v) => setState(() => _selectedAge = v),
            ),
            const SizedBox(height: 14),

            _InputField(
              controller: _locationCtrl,
              label: 'Location',
              icon: Icons.location_on_outlined,
              hint: 'City, Country',
            ),
            const SizedBox(height: 32),

            // ── Bio ───────────────────────────────────────────────────
            const _SectionLabel('About You'),
            const SizedBox(height: 14),

            TextFormField(
              controller: _bioCtrl,
              maxLines: 4,
              maxLength: AppConstants.maxBioLength,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                labelText: 'Bio',
                hintText: 'Tell others about yourself...',
                alignLabelWithHint: true,
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 56),
                  child: Icon(Icons.info_outline_rounded),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── Interests ─────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _SectionLabel('Interests'),
                Obx(() {
                  final cnt = c.selectedInterestIds.length;
                  return Text(
                    '$cnt / ${AppConstants.maxInterests}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: cnt < AppConstants.minInterests
                          ? AppColors.error
                          : AppColors.secondary,
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Choose at least ${AppConstants.minInterests} interests',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
            ),
            const SizedBox(height: 14),

            Obx(() {
              final all = c.allInterests;
              if (all.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: all.map((item) {
                  final id       = item['id'] as int;
                  final name     = item['name'] as String? ?? '';
                  final selected = c.selectedInterestIds.contains(id);
                  return _InterestChip(
                    name: name,
                    selected: selected,
                    onTap: () {
                      if (!selected &&
                          c.selectedInterestIds.length >=
                              AppConstants.maxInterests) {
                        Get.snackbar(
                          'Limit Reached',
                          'You can select up to ${AppConstants.maxInterests} interests',
                          snackPosition: SnackPosition.BOTTOM,
                          margin: const EdgeInsets.all(16),
                        );
                        return;
                      }
                      c.toggleInterest(id);
                    },
                  );
                }).toList(),
              );
            }),

            const SizedBox(height: 32),

            // ── Languages I'm learning ────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _SectionLabel('Languages I\'m Learning'),
                TextButton.icon(
                  onPressed: () => Get.dialog(_AddLanguageDialog(ctrl: c)),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Obx(() {
              final learning = c.user.value?.learningLanguages ?? [];
              if (learning.isEmpty) {
                return Text(
                  'You\'re not learning any language yet — tap "Add" to start one.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                );
              }
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: learning.map((lang) {
                  return _LanguageChip(
                    name: lang.language?.name ?? 'Language',
                    level: c.languageLevelLabel(lang.level),
                  );
                }).toList(),
              );
            }),

            const SizedBox(height: 32),

            // ── Error banner ──────────────────────────────────────────
            Obx(() {
              final err = c.errorMessage.value;
              if (err == null) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        err,
                        style: const TextStyle(
                            color: AppColors.error, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              );
            }),

            // ── Save button ───────────────────────────────────────────
            Obx(() => _GradientButton(
                  label: 'Save Changes',
                  isLoading: c.isSaving.value,
                  onTap: c.isSaving.value ? null : _save,
                )),
            const SizedBox(height: 16),

            // ── Change password ───────────────────────────────────────
            OutlinedButton.icon(
              onPressed: () => Get.dialog(_ChangePasswordDialog(ctrl: c)),
              icon: const Icon(Icons.lock_outline_rounded),
              label: const Text('Change Password'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ─── Avatar picker ────────────────────────────────────────────────────────────

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({
    required this.initials,
    required this.onTap,
    this.imageUrl,
    this.isUploading = false,
  });

  final String initials;
  final String? imageUrl;
  final bool isUploading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final letter = initials.isNotEmpty ? initials[0].toUpperCase() : '?';
    return Center(
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipOval(
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => _initialsAvatar(letter),
                      errorWidget: (_, _, _) => _initialsAvatar(letter),
                    )
                  : _initialsAvatar(letter),
            ),
          ),
          if (isUploading)
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black45,
                ),
                child: const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  ),
                ),
              ),
            ),
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: isUploading ? null : onTap,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: AppColors.purpleGradient,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 2),
                ),
                child: const Icon(Icons.camera_alt_rounded,
                    color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _initialsAvatar(String letter) => Center(
        child: Text(
          letter,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 38,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context)
          .textTheme
          .titleSmall
          ?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

// ─── Text input field ─────────────────────────────────────────────────────────

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
      ),
    );
  }
}

// ─── Age dropdown ─────────────────────────────────────────────────────────────

class _AgeDropdown extends StatelessWidget {
  const _AgeDropdown({
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  final int? value;
  final bool isDark;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      decoration: const InputDecoration(
        labelText: 'Age',
        prefixIcon: Icon(Icons.cake_outlined),
      ),
      hint: const Text('Select your age'),
      isExpanded: true,
      items: List.generate(
        AppConstants.maxAge - AppConstants.minAge + 1,
        (i) {
          final age = AppConstants.minAge + i;
          return DropdownMenuItem(value: age, child: Text('$age'));
        },
      ),
      onChanged: onChanged,
    );
  }
}

// ─── Interest chip ────────────────────────────────────────────────────────────

class _InterestChip extends StatelessWidget {
  const _InterestChip({
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.12)
              : (Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkSurfaceVariant
                  : AppColors.lightSurfaceVariant),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.5)
                : (Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkOutline
                    : AppColors.lightOutline),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 14),
              const SizedBox(width: 6),
            ],
            Text(
              name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? AppColors.primary
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Language chip (read-only — shows a language the user is learning) ───────

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({required this.name, required this.level});

  final String name;
  final String level;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.translate_rounded, size: 14, color: AppColors.secondary),
          const SizedBox(width: 6),
          Text(
            name,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 6),
          Text(
            '· $level',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Gradient save button ─────────────────────────────────────────────────────

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  final String label;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 54,
        decoration: BoxDecoration(
          gradient: onTap != null
              ? AppColors.primaryGradient
              : const LinearGradient(
                  colors: [Color(0xFFAAAAAA), Color(0xFF888888)]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: onTap != null
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}

// ─── Change password dialog ───────────────────────────────────────────────────

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog({required this.ctrl});
  final ProfileController ctrl;

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _oldPw  = TextEditingController();
  final _newPw  = TextEditingController();
  final _confPw = TextEditingController();

  bool _showOld = false;
  bool _showNew = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _oldPw.dispose();
    _newPw.dispose();
    _confPw.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_oldPw.text.isEmpty) {
      setState(() => _error = 'Enter your current password');
      return;
    }
    if (_newPw.text.length < 8) {
      setState(() => _error = 'New password must be at least 8 characters');
      return;
    }
    if (_newPw.text != _confPw.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }

    setState(() { _loading = true; _error = null; });

    final ok = await widget.ctrl.changePassword(
      oldPassword: _oldPw.text,
      newPassword: _newPw.text,
    );

    if (!mounted) return;

    if (ok) {
      Get.back();
      Get.snackbar(
        'Password Changed',
        'Your password has been updated',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );
    } else {
      setState(() {
        _loading = false;
        _error = widget.ctrl.errorMessage.value ?? 'Failed to change password';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change Password'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                            color: AppColors.error, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
            TextField(
              controller: _oldPw,
              obscureText: !_showOld,
              enabled: !_loading,
              decoration: InputDecoration(
                labelText: 'Current Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(_showOld
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () => setState(() => _showOld = !_showOld),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newPw,
              obscureText: !_showNew,
              enabled: !_loading,
              decoration: InputDecoration(
                labelText: 'New Password',
                prefixIcon: const Icon(Icons.lock_rounded),
                suffixIcon: IconButton(
                  icon: Icon(_showNew
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () => setState(() => _showNew = !_showNew),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confPw,
              obscureText: true,
              enabled: !_loading,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                prefixIcon: Icon(Icons.lock_rounded),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : Get.back,
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Change'),
        ),
      ],
    );
  }
}

// ─── Add language dialog ──────────────────────────────────────────────────────

class _AddLanguageDialog extends StatefulWidget {
  const _AddLanguageDialog({required this.ctrl});
  final ProfileController ctrl;

  @override
  State<_AddLanguageDialog> createState() => _AddLanguageDialogState();
}

class _AddLanguageDialogState extends State<_AddLanguageDialog> {
  static const _levels = ['beginner', 'intermediate', 'advanced'];

  int? _selectedLanguageId;
  String _selectedLevel = _levels.first;
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    final languageId = _selectedLanguageId;
    if (languageId == null) {
      setState(() => _error = 'Choose a language first');
      return;
    }

    setState(() { _loading = true; _error = null; });

    final ok = await widget.ctrl.addLanguage(languageId, _selectedLevel);

    if (!mounted) return;

    if (ok) {
      Get.back();
      Get.snackbar(
        'Language Added',
        'You can now practice it in quizzes and games',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final candidates = widget.ctrl.languagesAvailableToAdd;

    return AlertDialog(
      title: const Text('Add a Language'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                            color: AppColors.error, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
            if (candidates.isEmpty)
              const Text(
                'You\'re already learning every available language!',
              )
            else ...[
              DropdownButtonFormField<int>(
                initialValue: _selectedLanguageId,
                decoration: const InputDecoration(
                  labelText: 'Language',
                  prefixIcon: Icon(Icons.public_rounded),
                ),
                items: candidates
                    .map((lang) => DropdownMenuItem(
                          value: lang.id,
                          child: Text(lang.nativeName ?? lang.name),
                        ))
                    .toList(),
                onChanged: _loading
                    ? null
                    : (v) => setState(() => _selectedLanguageId = v),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _selectedLevel,
                decoration: const InputDecoration(
                  labelText: 'Your current level',
                  prefixIcon: Icon(Icons.bar_chart_rounded),
                ),
                items: _levels
                    .map((level) => DropdownMenuItem(
                          value: level,
                          child: Text(widget.ctrl.languageLevelLabel(level)),
                        ))
                    .toList(),
                onChanged: _loading
                    ? null
                    : (v) => setState(() => _selectedLevel = v ?? _selectedLevel),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : Get.back,
          child: const Text('Cancel'),
        ),
        if (candidates.isNotEmpty)
          TextButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Add'),
          ),
      ],
    );
  }
}
