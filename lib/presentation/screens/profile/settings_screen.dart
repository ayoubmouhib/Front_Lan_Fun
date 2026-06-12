import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../config/constants.dart';
import '../../../config/routes.dart';
import '../../../config/theme.dart';
import '../../controllers/app_controller.dart';
import '../../controllers/profile_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Notification toggles — stored in SharedPreferences
  bool _notifyMatch    = true;
  bool _notifyMessage  = true;
  bool _notifyCall     = true;
  bool _notifyAchieve  = true;
  bool _prefsLoaded    = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notifyMatch   = p.getBool('notify_match')   ?? true;
      _notifyMessage = p.getBool('notify_message') ?? true;
      _notifyCall    = p.getBool('notify_call')    ?? true;
      _notifyAchieve = p.getBool('notify_achieve') ?? true;
      _prefsLoaded   = true;
    });
  }

  Future<void> _setNotify(String key, bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(key, value);
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final profileCtrl = ProfileController.to;
    final appCtrl     = AppController.to;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: BackButton(onPressed: Get.back),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [

          // ── 1. Account ────────────────────────────────────────────
          _SectionHeader('Account'),

          Obx(() {
            final email = profileCtrl.email;
            final username = profileCtrl.username;
            return Column(
              children: [
                _InfoTile(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: email.isNotEmpty ? email : '—',
                ),
                _InfoTile(
                  icon: Icons.alternate_email_rounded,
                  label: 'Username',
                  value: username.isNotEmpty ? '@$username' : '—',
                ),
              ],
            );
          }),

          _NavTile(
            icon: Icons.edit_outlined,
            label: 'Edit Profile',
            onTap: () => Get.toNamed('/profile/edit'),
          ),
          _NavTile(
            icon: Icons.lock_outline_rounded,
            label: 'Change Password',
            onTap: () => Get.dialog(_ChangePasswordDialog(
              ctrl: profileCtrl,
            )),
          ),
          const _Divider(),

          // ── 2. Notifications ──────────────────────────────────────
          _SectionHeader('Notifications'),

          if (!_prefsLoaded)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            )
          else ...[
            _ToggleTile(
              icon: Icons.people_outline_rounded,
              label: 'Match Requests',
              subtitle: 'When someone wants to connect with you',
              value: _notifyMatch,
              onChanged: (v) {
                setState(() => _notifyMatch = v);
                _setNotify('notify_match', v);
              },
            ),
            _ToggleTile(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'New Messages',
              subtitle: 'When you receive a new message',
              value: _notifyMessage,
              onChanged: (v) {
                setState(() => _notifyMessage = v);
                _setNotify('notify_message', v);
              },
            ),
            _ToggleTile(
              icon: Icons.phone_outlined,
              label: 'Incoming Calls',
              subtitle: 'When someone calls you',
              value: _notifyCall,
              onChanged: (v) {
                setState(() => _notifyCall = v);
                _setNotify('notify_call', v);
              },
            ),
            _ToggleTile(
              icon: Icons.emoji_events_outlined,
              label: 'Achievements',
              subtitle: 'When you unlock a new badge or level up',
              value: _notifyAchieve,
              onChanged: (v) {
                setState(() => _notifyAchieve = v);
                _setNotify('notify_achieve', v);
              },
            ),
          ],
          const _Divider(),

          // ── 3. Appearance ─────────────────────────────────────────
          _SectionHeader('Appearance'),

          Obx(() {
            final mode = appCtrl.themeMode;
            return Column(
              children: [
                _ThemeOption(
                  icon: Icons.light_mode_rounded,
                  label: 'Light Mode',
                  selected: mode == ThemeMode.light,
                  onTap: () => appCtrl.setTheme(ThemeMode.light),
                ),
                _ThemeOption(
                  icon: Icons.dark_mode_rounded,
                  label: 'Dark Mode',
                  selected: mode == ThemeMode.dark,
                  onTap: () => appCtrl.setTheme(ThemeMode.dark),
                ),
                _ThemeOption(
                  icon: Icons.brightness_auto_rounded,
                  label: 'System Default',
                  selected: mode == ThemeMode.system,
                  onTap: () => appCtrl.setTheme(ThemeMode.system),
                ),
              ],
            );
          }),
          const _Divider(),

          // ── 4. Privacy & Safety ───────────────────────────────────
          _SectionHeader('Privacy & Safety'),

          _NavTile(
            icon: Icons.block_rounded,
            label: 'Blocked Users',
            onTap: () => Get.toNamed(Routes.blockedUsers),
          ),
          _NavTile(
            icon: Icons.privacy_tip_outlined,
            label: 'Privacy Policy',
            onTap: () => _showInfoDialog(
              context,
              'Privacy Policy',
              'Our privacy policy explains how we collect, use, and protect your personal information.\n\nVisit our website for the full privacy policy.',
            ),
          ),
          _NavTile(
            icon: Icons.gavel_rounded,
            label: 'Terms of Service',
            onTap: () => _showInfoDialog(
              context,
              'Terms of Service',
              'By using LinguaConnect, you agree to our terms of service.\n\nVisit our website for the full terms of service.',
            ),
          ),
          _NavTile(
            icon: Icons.flag_outlined,
            label: 'Report Abuse',
            onTap: () => Get.snackbar(
              'Report Abuse',
              'To report abuse, please contact us at support@linguaconnect.app',
              snackPosition: SnackPosition.BOTTOM,
              margin: const EdgeInsets.all(16),
            ),
          ),
          const _Divider(),

          // ── 5. About ──────────────────────────────────────────────
          _SectionHeader('About'),

          _InfoTile(
            icon: Icons.info_outline_rounded,
            label: 'Version',
            value: AppConstants.appVersion,
          ),
          _NavTile(
            icon: Icons.system_update_outlined,
            label: 'Check for Updates',
            onTap: () => Get.snackbar(
              'Up to Date',
              'You are running the latest version of ${AppConstants.appName}',
              snackPosition: SnackPosition.BOTTOM,
              margin: const EdgeInsets.all(16),
            ),
          ),
          _NavTile(
            icon: Icons.help_outline_rounded,
            label: 'Help & Support',
            onTap: () => _showInfoDialog(
              context,
              'Help & Support',
              'Need help? Contact us at support@linguaconnect.app\n\nWe typically respond within 24 hours.',
            ),
          ),
          const _Divider(),

          // ── 6. Danger zone ────────────────────────────────────────
          _SectionHeader('Account Actions'),

          // Logout
          _DangerTile(
            icon: Icons.logout_rounded,
            label: 'Log Out',
            color: AppColors.primary,
            onTap: () => _confirmLogout(context, profileCtrl),
          ),

          // Delete account
          _DangerTile(
            icon: Icons.delete_forever_rounded,
            label: 'Delete Account',
            color: AppColors.error,
            onTap: () => _confirmDelete(context, profileCtrl),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ─── Dialogs ───────────────────────────────────────────────────────────────

  void _showInfoDialog(BuildContext ctx, String title, String body) {
    Get.dialog(AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Close')),
      ],
    ));
  }

  void _confirmLogout(BuildContext ctx, ProfileController ctrl) {
    Get.dialog(AlertDialog(
      title: const Text('Log Out'),
      content: const Text('Are you sure you want to log out?'),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Cancel')),
        TextButton(
          onPressed: () { Get.back(); ctrl.logout(); },
          child: const Text(
            'Log Out',
            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ));
  }

  void _confirmDelete(BuildContext ctx, ProfileController ctrl) {
    Get.dialog(AlertDialog(
      title: const Text('Delete Account'),
      content: const Text(
        'This will permanently delete your account and all your data. '
        'This action cannot be undone.',
      ),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Cancel')),
        TextButton(
          onPressed: () { Get.back(); ctrl.deleteAccount(); },
          child: const Text(
            'Delete Forever',
            style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ));
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

// ─── Divider ──────────────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 20,
      endIndent: 20,
      color: Theme.of(context).dividerColor,
    );
  }
}

// ─── Info tile (read-only) ────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: ListTile(
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                )),
        trailing: Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.darkOnSurfaceVariant
                    : AppColors.lightOnSurfaceVariant,
              ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ─── Navigation tile (tappable) ───────────────────────────────────────────────

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                )),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: Theme.of(context)
              .colorScheme
              .onSurface
              .withValues(alpha: 0.35),
          size: 20,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ─── Toggle tile ──────────────────────────────────────────────────────────────

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: ListTile(
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                )),
        subtitle: subtitle != null
            ? Text(subtitle!, style: Theme.of(context).textTheme.bodySmall)
            : null,
        trailing: Switch(
          value: value,
          onChanged: onChanged,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ─── Theme option ─────────────────────────────────────────────────────────────

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.15)
                : AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: selected ? AppColors.primary : AppColors.lightOutlineVariant,
            size: 20,
          ),
        ),
        title: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? AppColors.primary
                    : Theme.of(context).colorScheme.onSurface,
              ),
        ),
        trailing: selected
            ? const Icon(Icons.check_circle_rounded,
                color: AppColors.primary, size: 22)
            : Icon(
                Icons.radio_button_unchecked_rounded,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.3),
                size: 22,
              ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ─── Danger tile ──────────────────────────────────────────────────────────────

class _DangerTile extends StatelessWidget {
  const _DangerTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
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
        'Your password has been updated successfully',
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
          children: [
            if (_error != null) ...[
              Container(
                width: double.infinity,
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
              : const Text('Change', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
