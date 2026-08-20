import 'user_model.dart';

enum LiveClassStatus {
  scheduled,
  live,
  ended;

  static LiveClassStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'live':
        return LiveClassStatus.live;
      case 'ended':
        return LiveClassStatus.ended;
      case 'scheduled':
      default:
        return LiveClassStatus.scheduled;
    }
  }

  String get value => name;
}

class LiveClassModel {
  final String id;
  final String courseId;
  final String instructorId;
  final String title;
  final String? description;
  final DateTime scheduledAt;
  final int durationMinutes;
  final String jitsiRoomId;
  final LiveClassStatus status;
  final DateTime createdAt;

  const LiveClassModel({
    required this.id,
    required this.courseId,
    required this.instructorId,
    required this.title,
    this.description,
    required this.scheduledAt,
    this.durationMinutes = 60,
    required this.jitsiRoomId,
    this.status = LiveClassStatus.scheduled,
    required this.createdAt,
  });

  bool get isLive => status == LiveClassStatus.live;
  bool get isScheduled => status == LiveClassStatus.scheduled;
  bool get isEnded => status == LiveClassStatus.ended;

  Map<String, dynamic> toJson() => {
        'id': id,
        'courseId': courseId,
        'instructorId': instructorId,
        'title': title,
        if (description != null) 'description': description,
        'scheduledAt': scheduledAt.toIso8601String(),
        'durationMinutes': durationMinutes,
        'jitsiRoomId': jitsiRoomId,
        'status': status.value,
        'createdAt': createdAt.toIso8601String(),
      };

  factory LiveClassModel.fromJson(Map<String, dynamic> json) {
    return LiveClassModel(
      id: json['id'] ?? '',
      courseId: json['courseId'] ?? '',
      instructorId: json['instructorId'] ?? '',
      title: json['title'] ?? 'Live Class',
      description: json['description'],
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.tryParse(json['scheduledAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      durationMinutes: (json['durationMinutes'] is int)
          ? json['durationMinutes']
          : (int.tryParse(json['durationMinutes']?.toString() ?? '60') ?? 60),
      jitsiRoomId: json['jitsiRoomId'] ?? '',
      status: LiveClassStatus.fromString(json['status']),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  LiveClassModel copyWith({
    String? id,
    String? courseId,
    String? instructorId,
    String? title,
    String? description,
    DateTime? scheduledAt,
    int? durationMinutes,
    String? jitsiRoomId,
    LiveClassStatus? status,
    DateTime? createdAt,
  }) {
    return LiveClassModel(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      instructorId: instructorId ?? this.instructorId,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      jitsiRoomId: jitsiRoomId ?? this.jitsiRoomId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class LiveClassParticipantModel {
  final String id;
  final String userId;
  final String name;
  final String? avatar;
  final UserRole role;
  final bool isMicOn;
  final bool isCameraOn;
  final bool isHandRaised;
  final DateTime joinedAt;

  const LiveClassParticipantModel({
    required this.id,
    required this.userId,
    required this.name,
    this.avatar,
    this.role = UserRole.student,
    this.isMicOn = true,
    this.isCameraOn = true,
    this.isHandRaised = false,
    required this.joinedAt,
  });

  bool get isInstructor => role == UserRole.instructor;

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'name': name,
        if (avatar != null) 'avatar': avatar,
        'role': role.name,
        'isMicOn': isMicOn,
        'isCameraOn': isCameraOn,
        'isHandRaised': isHandRaised,
        'joinedAt': joinedAt.toIso8601String(),
      };

  factory LiveClassParticipantModel.fromJson(Map<String, dynamic> json) {
    return LiveClassParticipantModel(
      id: json['id'] ?? json['userId'] ?? '',
      userId: json['userId'] ?? json['id'] ?? '',
      name: json['name'] ?? 'Student',
      avatar: json['avatar'],
      role: json['role'] == 'instructor' ? UserRole.instructor : UserRole.student,
      isMicOn: json['isMicOn'] ?? true,
      isCameraOn: json['isCameraOn'] ?? true,
      isHandRaised: json['isHandRaised'] ?? false,
      joinedAt: json['joinedAt'] != null
          ? DateTime.tryParse(json['joinedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  LiveClassParticipantModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? avatar,
    UserRole? role,
    bool? isMicOn,
    bool? isCameraOn,
    bool? isHandRaised,
    DateTime? joinedAt,
  }) {
    return LiveClassParticipantModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
      isMicOn: isMicOn ?? this.isMicOn,
      isCameraOn: isCameraOn ?? this.isCameraOn,
      isHandRaised: isHandRaised ?? this.isHandRaised,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}

class LiveClassMessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final UserRole senderRole;
  final String message;
  final DateTime sentAt;

  const LiveClassMessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    this.senderRole = UserRole.student,
    required this.message,
    required this.sentAt,
  });

  bool get isInstructor => senderRole == UserRole.instructor;

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderId': senderId,
        'senderName': senderName,
        if (senderAvatar != null) 'senderAvatar': senderAvatar,
        'senderRole': senderRole.name,
        'message': message,
        'sentAt': sentAt.toIso8601String(),
      };

  factory LiveClassMessageModel.fromJson(Map<String, dynamic> json) {
    return LiveClassMessageModel(
      id: json['id'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? 'Participant',
      senderAvatar: json['senderAvatar'],
      senderRole: json['senderRole'] == 'instructor' ? UserRole.instructor : UserRole.student,
      message: json['message'] ?? '',
      sentAt: json['sentAt'] != null
          ? DateTime.tryParse(json['sentAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
