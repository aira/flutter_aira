// ignore_for_file: constant_identifier_names

enum Language {
  English,
  French,
  Spanish,
}

extension LanguageExtension on Language {
  get name => toString().split('.').last;
}