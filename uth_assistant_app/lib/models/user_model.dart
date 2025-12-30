class UserModel {
  final String id;
  final String username;
  final String email;
  final String? avatarUrl;
  final String? realname;
  final bool isProfileCompleted;
  final String? bio;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.avatarUrl,
    this.realname,
    this.isProfileCompleted = false,
    this.bio,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatarUrl'],
      realname: json['realname'],
      isProfileCompleted: json['isProfileCompleted'] ?? false,
      bio: json['bio'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'email': email,
      'avatarUrl': avatarUrl,
      'realname': realname,
      'isProfileCompleted': isProfileCompleted,
      'bio': bio,
    };
  }

  // Copy with method for updating fields
  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? avatarUrl,
    String? realname,
    bool? isProfileCompleted,
    String? bio,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      realname: realname ?? this.realname,
      isProfileCompleted: isProfileCompleted ?? this.isProfileCompleted,
      bio: bio ?? this.bio,
    );
  }
}
