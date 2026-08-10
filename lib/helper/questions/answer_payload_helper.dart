/// Builds student submit bodies matching backend SubmitAnswerRequest.
///
/// PAIR (critical):
/// Backend PairScorer:
///   foreach ($submittedPairs as $leftId => $rightId)
///     if ((int)$leftId === (int)$rightId) correct++
/// Body MUST be a JSON object map, NOT a list:
///   { "answer": { "pairs": { "5": 5, "6": 6 } } }
class AnswerPayloadHelper {
  AnswerPayloadHelper._();

  static Map<String, dynamic> mcq({required int selectedAnswerId}) {
    return {
      'answer': {'selected_answer_id': selectedAnswerId},
    };
  }

  static Map<String, dynamic> fill({required Map<int, String> blankInputs}) {
    final answers = <String, String>{};
    for (final e in blankInputs.entries) {
      answers['${e.key}'] = e.value.trim();
    }
    return {
      'answer': {'answers': answers},
    };
  }

  static Map<String, dynamic> arrange({required List<int> orderedIds}) {
    return {
      'answer': {'ordered_ids': orderedIds},
    };
  }

  /// [matches] = left pair_answer id → right pair_answer id.
  /// Correct when leftId == rightId (same row).
  static Map<String, dynamic> pair({required Map<int, int> matches}) {
    final pairs = <String, int>{};
    for (final e in matches.entries) {
      pairs['${e.key}'] = e.value;
    }
    return {
      'answer': {'pairs': pairs},
    };
  }
}
