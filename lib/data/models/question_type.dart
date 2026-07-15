// lib/data/models/question_type.dart

enum QuestionType {
  mcq('MCQ', 'Multiple Choice'),
  fill('FILL', 'Fill in the Blank'),
  arrange('ARRANGE', 'Arrange Words'),
  pair('PAIR', 'Match Pairs');

  final String value;
  final String displayName;
  const QuestionType(this.value, this.displayName);

  static QuestionType fromString(String? value) {
    if (value == null) return QuestionType.mcq;
    return QuestionType.values.firstWhere(
      (t) => t.value == value,
      orElse: () => QuestionType.mcq,
    );
  }
}

enum QuestionDifficulty {
  easy('EASY', 'Easy', 1, 2),
  medium('MEDIUM', 'Medium', 3, 5),
  hard('HARD', 'Hard', 6, 10);

  final String value;
  final String displayName;
  final int minScore;
  final int maxScore;
  const QuestionDifficulty(this.value, this.displayName, this.minScore, this.maxScore);

  static QuestionDifficulty fromString(String? value) {
    if (value == null) return QuestionDifficulty.easy;
    return QuestionDifficulty.values.firstWhere(
      (d) => d.value == value,
      orElse: () => QuestionDifficulty.easy,
    );
  }
}