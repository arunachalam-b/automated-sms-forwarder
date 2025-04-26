enum FilterConditionType {
  sender,
  content,
}

// Helper to get enum from string (case-insensitive)
FilterConditionType fromString(String value) {
  return FilterConditionType.values.firstWhere(
    (e) => e.name.toLowerCase() == value.toLowerCase(),
    orElse: () => FilterConditionType.content, // Default fallback
  );
}

class FilterCondition {
  final FilterConditionType type;
  final String value;
  final bool caseSensitive; // Only relevant for content type

  FilterCondition({
    required this.type,
    required this.value,
    this.caseSensitive = false,
  });

  // To JSON Map
  Map<String, dynamic> toJson() => {
        'type': type.name, // Store enum as its string name
        'value': value,
        'caseSensitive': caseSensitive,
      };

  // From JSON Map
  factory FilterCondition.fromJson(Map<String, dynamic> json) => FilterCondition(
        type: fromString(json['type'] as String),
        value: json['value'] as String,
        caseSensitive: json['caseSensitive'] as bool? ?? false, // Handle potential null
      );
}

class Filter {
  final String id; // To uniquely identify for editing/deleting
  final List<String> recipients; // Phone numbers or contact IDs
  final List<FilterCondition> conditions;

  Filter({
    required this.id,
    required this.recipients,
    required this.conditions,
  });
} 