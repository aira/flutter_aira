class Session {
  String token;
  int userId;
  String? uuid;
  String? login;
  String? authProvider;
  String? email;
  String? phone;
  bool isAnonymous;
  String firebaseCustomToken;

  Session({
    required this.token,
    required this.userId,
    required this.firebaseCustomToken,
    this.authProvider,
    this.login,
    this.email,
    this.phone,
    this.isAnonymous = false,
    this.uuid,
  });

  Session.fromJson(Map<String, dynamic> json)
      : token = json['token'],
        userId = json['userId'],
        login = json['login'],
        email = json['email'],
        phone = json['phone'],
        authProvider = json['authProvider'],
        firebaseCustomToken = json['firebaseCustomToken'],
        isAnonymous = json['isAnonymous'] ?? false,
        uuid = json['uuid'];

  Session.anonymous({
    required this.uuid,
    required this.firebaseCustomToken,
  })  : token = '',
        userId = 0,
        email = '',
        isAnonymous = true;
}
