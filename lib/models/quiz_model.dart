enum QuestionType {
  multipleChoice,
  trueFalse,
  shortAnswer;

  static QuestionType fromString(String? type) {
    switch (type?.toLowerCase()) {
      case 'truefalse':
      case 'true_false':
        return QuestionType.trueFalse;
      case 'shortanswer':
      case 'short_answer':
        return QuestionType.shortAnswer;
      default:
        return QuestionType.multipleChoice;
    }
  }
}

class QuizOption {
  final String id;
  final String text;
  final bool isCorrect;

  const QuizOption({
    required this.id,
    required this.text,
    required this.isCorrect,
  });

  QuizOption copyWith({
    String? id,
    String? text,
    bool? isCorrect,
  }) {
    return QuizOption(
      id: id ?? this.id,
      text: text ?? this.text,
      isCorrect: isCorrect ?? this.isCorrect,
    );
  }

  factory QuizOption.fromJson(Map<String, dynamic> json) {
    return QuizOption(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      isCorrect: json['isCorrect'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isCorrect': isCorrect,
    };
  }
}

class QuizQuestion {
  final String id;
  final String question;
  final String explanation;
  final QuestionType type;
  final String sampleAnswer;
  final List<QuizOption> options;

  const QuizQuestion({
    required this.id,
    required this.question,
    this.explanation = '',
    this.type = QuestionType.multipleChoice,
    this.sampleAnswer = '',
    required this.options,
  });

  QuizQuestion copyWith({
    String? id,
    String? question,
    String? explanation,
    QuestionType? type,
    String? sampleAnswer,
    List<QuizOption>? options,
  }) {
    return QuizQuestion(
      id: id ?? this.id,
      question: question ?? this.question,
      explanation: explanation ?? this.explanation,
      type: type ?? this.type,
      sampleAnswer: sampleAnswer ?? this.sampleAnswer,
      options: options ?? this.options,
    );
  }

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'] as String? ?? '',
      question: json['question'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
      type: QuestionType.fromString(json['type'] as String?),
      sampleAnswer: json['sampleAnswer'] as String? ?? '',
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => QuizOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'explanation': explanation,
      'type': type.name,
      'sampleAnswer': sampleAnswer,
      'options': options.map((e) => e.toJson()).toList(),
    };
  }
}

class QuizModel {
  final String id;
  final String courseId;
  final String? lessonId;
  final String title;
  final String description;
  final int passingScore;
  final int timeLimitMinutes;
  final List<QuizQuestion> questions;

  const QuizModel({
    required this.id,
    required this.courseId,
    this.lessonId,
    required this.title,
    this.description = '',
    this.passingScore = 80,
    this.timeLimitMinutes = 15,
    required this.questions,
  });

  QuizModel copyWith({
    String? id,
    String? courseId,
    String? lessonId,
    String? title,
    String? description,
    int? passingScore,
    int? timeLimitMinutes,
    List<QuizQuestion>? questions,
  }) {
    return QuizModel(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      lessonId: lessonId ?? this.lessonId,
      title: title ?? this.title,
      description: description ?? this.description,
      passingScore: passingScore ?? this.passingScore,
      timeLimitMinutes: timeLimitMinutes ?? this.timeLimitMinutes,
      questions: questions ?? this.questions,
    );
  }

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    return QuizModel(
      id: json['id'] as String? ?? '',
      courseId: json['courseId'] as String? ?? '',
      lessonId: json['lessonId'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      passingScore: (json['passingScore'] as num?)?.toInt() ?? 80,
      timeLimitMinutes: (json['timeLimitMinutes'] as num?)?.toInt() ?? 15,
      questions: (json['questions'] as List<dynamic>?)
              ?.map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'lessonId': lessonId,
      'title': title,
      'description': description,
      'passingScore': passingScore,
      'timeLimitMinutes': timeLimitMinutes,
      'questions': questions.map((e) => e.toJson()).toList(),
    };
  }
}

class QuizAttemptModel {
  final String id;
  final String userId;
  final String quizId;
  final String? courseId;
  final int score;
  final bool passed;
  final int shortAnswerCount;
  final Map<String, String> answers;
  final DateTime completedAt;

  const QuizAttemptModel({
    required this.id,
    required this.userId,
    required this.quizId,
    this.courseId,
    required this.score,
    required this.passed,
    this.shortAnswerCount = 0,
    required this.answers,
    required this.completedAt,
  });

  factory QuizAttemptModel.fromJson(Map<String, dynamic> json) {
    return QuizAttemptModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      quizId: json['quizId'] as String? ?? '',
      courseId: json['courseId'] as String?,
      score: (json['score'] as num?)?.toInt() ?? 0,
      passed: json['passed'] as bool? ?? false,
      shortAnswerCount: (json['shortAnswerCount'] as num?)?.toInt() ?? 0,
      answers: (json['answers'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v.toString()),
          ) ??
          const {},
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'quizId': quizId,
      'courseId': courseId,
      'score': score,
      'passed': passed,
      'shortAnswerCount': shortAnswerCount,
      'answers': answers,
      'completedAt': completedAt.toIso8601String(),
    };
  }
}
