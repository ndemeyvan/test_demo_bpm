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

  Map<String, dynamic> toJson() => {'value': value, 'label': label};

  factory FormFieldOption.fromJson(Map<String, dynamic> json) {
    return FormFieldOption(value: json['value'] as String, label: json['label'] as String);
  }
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

  Map<String, dynamic> toJson() => {
        'key': key,
        'label': label,
        'type': type.name,
        'required': required,
        'hint': hint,
        'options': options?.map((o) => o.toJson()).toList(),
      };

  factory FormFieldDef.fromJson(Map<String, dynamic> json) {
    return FormFieldDef(
      key: json['key'] as String,
      label: json['label'] as String,
      type: FormFieldType.values.byName(json['type'] as String),
      required: json['required'] as bool? ?? false,
      hint: json['hint'] as String?,
      options: (json['options'] as List?)
          ?.map((o) => FormFieldOption.fromJson(o as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// The form a BPM engine attaches to a user task — mirrors what real
/// engines (Flowable/Camunda "form properties", Zeebe forms, …) send down
/// so a client can render one input per variable the task expects back,
/// without hardcoding a screen per task.
class FormDefinition {
  final List<FormFieldDef> fields;

  const FormDefinition({required this.fields});

  Map<String, dynamic> toJson() => {'fields': fields.map((f) => f.toJson()).toList()};

  factory FormDefinition.fromJson(Map<String, dynamic> json) {
    return FormDefinition(
      fields: (json['fields'] as List)
          .map((f) => FormFieldDef.fromJson(f as Map<String, dynamic>))
          .toList(),
    );
  }
}
