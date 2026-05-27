enum TranslationLanguage {
  auto('Auto Detect'),
  zh('中文'),
  en('English');

  const TranslationLanguage(this.label);

  final String label;

  static TranslationLanguage detect(String text) {
    final hasChinese = RegExp(r'[\u4e00-\u9fff]').hasMatch(text);
    return hasChinese ? TranslationLanguage.zh : TranslationLanguage.en;
  }
}

