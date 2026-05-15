class User {
  const User({
    required this.id,
    required this.email,
    required this.createdAt,
    this.nickname,
    this.avatarUrl,
  });

  final String id;
  final String email;
  final DateTime createdAt;
  final String? nickname;
  final String? avatarUrl;

  User copyWith({
    String? nickname,
    String? avatarUrl,
  }) {
    return User(
      id: id,
      email: email,
      createdAt: createdAt,
      nickname: nickname ?? this.nickname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
