enum LanguagePreference {
  korean('kor'),
  english('en');

  const LanguagePreference(this.id);

  final String id;

  static LanguagePreference parse(String id) {
    for (final LanguagePreference language in values) {
      if (language.id == id) {
        return language;
      }
    }
    throw FormatException('Unsupported language preference: $id');
  }
}
