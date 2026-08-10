/// Helpers for FILL questions — aligned with backend:
/// - text_question placeholders: {1}, {2}, ... sequential from 1
/// - answers: text_answer + blank_order
/// - student submit payload:
///   { "answer": { "answers": { "1": "hello", "2": "world" } } }
class FillQuestionHelper {
  FillQuestionHelper._();

  static final RegExp placeholderRegex = RegExp(r'\{(\d+)\}');

  /// Ordered unique blank numbers found in [textQuestion].
  static List<int> parseBlankOrders(String? textQuestion) {
    if (textQuestion == null || textQuestion.isEmpty) return const [];
    final found = <int>{};
    for (final m in placeholderRegex.allMatches(textQuestion)) {
      final n = int.tryParse(m.group(1) ?? '');
      if (n != null && n > 0) found.add(n);
    }
    final list = found.toList()..sort();
    return list;
  }

  /// Count of placeholders (not unique) — usually same as unique for valid text.
  static int placeholderCount(String? textQuestion) {
    if (textQuestion == null || textQuestion.isEmpty) return 0;
    return placeholderRegex.allMatches(textQuestion).length;
  }

  /// Backend rule: placeholders must be sequential starting at {1}.
  static String? validatePlaceholders(String? textQuestion) {
    final orders = parseBlankOrders(textQuestion);
    if (orders.isEmpty) {
      return 'Must contain at least one placeholder like {1}.';
    }
    for (var i = 0; i < orders.length; i++) {
      if (orders[i] != i + 1) {
        return 'Placeholders must be sequential starting from {1}.';
      }
    }
    if (placeholderCount(textQuestion) != orders.length) {
      return 'Duplicate placeholders are not allowed.';
    }
    return null;
  }

  /// Teacher-side: number of answer rows should cover every blank_order.
  static String? validateAnswersCoverBlanks({
    required String? textQuestion,
    required List<int> blankOrdersFromAnswers,
  }) {
    final ph = validatePlaceholders(textQuestion);
    if (ph != null) return ph;
    final expected = parseBlankOrders(textQuestion).toSet();
    final provided = blankOrdersFromAnswers.where((e) => e > 0).toSet();
    if (!expected.every(provided.contains)) {
      return 'Every placeholder must have at least one answer (blank_order).';
    }
    if (blankOrdersFromAnswers.any((e) => e < 1)) {
      return 'blank_order must be >= 1.';
    }
    return null;
  }

  /// Student submit body matching SubmitAnswerRequest for FILL.
  static Map<String, dynamic> buildSubmitPayload(Map<int, String> blankInputs) {
    final answers = <String, String>{};
    final keys = blankInputs.keys.toList()..sort();
    for (final k in keys) {
      answers['$k'] = blankInputs[k]?.trim() ?? '';
    }
    return {
      'answer': {'answers': answers},
    };
  }

  /// True when every blank has a non-empty answer.
  static bool isComplete(Map<int, String> blankInputs, List<int> blankOrders) {
    for (final o in blankOrders) {
      final v = blankInputs[o]?.trim() ?? '';
      if (v.isEmpty) return false;
    }
    return blankOrders.isNotEmpty;
  }

  /// Split text into segments for UI: plain text vs blank index.
  /// Example: "Hello {1} world {2}" →
  /// [FillText('Hello '), FillBlank(1), FillText(' world '), FillBlank(2)]
  static List<FillSegment> segments(String? textQuestion) {
    if (textQuestion == null || textQuestion.isEmpty) {
      return const [FillText('')];
    }
    final result = <FillSegment>[];
    var last = 0;
    for (final m in placeholderRegex.allMatches(textQuestion)) {
      if (m.start > last) {
        result.add(FillText(textQuestion.substring(last, m.start)));
      }
      final n = int.tryParse(m.group(1) ?? '') ?? 0;
      result.add(FillBlank(n));
      last = m.end;
    }
    if (last < textQuestion.length) {
      result.add(FillText(textQuestion.substring(last)));
    }
    if (result.isEmpty) result.add(FillText(textQuestion));
    return result;
  }
}

sealed class FillSegment {
  const FillSegment();
}

class FillText extends FillSegment {
  final String text;
  const FillText(this.text);
}

class FillBlank extends FillSegment {
  final int order;
  const FillBlank(this.order);
}
