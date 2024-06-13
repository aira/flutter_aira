class Session {
  String token;
  int userId;
  String? login;
  String? authProvider;
  String? email;
  String? phone;
  String firebaseCustomToken;

  Session({
    required this.token,
    required this.userId,
    required this.firebaseCustomToken,
    this.authProvider,
    this.login,
    this.email,
    this.phone,
  });

  Session.fromJson(Map<String, dynamic> json)
      : token = json['token'],
        userId = json['userId'],
        login = json['login'],
        email = json['email'],
        phone = json['phone'],
        authProvider = json['authProvider'],
        firebaseCustomToken = json['firebaseCustomToken'];
}
