import 'package:flutter/material.dart';

/// 通用漂亮输入框
class PrettyField extends StatefulWidget {
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final bool isPassword;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;

  const PrettyField({
    Key? key,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.isPassword = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.controller,
  }) : super(key: key);

  @override
  State<PrettyField> createState() => _PrettyFieldState();
}

class _PrettyFieldState extends State<PrettyField> {
  late TextEditingController _ctrl;
  bool _obscure = true;
  bool _hasFocus = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrl = widget.controller ?? TextEditingController();
  }

  @override
  void dispose() {
    if (widget.controller == null) _ctrl.dispose();
    super.dispose();
  }

  void _validate(String v) {
    setState(() => _error = widget.validator?.call(v));
    widget.onChanged?.call(v);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(4);

    return Focus(
      onFocusChange: (v) => setState(() => _hasFocus = v),
      child: TextFormField(
        controller: _ctrl,
        obscureText: widget.isPassword && _obscure,
        keyboardType: widget.keyboardType,
        onChanged: _validate,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          filled: true,
          fillColor: theme.colorScheme.surfaceVariant.withOpacity(.4),
          prefixIcon: Icon(widget.prefixIcon, size: 20),
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscure = !_obscure),
                )
              : _ctrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _ctrl.clear();
                        _validate('');
                      },
                    )
                  : null,
          enabledBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(color: theme.dividerColor, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
          ),
          errorText: _error,
          labelStyle: TextStyle(
            color: _hasFocus ? theme.colorScheme.primary : theme.hintColor,
          ),
          contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        ),
      ),
    );
  }
}