import 'package:clear_translate/shared/utils/translation_output_cleaner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('removes MiniMax think blocks from translation output', () {
    const output = '''
<think>
用户要求将英文翻译成中文。
</think>

你好
''';

    expect(TranslationOutputCleaner.clean(output), '你好');
  });

  test('keeps normal translation output unchanged except surrounding spaces',
      () {
    expect(TranslationOutputCleaner.clean('  Hello world  '), 'Hello world');
  });
}
