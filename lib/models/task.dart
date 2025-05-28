class Task {
  String title;
  bool isDone;
  DateTime dueDate;

  Task(this.title, {this.isDone = false, DateTime? dueDate})
      : dueDate = dueDate ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'title': title,
        'done': isDone,
        'dueDate': dueDate.toIso8601String(),
      };

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      json['title'],
      isDone: json['done'],
      dueDate: DateTime.parse(json['dueDate']),
    );
  }
}
