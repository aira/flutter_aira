class FeedbackForm {
  FeedbackForm({
    this.rateAgent,
    this.rateApp,
    this.rateAi,
  });

  final Map? rateAgent;
  final Map? rateApp;
  final Map? rateAi;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['rateAgent'] = rateAgent;
    data['rateApp'] = rateApp;
    data['rateAi'] = rateAi;
    return data;
  }

  factory FeedbackForm.fromJson(Map? map) {
    return FeedbackForm(
      rateAgent: map?['rateAgent'],
      rateApp: map?['rateApp'],
      rateAi: map?['rateAi'],
    );
  }
}
