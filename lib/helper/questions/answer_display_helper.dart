import 'package:fluent/data/models/question_model.dart';

/// Human-readable answer formatting for student feedback / review.
/// Maps MCQ/ARRANGE/PAIR ids → text_answer (or left/right for pairs).
class AnswerDisplayHelper {
  AnswerDisplayHelper._();

  static String format({required dynamic answer, Question? question}) {
    if (answer == null) return '—';
    if (answer is String) return answer.trim().isEmpty ? '—' : answer;

    if (answer is! Map) return answer.toString();
    final map = Map<String, dynamic>.from(answer);

    // MCQ
    if (map.containsKey('selected_answer_id')) {
      final id = _asInt(map['selected_answer_id']);
      final label = _mcqLabel(question, id);
      return label ?? (id != null ? 'Option #$id' : '—');
    }

    // FILL: { "answers": { "1": "text", "2": "text" } }
    // or correct shape: { "answers": { "1": ["a","b"], ... } }
    if (map.containsKey('answers')) {
      final a = map['answers'];
      if (a is Map) {
        final keys = a.keys.map((k) => k.toString()).toList()
          ..sort(
            (x, y) => (int.tryParse(x) ?? 0).compareTo(int.tryParse(y) ?? 0),
          );
        return keys
            .map((k) {
              final v = a[k] ?? a[int.tryParse(k)];
              if (v is List) {
                return '{$k}: ${v.map((e) => e.toString()).join(' / ')}';
              }
              return '{$k}: ${v?.toString() ?? '—'}';
            })
            .join('  ·  ');
      }
    }

    // ARRANGE: ordered_ids → words in order
    if (map.containsKey('ordered_ids')) {
      final raw = map['ordered_ids'];
      if (raw is List) {
        final ids = raw.map(_asInt).whereType<int>().toList();
        if (ids.isEmpty) return '—';
        final words = ids.map((id) {
          final t = _answerText(question, id);
          return t ?? '#$id';
        }).toList();
        // Prefer words; if all fell back to #id only, still join
        return words.join(' → ');
      }
    }

    // PAIR: pairs map leftId → rightId
    if (map.containsKey('pairs')) {
      final p = map['pairs'];
      if (p is Map) {
        final parts = <String>[];
        p.forEach((left, right) {
          final lid = _asInt(left);
          final rid = _asInt(right);
          final leftLabel =
              _pairLeft(question, lid) ?? (lid != null ? '#$lid' : '?');
          final rightLabel =
              _pairRight(question, rid) ?? (rid != null ? '#$rid' : '?');
          parts.add('$leftLabel ↔ $rightLabel');
        });
        return parts.isEmpty ? '—' : parts.join('  ·  ');
      }
    }

    return map.toString();
  }

  static String? _mcqLabel(Question? q, int? id) {
    if (q == null || id == null) return null;
    for (final a in q.answers) {
      if (a.id == id) {
        final t = (a.textAnswer ?? '').trim();
        return t.isEmpty ? null : t;
      }
    }
    return null;
  }

  static String? _answerText(Question? q, int id) {
    if (q == null) return null;
    for (final a in q.answers) {
      if (a.id == id) {
        final t = (a.textAnswer ?? '').trim();
        if (t.isNotEmpty) return t;
        // pair rows sometimes only have left/right
        final l = (a.leftText ?? '').trim();
        final r = (a.rightText ?? '').trim();
        if (l.isNotEmpty || r.isNotEmpty) return '$l / $r';
      }
    }
    return null;
  }

  static String? _pairLeft(Question? q, int? id) {
    if (q == null || id == null) return null;
    for (final a in q.answers) {
      if (a.id == id) {
        final t = (a.leftText ?? a.textAnswer ?? '').trim();
        return t.isEmpty ? null : t;
      }
    }
    return null;
  }

  static String? _pairRight(Question? q, int? id) {
    if (q == null || id == null) return null;
    for (final a in q.answers) {
      if (a.id == id) {
        final t = (a.rightText ?? a.textAnswer ?? '').trim();
        return t.isEmpty ? null : t;
      }
    }
    return null;
  }

  static int? _asInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '');
  }
}
