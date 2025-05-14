class User {
  final String id;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final String currency;
  final String theme;

  User({
    required this.id,
    this.email,
    this.displayName,
    this.photoUrl,
    this.currency = 'MYR',
    this.theme = 'light',
  });

  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? currency,
    String? theme,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      currency: currency ?? this.currency,
      theme: theme ?? this.theme,
    );
  }
}
