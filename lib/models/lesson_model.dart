class LessonResource {
  final String title;
  final String url;
  final String type;
  final String? cloudinaryPublicId;
  final bool isPreview;

  const LessonResource({
    required this.title,
    this.url = '',
    this.type = 'pdf',
    this.cloudinaryPublicId,
    this.isPreview = false,
  });

  factory LessonResource.fromJson(Map<String, dynamic> json) {
    return LessonResource(
      title: json['title'] as String? ?? '',
      url: json['url'] as String? ?? '',
      type: json['type'] as String? ?? 'pdf',
      cloudinaryPublicId: json['cloudinaryPublicId'] as String?,
      isPreview: json['isPreview'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
      'type': type,
      'cloudinaryPublicId': cloudinaryPublicId,
      'isPreview': isPreview,
    };
  }
}

class LessonModel {
  final String id;
  final String courseId;
  final String title;
  final String videoUrl;
  final String? cloudinaryPublicId;
  final String duration;
  final int order;
  final bool isPreview;
  final List<LessonResource> resources;

  const LessonModel({
    required this.id,
    required this.courseId,
    required this.title,
    this.videoUrl = '',
    this.cloudinaryPublicId,
    this.duration = '10:00',
    required this.order,
    this.isPreview = false,
    this.resources = const [],
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      id: json['id'] as String? ?? '',
      courseId: json['courseId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      videoUrl: json['videoUrl'] as String? ?? '',
      cloudinaryPublicId: json['cloudinaryPublicId'] as String?,
      duration: json['duration'] as String? ?? '10:00',
      order: (json['order'] as num?)?.toInt() ?? 1,
      isPreview: json['isPreview'] as bool? ?? false,
      resources: (json['resources'] as List<dynamic>?)
              ?.map((e) => LessonResource.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'title': title,
      'videoUrl': videoUrl,
      'cloudinaryPublicId': cloudinaryPublicId,
      'duration': duration,
      'order': order,
      'isPreview': isPreview,
      'resources': resources.map((e) => e.toJson()).toList(),
    };
  }
}

class ModuleModel {
  final String id;
  final String title;
  final String description;
  final List<LessonModel> lessons;

  const ModuleModel({
    required this.id,
    required this.title,
    this.description = '',
    this.lessons = const [],
  });

  factory ModuleModel.fromJson(Map<String, dynamic> json) {
    return ModuleModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      lessons: (json['lessons'] as List<dynamic>?)
              ?.map((e) => LessonModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'lessons': lessons.map((e) => e.toJson()).toList(),
    };
  }
}
