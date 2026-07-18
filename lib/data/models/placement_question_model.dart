import 'package:flutter/material.dart';

enum PlacementQuestionType {
  vocabulary, 
  grammar, 
  reading, 
}

enum PlacementDifficulty {
  beginner, // A1
  elementary, // A2
  preIntermediate, // B1
  intermediate, // B2
  upperIntermediate, // C1
  advanced, // C2
}

class PlacementQuestion {
  final String id;
  final PlacementQuestionType type;
  final PlacementDifficulty difficulty;
  final String question;
  final String? passage; 
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const PlacementQuestion({
    required this.id,
    required this.type,
    required this.difficulty,
    required this.question,
    this.passage,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  static ({String title, String code, Color color}) getLevelInfo(
    PlacementDifficulty d,
  ) {
    switch (d) {
      case PlacementDifficulty.beginner:
        return (title: 'Beginner', code: 'A1', color: const Color(0xffFFD35B));
      case PlacementDifficulty.elementary:
        return (
          title: 'Elementary',
          code: 'A2',
          color: const Color(0xffF5A201),
        );
      case PlacementDifficulty.preIntermediate:
        return (
          title: 'Pre-Intermediate',
          code: 'B1',
          color: const Color(0xffA8E8F9),
        );
      case PlacementDifficulty.intermediate:
        return (
          title: 'Intermediate',
          code: 'B2',
          color: const Color(0xff7C4DFF),
        );
      case PlacementDifficulty.upperIntermediate:
        return (
          title: 'Upper-Intermediate',
          code: 'C1',
          color: const Color(0xffFF6B6B),
        );
      case PlacementDifficulty.advanced:
        return (title: 'Advanced', code: 'C2', color: const Color(0xff00E5FF));
    }
  }
}

const List<PlacementQuestion> kPlacementQuestions = [
  PlacementQuestion(
    id: 'q1',
    type: PlacementQuestionType.vocabulary,
    difficulty: PlacementDifficulty.beginner,
    question: 'What is the English word for "كتاب"؟',
    options: ['Book', 'Pen', 'Bag', 'Chair'],
    correctIndex: 0,
    explanation: 'Book = كتاب 📚',
  ),
  PlacementQuestion(
    id: 'q2',
    type: PlacementQuestionType.grammar,
    difficulty: PlacementDifficulty.beginner,
    question: 'Choose the correct sentence:',
    options: [
      'She are happy.',
      'She is happy.',
      'She am happy.',
      'She be happy.',
    ],
    correctIndex: 1,
    explanation: 'مع she/he/it نستخدم "is"',
  ),

  PlacementQuestion(
    id: 'q3',
    type: PlacementQuestionType.vocabulary,
    difficulty: PlacementDifficulty.elementary,
    question: 'Which word means "سعيد"؟',
    options: ['Angry', 'Tired', 'Happy', 'Hungry'],
    correctIndex: 2,
    explanation: 'Happy = سعيد 😊',
  ),
  PlacementQuestion(
    id: 'q4',
    type: PlacementQuestionType.grammar,
    difficulty: PlacementDifficulty.elementary,
    question: 'I ___ to school every day.',
    options: ['go', 'goes', 'going', 'went'],
    correctIndex: 0,
    explanation: 'مع I/you/we/they نستخدم الفعل في المصدر (go)',
  ),

  PlacementQuestion(
    id: 'q5',
    type: PlacementQuestionType.grammar,
    difficulty: PlacementDifficulty.preIntermediate,
    question: 'If it rains tomorrow, we ___ at home.',
    options: ['stay', 'will stay', 'stayed', 'would stay'],
    correctIndex: 1,
    explanation: 'في الجمل الشرطية من النوع الأول: If + present, will + verb',
  ),
  PlacementQuestion(
    id: 'q6',
    type: PlacementQuestionType.vocabulary,
    difficulty: PlacementDifficulty.preIntermediate,
    question: 'What does "to accomplish" mean?',
    options: ['To fail', 'To achieve', 'To start', 'To forget'],
    correctIndex: 1,
    explanation: 'To accomplish = تحقيق / إنجاز ✅',
  ),

  PlacementQuestion(
    id: 'q7',
    type: PlacementQuestionType.reading,
    difficulty: PlacementDifficulty.intermediate,
    passage:
        'Sarah has been working at the company for five years. She started as a junior developer and is now the team lead.',
    question: 'What is Sarah\'s current position?',
    options: ['Junior Developer', 'Project Manager', 'Team Lead', 'CEO'],
    correctIndex: 2,
    explanation: 'النص يقول "she is now the team lead"',
  ),
  PlacementQuestion(
    id: 'q8',
    type: PlacementQuestionType.grammar,
    difficulty: PlacementDifficulty.intermediate,
    question: 'By the time you arrive, I ___ dinner.',
    options: ['will finish', 'will have finished', 'have finished', 'finished'],
    correctIndex: 1,
    explanation:
        'Future Perfect: will have + past participle (لحدث يكتمل قبل آخر في المستقبل)',
  ),

  PlacementQuestion(
    id: 'q9',
    type: PlacementQuestionType.vocabulary,
    difficulty: PlacementDifficulty.upperIntermediate,
    question: 'Choose the closest synonym to "meticulous":',
    options: ['Careless', 'Thorough', 'Quick', 'Lazy'],
    correctIndex: 1,
    explanation: 'Meticulous = دقيق / متقن (شبيه بـ Thorough)',
  ),
  PlacementQuestion(
    id: 'q10',
    type: PlacementQuestionType.grammar,
    difficulty: PlacementDifficulty.upperIntermediate,
    question: 'I wish I ___ harder when I was younger.',
    options: ['studied', 'had studied', 'would study', 'have studied'],
    correctIndex: 1,
    explanation: 'I wish + past perfect (للتعبير عن ندم على الماضي)',
  ),

  PlacementQuestion(
    id: 'q11',
    type: PlacementQuestionType.reading,
    difficulty: PlacementDifficulty.advanced,
    passage:
        'Despite the ostensibly altruistic motives behind the policy, critics argue that its implementation has been marred by systemic inefficiencies and a glaring lack of transparency.',
    question: 'The word "ostensibly" most nearly means:',
    options: ['Clearly', 'Supposedly', 'Honestly', 'Obviously'],
    correctIndex: 1,
    explanation: 'Ostensibly = ظاهرياً / على ما يبدو (Supposedly)',
  ),
  PlacementQuestion(
    id: 'q12',
    type: PlacementQuestionType.grammar,
    difficulty: PlacementDifficulty.advanced,
    question: 'Hardly ___ the office when the meeting started.',
    options: ['I had entered', 'had I entered', 'I entered', 'did I entered'],
    correctIndex: 1,
    explanation:
        'Inversion after negative adverbials: Hardly had I + past participle',
  ),
];
