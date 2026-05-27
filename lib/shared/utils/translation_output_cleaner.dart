class TranslationOutputCleaner {
  const TranslationOutputCleaner._();

  static String clean(String output) {
    final withoutThinkBlocks = output.replaceAll(
      RegExp(r'<think>[\s\S]*?</think>', caseSensitive: false),
      '',
    );

    return withoutThinkBlocks.trim();
  }
}
