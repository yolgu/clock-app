enum CompletionGroup {
  incomplete(isCompleted: false),
  completed(isCompleted: true);

  const CompletionGroup({required this.isCompleted});

  final bool isCompleted;

  int get sortOrder => switch (this) {
    CompletionGroup.incomplete => 0,
    CompletionGroup.completed => 1,
  };

  factory CompletionGroup.fromCompleted(bool completed) {
    return completed ? CompletionGroup.completed : CompletionGroup.incomplete;
  }
}
