class Session {
  String token;
  int userId;

  Session(this.token, this.userId);

  Session.fromJson(Map<String, dynamic> json)
      : this(json['token'], json['userId']);
}
