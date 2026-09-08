class Question {
  const Question({
    required this.text,
    required this.category,
    this.packageId = '',
  });

  final String text;
  final String category;
  final String packageId;
}
