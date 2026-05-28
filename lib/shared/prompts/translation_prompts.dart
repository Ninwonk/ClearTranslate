import '../../domain/entities/translation_language.dart';
import '../../domain/entities/translation_mode.dart';
import '../../domain/entities/translation_request.dart';

class TranslationPrompts {
  const TranslationPrompts._();

  static List<Map<String, String>> translate(TranslationRequest request) {
    if (request.mode == TranslationMode.dictionary) {
      return dictionaryExplanation(request.sourceText);
    }

    if (request.isChunked) {
      return longTextChunk(request);
    }

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

  static List<Map<String, String>> longTextChunk(TranslationRequest request) {
    return [
      {
        'role': 'system',
        'content': '你是一个专业中英长文本翻译引擎。只输出当前分段译文，不要解释，不要总结，不要输出思考过程。',
      },
      {
        'role': 'user',
        'content': '''
你正在翻译一篇长文的第 ${request.currentChunk} / ${request.totalChunks} 段。
请将以下内容翻译为${_languageName(request.targetLanguage)}。

要求：
1. 保留段落、标题、列表、编号、代码块和 Markdown 格式。
2. 不要总结，不要省略，不要合并无关段落。
3. 只输出当前分段译文。
4. 翻译自然、准确、符合目标语言表达习惯。
5. 翻译风格：${request.style}
6. 不要输出思考过程、分析说明或 <think> 标签。

当前分段：
${request.sourceText}
''',
      },
    ];
  }

  static List<Map<String, String>> dictionaryExplanation(String content) {
    return [
      {
        'role': 'system',
        'content': '你是一个专业中英双语词典和表达助手。输出结构清晰，适合在词典 App 中展示。不要输出思考过程。',
      },
      {
        'role': 'user',
        'content': '''
请基于用户查询和本地词典结果做 AI 深度解释。

要求：
1. 用中文说明核心含义。
2. 给出常见用法和自然例句。
3. 如果是英文单词，按词性或语境解释。
4. 如果是中文词语，给出多个英文表达并说明差异。
5. 不要编造罕见或不可靠的用法。
6. 只输出解释内容，不要输出 <think> 标签。

$content
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
