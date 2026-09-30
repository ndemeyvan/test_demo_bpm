import 'package:flutter/material.dart';

import '../../../bpm_framework/bpm_framework.dart';

/// Renders a task's [FormDefinition] generically — one input per field,
/// with no bespoke screen needed. This is the piece that turns a BPM
/// task's form *metadata* into an actual UI: add a field to the engine's
/// `_formFor(...)`, no Flutter code changes.
///
/// The widget owns its field state and rebuilds [actionsBuilder] on every
/// change so callers can enable/disable submit buttons from the current
/// values and validity without any external form controller.
class DynamicFormView extends StatefulWidget {
  final FormDefinition form;
  final Map<String, dynamic> initialValues;
  final bool isBusy;
  final List<Widget> Function(Map<String, dynamic> values, bool isValid) actionsBuilder;

  const DynamicFormView({
    super.key,
    required this.form,
    this.initialValues = const {},
    required this.isBusy,
    required this.actionsBuilder,
  });

  @override
  State<DynamicFormView> createState() => _DynamicFormViewState();
}

class _DynamicFormViewState extends State<DynamicFormView> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, dynamic> _values = {};

  @override
  void initState() {
    super.initState();
    for (final field in widget.form.fields) {
      final initial = widget.initialValues[field.key];
      _values[field.key] = initial;
      if (field.type != FormFieldType.checkbox && field.type != FormFieldType.document) {
        _controllers[field.key] = TextEditingController(text: initial?.toString() ?? '');
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _isValid {
    for (final field in widget.form.fields) {
      if (!field.required) continue;
      final value = _values[field.key];
      if (value == null) return false;
      if (value is String && value.trim().isEmpty) return false;
      if (field.type == FormFieldType.number && num.tryParse('$value') == null) return false;
    }
    return true;
  }

  void _setValue(String key, dynamic value) {
    setState(() => _values[key] = value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final field in widget.form.fields) ...[
          _buildField(context, field),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 8),
        ...widget.actionsBuilder(Map.of(_values), _isValid),
      ],
    );
  }

  Widget _buildField(BuildContext context, FormFieldDef field) {
    final label = field.required ? '${field.label} *' : field.label;

    switch (field.type) {
      case FormFieldType.text:
      case FormFieldType.email:
      case FormFieldType.number:
        return TextField(
          controller: _controllers[field.key],
          enabled: !widget.isBusy,
          keyboardType: switch (field.type) {
            FormFieldType.email => TextInputType.emailAddress,
            FormFieldType.number => TextInputType.number,
            _ => TextInputType.text,
          },
          decoration: InputDecoration(
            labelText: label,
            hintText: field.hint,
            border: const OutlineInputBorder(),
          ),
          onChanged: (value) => _setValue(field.key, value),
        );

      case FormFieldType.textarea:
        return TextField(
          controller: _controllers[field.key],
          enabled: !widget.isBusy,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: label,
            hintText: field.hint,
            border: const OutlineInputBorder(),
          ),
          onChanged: (value) => _setValue(field.key, value),
        );

      case FormFieldType.select:
        return DropdownButtonFormField<String>(
          initialValue: _values[field.key] as String?,
          items: [
            for (final option in field.options ?? const [])
              DropdownMenuItem(value: option.value, child: Text(option.label)),
          ],
          onChanged: widget.isBusy ? null : (value) => _setValue(field.key, value),
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        );

      case FormFieldType.checkbox:
        return CheckboxListTile(
          value: _values[field.key] as bool? ?? false,
          onChanged: widget.isBusy ? null : (value) => _setValue(field.key, value ?? false),
          title: Text(field.label),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        );

      case FormFieldType.document:
        final uploaded = _values[field.key] as String?;
        final colors = Theme.of(context).colorScheme;
        return InkWell(
          onTap: widget.isBusy ? null : () => _setValue(field.key, 'document.pdf'),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: colors.outline),
              borderRadius: BorderRadius.circular(12),
              color: uploaded != null ? colors.secondaryContainer : colors.surfaceContainerHighest,
            ),
            child: Row(
              children: [
                Icon(
                  uploaded != null ? Icons.check_circle_rounded : Icons.upload_file_rounded,
                  color: uploaded != null ? colors.secondary : colors.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(uploaded ?? label)),
              ],
            ),
          ),
        );
    }
  }
}
