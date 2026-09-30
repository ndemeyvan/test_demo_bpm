/// Describes one field of a task's form.
///
/// This is metadata a BPM engine sends down alongside a user task so a
/// generic UI can render the right input without the app needing a
/// bespoke screen for every task — see `DynamicFormView`.
enum FormFieldType { text, email, number, textarea, select, checkbox, document }

class FormFieldOption {
  final String value;
  final String label;

  const FormFieldOption({required this.value, required this.label});
}

class FormFieldDef {
  final String key;
  final String label;
  final FormFieldType type;
  final bool required;
  final String? hint;
  final List<FormFieldOption>? options;

  const FormFieldDef({
    required this.key,
    required this.label,
    required this.type,
    this.required = false,
    this.hint,
    this.options,
  });
}

/// The form a BPM engine attaches to a user task — mirrors what real
/// engines (Flowable/Camunda "form properties", Zeebe forms, …) send down
/// so a client can render one input per variable the task expects back,
/// without hardcoding a screen per task.
class FormDefinition {
  final List<FormFieldDef> fields;

  const FormDefinition({required this.fields});
}
