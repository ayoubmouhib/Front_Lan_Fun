import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../config/constants.dart';
import '../../../config/theme.dart';
import '../../../utils/validators.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/input/password_input_field.dart';
import '../../widgets/input/text_input_field.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  late final AuthController _auth;
  final PageController _pageCtrl = PageController();

  // Step form keys
  final List<GlobalKey<FormState>> _formKeys =
      List.generate(6, (_) => GlobalKey<FormState>());

  // Step 1 — Personal Info
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl  = TextEditingController();
  final _usernameCtrl  = TextEditingController();
  final _emailCtrl     = TextEditingController();

  // Step 2 — Password
  final _passwordCtrl  = TextEditingController();
  final _confirmCtrl   = TextEditingController();

  // Step 3 — Age
  int? _age;

  // Step 4 — Native language (id + level)
  int?    _nativeLangId;
  String  _nativeLevel = 'beginner';

  // Step 5 — Learning languages
  final List<Map<String, dynamic>> _learningLangs = [];

  // Step 6 — Interests
  final Set<int> _selectedInterestIds = {};

  static const _stepTitles = [
    'Personal Info',
    'Set Password',
    'Your Age',
    'Native Language',
    'Languages to Learn',
    'Your Interests',
  ];

  @override
  void initState() {
    super.initState();
    _auth = Get.find<AuthController>();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ─── Navigation ──────────────────────────────────────────────────────────

  void _next() {
    final step = _auth.signupStep.value;
    if (!(_formKeys[step].currentState?.validate() ?? true)) return;
    if (!_stepIsValid(step)) return;

    _collectStepData(step);

    if (step < 5) {
      _auth.nextSignupStep();
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _auth.submitSignup();
    }
  }

  void _prev() {
    if (_auth.signupStep.value == 0) {
      Get.back();
    } else {
      _auth.prevSignupStep();
      _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _stepIsValid(int step) {
    switch (step) {
      case 3:
        if (_nativeLangId == null) {
          _showError('Please select your native language');
          return false;
        }
      case 4:
        if (_learningLangs.isEmpty) {
          _showError('Please select at least one language to learn');
          return false;
        }
      case 5:
        if (_selectedInterestIds.length < AppConstants.minInterests) {
          _showError('Please select at least ${AppConstants.minInterests} interests');
          return false;
        }
    }
    return true;
  }

  void _collectStepData(int step) {
    switch (step) {
      case 0:
        _auth.updateSignupData({
          'first_name': _firstNameCtrl.text.trim(),
          'last_name':  _lastNameCtrl.text.trim(),
          'username':   _usernameCtrl.text.trim(),
          'email':      _emailCtrl.text.trim(),
        });
      case 1:
        _auth.updateSignupData({'password': _passwordCtrl.text});
      case 2:
        if (_age != null) _auth.updateSignupData({'age': _age});
      case 3:
        _auth.updateSignupData({
          'preferred_language_id': _nativeLangId,
        });
      case 4:
        _auth.updateSignupData({
          'languages': _learningLangs,
        });
      case 5:
        _auth.updateSignupData({
          'interest_ids': _selectedInterestIds.toList(),
        });
    }
  }

  void _showError(String msg) {
    Get.snackbar(
      'Missing Info',
      msg,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      backgroundColor: AppColors.error.withValues(alpha: 0.9),
      colorText: Colors.white,
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────
            _Header(onBack: _prev),

            // ── Progress bar ──────────────────────────────────────
            Obx(() => _ProgressBar(step: _auth.signupStep.value, total: 6)),

            const SizedBox(height: 8),

            // ── Step title ────────────────────────────────────────
            Obx(() => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Step ${_auth.signupStep.value + 1} of 6',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _stepTitles[_auth.signupStep.value],
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                )),

            const SizedBox(height: 20),

            // ── Pages ─────────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _Step1PersonalInfo(
                    formKey: _formKeys[0],
                    firstNameCtrl: _firstNameCtrl,
                    lastNameCtrl: _lastNameCtrl,
                    usernameCtrl: _usernameCtrl,
                    emailCtrl: _emailCtrl,
                  ),
                  _Step2Password(
                    formKey: _formKeys[1],
                    passwordCtrl: _passwordCtrl,
                    confirmCtrl: _confirmCtrl,
                  ),
                  _Step3Age(
                    formKey: _formKeys[2],
                    selectedAge: _age,
                    onChanged: (v) => setState(() => _age = v),
                  ),
                  Obx(() => _Step4NativeLanguage(
                        formKey: _formKeys[3],
                        languages: _auth.languages.toList(),
                        selectedId: _nativeLangId,
                        selectedLevel: _nativeLevel,
                        onLanguageChanged: (id, name) =>
                            setState(() => _nativeLangId = id),
                        onLevelChanged: (v) =>
                            setState(() => _nativeLevel = v),
                      )),
                  Obx(() => _Step5LearningLanguages(
                        formKey: _formKeys[4],
                        languages: _auth.languages.toList(),
                        nativeLangId: _nativeLangId,
                        selected: _learningLangs,
                        onAdd: (entry) =>
                            setState(() => _learningLangs.add(entry)),
                        onRemove: (id) => setState(() =>
                            _learningLangs.removeWhere(
                                (e) => e['language_id'] == id)),
                        onUpdateLevel: (id, level) => setState(() {
                          final idx = _learningLangs
                              .indexWhere((e) => e['language_id'] == id);
                          if (idx != -1) {
                            _learningLangs[idx] = {
                              ..._learningLangs[idx],
                              'level': level,
                            };
                          }
                        }),
                      )),
                  Obx(() => _Step6Interests(
                        formKey: _formKeys[5],
                        interests: _auth.interests.toList(),
                        selected: _selectedInterestIds,
                        onToggle: (id) => setState(() {
                          if (_selectedInterestIds.contains(id)) {
                            _selectedInterestIds.remove(id);
                          } else {
                            _selectedInterestIds.add(id);
                          }
                        }),
                      )),
                ],
              ),
            ),

            // ── Error ─────────────────────────────────────────────
            Obx(() {
              final err = _auth.errorMessage.value;
              if (err == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: _ErrorBanner(message: err),
              );
            }),

            // ── Bottom buttons ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Obx(() {
                final step = _auth.signupStep.value;
                final isLast = step == 5;
                return PrimaryButton(
                  label: isLast ? 'Create Account' : 'Next',
                  onPressed: _next,
                  isLoading: _auth.isLoading.value,
                  icon: isLast
                      ? Icons.check_circle_outline_rounded
                      : Icons.arrow_forward_rounded,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── STEP WIDGETS ────────────────────────────────────────────────────────────

class _Step1PersonalInfo extends StatelessWidget {
  const _Step1PersonalInfo({
    required this.formKey,
    required this.firstNameCtrl,
    required this.lastNameCtrl,
    required this.usernameCtrl,
    required this.emailCtrl,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameCtrl, lastNameCtrl, usernameCtrl, emailCtrl;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextInputField(
                    label: 'First Name',
                    hint: 'John',
                    controller: firstNameCtrl,
                    prefixIcon: Icons.person_outline_rounded,
                    validator: Validators.name,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextInputField(
                    label: 'Last Name',
                    hint: 'Doe',
                    controller: lastNameCtrl,
                    prefixIcon: Icons.person_outline_rounded,
                    validator: Validators.name,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextInputField(
              label: 'Username',
              hint: 'john_doe',
              controller: usernameCtrl,
              prefixIcon: Icons.alternate_email_rounded,
              validator: Validators.username,
            ),
            const SizedBox(height: 16),
            TextInputField(
              label: 'Email Address',
              hint: 'john@example.com',
              controller: emailCtrl,
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: Validators.email,
            ),
          ],
        ),
      ),
    );
  }
}

