class AuthModel {
  final int id;
  final String token;
  final String role;
  final String username;

  AuthModel({required this.id, required this.token, required this.role, required this.username});

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    return AuthModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      token: json['token'] as String,
      role: json['role'] as String,
      username: json['username'] as String? ?? 'User',
    );
  }
}
