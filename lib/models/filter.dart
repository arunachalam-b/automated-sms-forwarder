enum FilterConditionType {
  sender,
  content,
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
}

class Filter {
  final String id; // To uniquely identify for editing/deleting
  final List<String> recipients; // Phone numbers or contact IDs
  final List<FilterCondition> conditions;
  final String? selectedSim; // Identifier for the selected SIM (nullable for now)

  Filter({
    required this.id,
    required this.recipients,
    required this.conditions,
    this.selectedSim,
  });
} 