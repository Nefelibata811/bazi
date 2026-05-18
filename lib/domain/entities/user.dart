class User {
  const User({
    required this.id,
    required this.email,
    required this.createdAt,
    this.nickname,
    this.avatarUrl,
    this.phone,
  });

  final String id;
  final String email;
  final DateTime createdAt;
  final String? nickname;
  final String? avatarUrl;
  /// E.164, e.g. +8613812345678
  final String? phone;

  User copyWith({
    String? nickname,
    String? avatarUrl,
    String? phone,
  }) {
    return User(
      id: id,
      email: email,
      createdAt: createdAt,
      nickname: nickname ?? this.nickname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
    );
  }
}
