/// Backend quiz item from StudentWordService::quizWords / buildQuestion:
/// {
///   "Quiz": {
///     "word_id": 10,
///     "question": "hello",
///     "audio": "https://...",
///     "options": [ { "id": 10, "text": "hello" }, ... ]
///   }
/// }
class WordQuizOption {
  final int id;
  final String text;

  const WordQuizOption({required this.id, required this.text});

  factory WordQuizOption.fromJson(Map<String, dynamic> json) {
    return WordQuizOption(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      text: json['text']?.toString() ?? '',
    );
  }
}

class WordQuizQuestion {
  final int wordId;
  final String question;
  final String? audio;
  final List<WordQuizOption> options;

  const WordQuizQuestion({
    required this.wordId,
    required this.question,
    this.audio,
    required this.options,
  });

  factory WordQuizQuestion.fromJson(Map<String, dynamic> json) {
    // Backend wraps each item under "Quiz"
    final raw = json['Quiz'] is Map
        ? Map<String, dynamic>.from(json['Quiz'] as Map)
        : json;

    final optionsRaw = raw['options'];
    final options = <WordQuizOption>[];
    if (optionsRaw is List) {
      for (final o in optionsRaw) {
        if (o is Map) {
          options.add(WordQuizOption.fromJson(Map<String, dynamic>.from(o)));
        }
      }
    }

    final audioRaw = raw['audio']?.toString();
    return WordQuizQuestion(
      wordId: raw['word_id'] is int
          ? raw['word_id'] as int
          : int.tryParse(raw['word_id']?.toString() ?? '0') ?? 0,
      question: raw['question']?.toString() ?? '',
      audio: (audioRaw != null && audioRaw.trim().isNotEmpty) ? audioRaw : null,
      options: options,
    );
  }

  bool get hasAudio => audio != null && audio!.trim().isNotEmpty;
}

/// Backend checkAnswer response:
/// { "correct": bool, "message": "...", "correct_answer_id": int? }
class WordQuizCheckResult {
  final bool correct;
  final String message;
  final int? correctAnswerId;

  const WordQuizCheckResult({
    required this.correct,
    required this.message,
    this.correctAnswerId,
  });

  factory WordQuizCheckResult.fromJson(Map<String, dynamic> json) {
    final rawId = json['correct_answer_id'];
    int? correctId;
    if (rawId != null) {
      correctId = rawId is int ? rawId : int.tryParse(rawId.toString());
    }
    return WordQuizCheckResult(
      correct: json['correct'] == true,
      message:
          json['message']?.toString() ??
          (json['correct'] == true
              ? 'Answer is correct'
              : 'Answer is incorrect'),
      correctAnswerId: correctId,
    );
  }
}
