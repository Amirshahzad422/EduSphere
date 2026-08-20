enum UserRole { student, instructor, admin }

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? photoUrl;
  final String? bio;
  final int xp;
  final int streak;
  final List<String> badges;
  final DateTime? lastActiveDate;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.role = UserRole.student,
    this.photoUrl,
    this.bio,
    this.xp = 0,
    this.streak = 0,
    this.badges = const [],
    this.lastActiveDate,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: _parseRole(json['role'] as String?),
      photoUrl: json['photoUrl'] as String?,
      bio: json['bio'] as String?,
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      streak: (json['streak'] as num?)?.toInt() ?? 0,
      badges: (json['badges'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      lastActiveDate: json['lastActiveDate'] != null
          ? DateTime.tryParse(json['lastActiveDate'].toString())
          : null,
    );
  }

  static UserRole _parseRole(String? roleStr) {
    switch (roleStr?.toLowerCase()) {
      case 'instructor':
        return UserRole.instructor;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.student;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'photoUrl': photoUrl,
      'bio': bio,
      'xp': xp,
      'streak': streak,
      'badges': badges,
      if (lastActiveDate != null) 'lastActiveDate': lastActiveDate!.toIso8601String(),
    };
  }

  Map<String, dynamic> toPublicProfileJson() {
    return {
      'id': id,
      'name': name,
      'photoUrl': photoUrl,
      'bio': bio,
      'xp': xp,
      'streak': streak,
      'badges': badges,
      'role': role.name,
      if (lastActiveDate != null) 'lastActiveDate': lastActiveDate!.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? photoUrl,
    String? bio,
    int? xp,
    int? streak,
    List<String>? badges,
    DateTime? lastActiveDate,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      xp: xp ?? this.xp,
      streak: streak ?? this.streak,
      badges: badges ?? this.badges,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
    );
  }
}
