class Task {
  String title;
  bool isDone;
  DateTime dueDate;
  bool isRecurring;

  Task(
    this.title, {
    this.isDone = false,
    DateTime? dueDate,
    this.isRecurring = false,
  }) : dueDate = dueDate ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'title': title,
    'done': isDone,
    'dueDate': dueDate.toIso8601String(),
    'isRecurring': isRecurring,
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    json['title'],
    isDone: json['done'],
    dueDate: DateTime.parse(json['dueDate']),
    isRecurring: json['isRecurring'] ?? false,
  );
}
