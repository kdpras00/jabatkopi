class AuthModel {
  final String token;
  final String role;

  AuthModel({required this.token, required this.role});

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    return AuthModel(
      token: json['token'] as String,
      role: json['role'] as String,
    );
  }
}
