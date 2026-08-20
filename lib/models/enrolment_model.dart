class EnrolmentModel {
  final String id;
  final String userId;
  final String courseId;
  final double progress; // 0.0 to 1.0
  final List<String> completedLessons;
  final String paymentId;
  final DateTime enrolledAt;
  final DateTime? lastAccessedAt;
  final String? lastLessonId;
  final Map<String, int> lastPlayedPositions; // lessonId -> seconds
  final Map<String, String> lessonNotes; // lessonId -> note text

  const EnrolmentModel({
    required this.id,
    required this.userId,
    required this.courseId,
    this.progress = 0.0,
    this.completedLessons = const [],
    this.paymentId = 'free_enrolment',
    required this.enrolledAt,
    this.lastAccessedAt,
    this.lastLessonId,
    this.lastPlayedPositions = const {},
    this.lessonNotes = const {},
  });

  factory EnrolmentModel.fromJson(Map<String, dynamic> json) {
    return EnrolmentModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      courseId: json['courseId'] as String? ?? '',
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      completedLessons: (json['completedLessons'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      paymentId: json['paymentId'] as String? ?? 'free_enrolment',
      enrolledAt: json['enrolledAt'] != null
          ? DateTime.tryParse(json['enrolledAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      lastAccessedAt: json['lastAccessedAt'] != null
          ? DateTime.tryParse(json['lastAccessedAt'].toString())
          : null,
      lastLessonId: json['lastLessonId'] as String?,
      lastPlayedPositions: (json['lastPlayedPositions'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toInt()),
          ) ??
          const {},
      lessonNotes: (json['lessonNotes'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v.toString()),
          ) ??
          const {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'courseId': courseId,
      'progress': progress,
      'completedLessons': completedLessons,
      'paymentId': paymentId,
      'enrolledAt': enrolledAt.toIso8601String(),
      'lastAccessedAt': lastAccessedAt?.toIso8601String(),
      'lastLessonId': lastLessonId,
      'lastPlayedPositions': lastPlayedPositions,
      'lessonNotes': lessonNotes,
    };
  }

  EnrolmentModel copyWith({
    String? id,
    String? userId,
    String? courseId,
    double? progress,
    List<String>? completedLessons,
    String? paymentId,
    DateTime? enrolledAt,
    DateTime? lastAccessedAt,
    String? lastLessonId,
    Map<String, int>? lastPlayedPositions,
    Map<String, String>? lessonNotes,
  }) {
    return EnrolmentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      courseId: courseId ?? this.courseId,
      progress: progress ?? this.progress,
      completedLessons: completedLessons ?? this.completedLessons,
      paymentId: paymentId ?? this.paymentId,
      enrolledAt: enrolledAt ?? this.enrolledAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      lastLessonId: lastLessonId ?? this.lastLessonId,
      lastPlayedPositions: lastPlayedPositions ?? this.lastPlayedPositions,
      lessonNotes: lessonNotes ?? this.lessonNotes,
    );
  }
}
