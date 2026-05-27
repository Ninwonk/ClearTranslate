import '../../domain/entities/translation_language.dart';
import '../../domain/entities/translation_request.dart';

class TranslationPrompts {
  const TranslationPrompts._();

  static List<Map<String, String>> translate(TranslationRequest request) {
    return [
      {
        'role': 'system',
        'content': '你是一个专业中英翻译引擎。只输出最终译文，不要解释，不要输出思考过程，不要输出 <think> 标签。',
      },
      {
        'role': 'user',
        'content': '''
请将用户输入翻译为${_languageName(request.targetLanguage)}。

要求：
1. 保留原文段落结构。
2. 保留 Markdown、列表、编号、代码块。
3. 不要添加解释。
4. 翻译自然、准确、符合目标语言表达习惯。
5. 如果原文有明显错别字，可在不改变意思的前提下自然修正。
6. 翻译风格：${request.style}
7. 不要输出思考过程、分析说明或 <think> 标签。

用户输入：
${request.sourceText}
''',
      },
    ];
  }

  static String _languageName(TranslationLanguage language) {
    return switch (language) {
      TranslationLanguage.auto => '自动识别的目标语言',
      TranslationLanguage.zh => '中文',
      TranslationLanguage.en => 'English',
    };
  }
}
