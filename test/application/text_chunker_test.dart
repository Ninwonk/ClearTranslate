import 'package:clear_translate/application/translate/text_chunker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps short text as one chunk', () {
    final chunks = TextChunker.split('hello world', 3000);

    expect(chunks, ['hello world']);
  });

  test('packs paragraphs without exceeding configured limit where possible',
      () {
    final text =
        '${'first paragraph. ' * 12}\n\n${'second paragraph. ' * 12}\n\n${'third paragraph. ' * 12}'
            .trim();
    final chunks = TextChunker.split(
      text,
      200,
    );

    expect(chunks.length, greaterThan(1));
    final merged = chunks.join('\n\n');
    expect(RegExp('first paragraph\\.').allMatches(merged), hasLength(12));
    expect(RegExp('second paragraph\\.').allMatches(merged), hasLength(12));
    expect(RegExp('third paragraph\\.').allMatches(merged), hasLength(12));
  });

  test('splits long paragraph by punctuation', () {
    final text = '${'a' * 120}. ${'b' * 120}. ${'c' * 120}.';
    final chunks = TextChunker.split(text, 200);

    expect(chunks.length, greaterThan(1));
    expect(chunks.first.endsWith('.'), isTrue);
  });
}
