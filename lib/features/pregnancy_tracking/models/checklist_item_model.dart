class ChecklistItem {
  final int? id;
  final String pregnancyId;
  final String category;
  final String itemKey;
  final bool isChecked;

  ChecklistItem({
    this.id,
    required this.pregnancyId,
    required this.category,
    required this.itemKey,
    this.isChecked = false,
  });

  ChecklistItem copyWith({
    int? id,
    String? pregnancyId,
    String? category,
    String? itemKey,
    bool? isChecked,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      pregnancyId: pregnancyId ?? this.pregnancyId,
      category: category ?? this.category,
      itemKey: itemKey ?? this.itemKey,
      isChecked: isChecked ?? this.isChecked,
    );
  }
}
