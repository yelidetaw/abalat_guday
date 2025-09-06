class PlanItem {
  final String id;
  final String title;
  final String? description;
  final DateTime? planDate;
  final String? assignee;
  final String? teamName;
  final bool isDone;

  PlanItem({
    required this.id,
    required this.title,
    this.description,
    this.planDate,
    this.assignee,
    this.teamName,
    this.isDone = false,
  });

  // Add this copyWith method
  PlanItem copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? planDate,
    String? assignee,
    String? teamName,
    bool? isDone,
  }) {
    return PlanItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      planDate: planDate ?? this.planDate,
      assignee: assignee ?? this.assignee,
      teamName: teamName ?? this.teamName,
      isDone: isDone ?? this.isDone,
    );
  }
}
