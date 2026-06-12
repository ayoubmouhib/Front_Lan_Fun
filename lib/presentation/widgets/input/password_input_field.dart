import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import 'text_input_field.dart';

class PasswordInputField extends StatefulWidget {
  const PasswordInputField({
    super.key,
    this.label = 'Password',
    this.hint = 'Enter your password',
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.textInputAction = TextInputAction.done,
    this.errorText,
    this.showStrengthIndicator = false,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final TextInputAction textInputAction;
  final String? errorText;
  final bool showStrengthIndicator;

  @override
  State<PasswordInputField> createState() => _PasswordInputFieldState();
}

class _PasswordInputFieldState extends State<PasswordInputField> {
  bool _obscure = true;
  String _value = '';

  int get _strength {
    if (_value.length < 6) return 0;
    int score = 0;
    if (_value.length >= 8) score++;
    if (_value.contains(RegExp(r'[A-Z]'))) score++;
    if (_value.contains(RegExp(r'[0-9]'))) score++;
    if (_value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;
    return score;
  }

  Color get _strengthColor => switch (_strength) {
        0 || 1 => AppColors.error,
        2       => AppColors.warning,
        3       => AppColors.info,
        _       => AppColors.success,
      };

  String get _strengthLabel => switch (_strength) {
        0 || 1 => 'Weak',
        2       => 'Fair',
        3       => 'Good',
        _       => 'Strong',
      };

  void _onChanged(String v) {
    setState(() => _value = v);
    widget.onChanged?.call(v);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextInputField(
          label: widget.label,
          hint: widget.hint,
          controller: widget.controller,
          focusNode: widget.focusNode,
          onChanged: _onChanged,
          onSubmitted: widget.onSubmitted,
          validator: widget.validator,
          keyboardType: TextInputType.visiblePassword,
          textInputAction: widget.textInputAction,
          obscureText: _obscure,
          errorText: widget.errorText,
          prefixIcon: Icons.lock_outline_rounded,
          suffixIcon: _obscure
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          onSuffixTap: () => setState(() => _obscure = !_obscure),
        ),
        if (widget.showStrengthIndicator && _value.isNotEmpty) ...[
          const SizedBox(height: 8),
          _StrengthBar(strength: _strength, color: _strengthColor, label: _strengthLabel),
        ],
      ],
    );
  }
}

class _StrengthBar extends StatelessWidget {
  const _StrengthBar({
    required this.strength,
    required this.color,
    required this.label,
  });

  final int strength;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) {
            final filled = i < strength;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                height: 4,
                decoration: BoxDecoration(
                  color: filled ? color : AppColors.lightOutline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          'Password strength: $label',
          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