class _Step2Password extends StatelessWidget {
  const _Step2Password({
    required this.formKey,
    required this.passwordCtrl,
    required this.confirmCtrl,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController passwordCtrl, confirmCtrl;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PasswordInputField(
              label: 'Password',
              controller: passwordCtrl,
              showStrengthIndicator: true,
              validator: Validators.password,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            PasswordInputField(
              label: 'Confirm Password',
              hint: 'Re-enter your password',
              controller: confirmCtrl,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please confirm your password';
                if (v != passwordCtrl.text) return 'Passwords do not match';
                return null;
              },
            ),
            const SizedBox(height: 20),
            _PasswordHints(),
          ],
        ),
      ),
    );
  }
}

class _PasswordHints extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const hints = [
      'At least 8 characters',
      'One uppercase letter',
      'One number',
      'One special character',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Password requirements:',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ...hints.map((h) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(h, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            )),
      ],
    );
  }
}

class _Step3Age extends StatelessWidget {
  const _Step3Age({
    required this.formKey,
    required this.selectedAge,
    required this.onChanged,
  });

  final GlobalKey<FormState> formKey;
  final int? selectedAge;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How old are you?',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<int>(
              initialValue: selectedAge,
              decoration: const InputDecoration(
                labelText: 'Age',
                prefixIcon: Icon(Icons.cake_outlined),
              ),
              items: List.generate(
                AppConstants.maxAge - AppConstants.minAge + 1,
                (i) {
                  final age = AppConstants.minAge + i;
                  return DropdownMenuItem(value: age, child: Text('$age'));
                },
              ),
              onChanged: onChanged,
              validator: (v) => v == null ? 'Please select your age' : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _Step4NativeLanguage extends StatelessWidget {
  const _Step4NativeLanguage({
    required this.formKey,
    required this.languages,
    required this.selectedId,
    required this.selectedLevel,
    required this.onLanguageChanged,
    required this.onLevelChanged,
  });

  final GlobalKey<FormState> formKey;
  final List<Map<String, dynamic>> languages;
  final int? selectedId;
  final String selectedLevel;
  final void Function(int id, String name) onLanguageChanged;
  final ValueChanged<String> onLevelChanged;

  @override
  Widget build(BuildContext context) {
    final langList = languages.isNotEmpty
        ? languages
        : AppConstants.supportedLanguages
            .asMap()
            .entries
            .map((e) => <String, dynamic>{
                  'id': e.key + 1,
                  'name': e.value['name'],
                  'iso_code': e.value['iso'],
                })
            .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What is your native language?',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<int>(
              initialValue: selectedId,
              decoration: const InputDecoration(
                labelText: 'Native Language',
                prefixIcon: Icon(Icons.language_rounded),
              ),
              isExpanded: true,
              items: langList
                  .map((l) => DropdownMenuItem<int>(
                        value: l['id'] as int,
                        child: Text(
                          '${_flag(l["iso_code"] as String? ?? "")}  ${l["name"]}',
                        ),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                final name = langList
                    .firstWhere((l) => l['id'] == v)['name'] as String;
                onLanguageChanged(v, name);
              },
              validator: (v) =>
                  v == null ? 'Please select your native language' : null,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: selectedLevel,
              decoration: const InputDecoration(
                labelText: 'Proficiency Level',
                prefixIcon: Icon(Icons.bar_chart_rounded),
              ),
              items: const [
                DropdownMenuItem(value: 'beginner',     child: Text('Beginner')),
                DropdownMenuItem(value: 'intermediate', child: Text('Intermediate')),
                DropdownMenuItem(value: 'advanced',     child: Text('Advanced / Native')),
              ],
              onChanged: (v) { if (v != null) onLevelChanged(v); },
            ),
          ],
        ),
      ),
    );
  }

  String _flag(String iso) {
    final match = AppConstants.supportedLanguages
        .where((l) => l['iso'] == iso)
        .toList();
    return match.isNotEmpty ? match.first['flag']! : '';
  }
}

