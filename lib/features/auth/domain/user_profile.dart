import 'dart:convert';

class UserProfile {
  final String id;
  final String role; // 'admin' or 'student'
  final String name;
  final String username;
  final String? classBatch;
  final bool active;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.role,
    required this.name,
    required this.username,
    this.classBatch,
    this.active = true,
    required this.createdAt,
  });

  bool get isAdmin => role == 'admin';
  bool get isStudent => role == 'student';

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      role: (map['role'] as String?)?.toLowerCase() ?? 'student',
      name: map['name'] as String? ?? 'User',
      username: map['username'] as String? ?? '',
      classBatch: map['class_batch'] as String?,
      active: map['active'] as bool? ?? true,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'role': role,
      'name': name,
      'username': username,
      'class_batch': classBatch,
      'active': active,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String toJson() => jsonEncode(toMap());

  factory UserProfile.fromJson(String source) =>
      UserProfile.fromMap(jsonDecode(source) as Map<String, dynamic>);

  UserProfile copyWith({
    String? id,
    String? role,
    String? name,
    String? username,
    String? classBatch,
    bool? active,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      role: role ?? this.role,
      name: name ?? this.name,
      username: username ?? this.username,
      classBatch: classBatch ?? this.classBatch,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