class _Step5LearningLanguages extends StatelessWidget {
  const _Step5LearningLanguages({
    required this.formKey,
    required this.languages,
    required this.nativeLangId,
    required this.selected,
    required this.onAdd,
    required this.onRemove,
    required this.onUpdateLevel,
  });

  final GlobalKey<FormState> formKey;
  final List<Map<String, dynamic>> languages;
  final int? nativeLangId;
  final List<Map<String, dynamic>> selected;
  final ValueChanged<Map<String, dynamic>> onAdd;
  final ValueChanged<int> onRemove;
  final void Function(int langId, String level) onUpdateLevel;

  static const _levelOptions = <Map<String, String>>[
    {'value': 'beginner',     'label': 'Beginner',     'desc': 'Just starting out'},
    {'value': 'intermediate', 'label': 'Intermediate', 'desc': 'Have some experience'},
    {'value': 'advanced',     'label': 'Advanced',     'desc': 'Near fluent or fluent'},
  ];

  void _pickLevel(
    BuildContext context,
    int langId,
    String langName,
    String? currentLevel,
  ) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                langName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Select your current level',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 12),
              ..._levelOptions.map((lvl) {
                final value    = lvl['value']!;
                final label    = lvl['label']!;
                final desc     = lvl['desc']!;
                final isActive = currentLevel == value;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    label,
                    style: TextStyle(
                      fontWeight:
                          isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive ? AppColors.primary : null,
                    ),
                  ),
                  subtitle: Text(desc, style: const TextStyle(fontSize: 12)),
                  trailing: isActive
                      ? const Icon(Icons.check_circle_rounded,
                          color: AppColors.primary)
                      : const Icon(Icons.radio_button_unchecked_rounded,
                          color: Colors.grey),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    if (currentLevel == null) {
                      onAdd({
                        'language_id': langId,
                        'level': value,
                        'user_type': 'learning',
                      });
                    } else {
                      onUpdateLevel(langId, value);
                    }
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final available  = languages.where((l) => l['id'] != nativeLangId).toList();
    final selectedIds = selected.map((e) => e['language_id'] as int).toSet();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Which languages do you want to learn?',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 6),
            Text(
              '${selected.length} selected',
              style: const TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            // Selected chips — show level and allow tap-to-edit
            if (selected.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selected.map((e) {
                  final id    = e['language_id'] as int;
                  final level = e['level'] as String;
                  final name  = (available.firstWhere(
                    (l) => l['id'] == id,
                    orElse: () => {'name': '?'},
                  )['name'] as String);
                  return GestureDetector(
                    onTap: () => _pickLevel(context, id, name, level),
                    child: Chip(
                      label: Text('$name · ${_levelLabel(level)}'),
                      deleteIcon: const Icon(Icons.close_rounded, size: 16),
                      onDeleted: () => onRemove(id),
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      labelStyle: const TextStyle(
                          color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap a language to change its level',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 12),
            ],

            // Available list — tap to pick level then add (or re-pick level if already selected)
            ...available.map((l) {
              final id         = l['id'] as int;
              final name       = l['name'] as String;
              final iso        = l['iso_code'] as String? ?? '';
              final isSelected = selectedIds.contains(id);
              final currentLevel = isSelected
                  ? selected.firstWhere(
                        (e) => e['language_id'] == id)['level'] as String
                  : null;

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Text(_flag(iso), style: const TextStyle(fontSize: 24)),
                title: Text(name, style: Theme.of(context).textTheme.bodyMedium),
                subtitle: isSelected
                    ? Text(
                        _levelLabel(currentLevel!),
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      )
                    : null,
                trailing: isSelected
                    ? const Icon(Icons.check_circle_rounded,
                        color: AppColors.primary)
                    : const Icon(Icons.add_circle_outline_rounded),
                onTap: () => _pickLevel(context, id, name, currentLevel),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _levelLabel(String level) => switch (level) {
    'beginner'     => 'Beginner',
    'intermediate' => 'Intermediate',
    'advanced'     => 'Advanced',
    _              => level,
  };

  String _flag(String iso) {
    final match =
        AppConstants.supportedLanguages.where((l) => l['iso'] == iso).toList();
    return match.isNotEmpty ? match.first['flag']! : '🌐';
  }
}

class _Step6Interests extends StatelessWidget {
  const _Step6Interests({
    required this.formKey,
    required this.interests,
    required this.selected,
    required this.onToggle,
  });

  final GlobalKey<FormState> formKey;
  final List<Map<String, dynamic>> interests;
  final Set<int> selected;
  final ValueChanged<int> onToggle;

  static const _icons = <String, IconData>{
    'flight': Icons.flight_rounded,
    'restaurant': Icons.restaurant_rounded,
    'music_note': Icons.music_note_rounded,
    'sports_soccer': Icons.sports_soccer_rounded,
    'computer': Icons.computer_rounded,
    'palette': Icons.palette_rounded,
    'book': Icons.book_rounded,
    'movie': Icons.movie_rounded,
    'sports_esports': Icons.sports_esports_rounded,
    'camera_alt': Icons.camera_alt_rounded,
    'restaurant_menu': Icons.restaurant_menu_rounded,
    'fitness_center': Icons.fitness_center_rounded,
    'nature': Icons.nature_rounded,
    'checkroom': Icons.checkroom_rounded,
    'science': Icons.science_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final list = interests.isNotEmpty
        ? interests
        : AppConstants.availableInterests
            .asMap()
            .entries
            .map((e) => <String, dynamic>{
                  'id': e.key + 1,
                  'name': e.value['name'],
                  'icon': e.value['icon'],
                })
            .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select at least ${AppConstants.minInterests} interests',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 6),
            Text(
              '${selected.length} selected',
              style: TextStyle(
                color: selected.length >= AppConstants.minInterests
                    ? AppColors.success
                    : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final id   = list[i]['id'] as int;
                final name = list[i]['name'] as String;
                final iconKey = list[i]['icon'] as String? ?? '';
                final icon = _icons[iconKey] ?? Icons.star_rounded;
                final isSelected = selected.contains(id);

                return GestureDetector(
                  onTap: () => onToggle(id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          size: 28,
                          color: isSelected
                              ? AppColors.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: isSelected
                                ? AppColors.primary
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared helpers ──────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Get.offAllNamed('/login'),
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.step, required this.total});
  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: List.generate(total, (i) {
          final done = i <= step;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 4,
              margin: EdgeInsets.only(right: i < total - 1 ? 4 : 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: done ? AppColors.primaryGradient : null,
                color: done
                    ? null
                    : Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.3),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
