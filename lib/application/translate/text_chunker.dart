class TextChunker {
  const TextChunker._();

  static List<String> split(String text, int maxChunkLength) {
    final normalizedLimit = maxChunkLength < 200 ? 200 : maxChunkLength;
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return const [];
    }
    if (trimmed.length <= normalizedLimit) {
      return [trimmed];
    }

    final paragraphs = _paragraphs(trimmed);
    final chunks = <String>[];
    final buffer = StringBuffer();

    void flush() {
      final value = buffer.toString().trim();
      if (value.isNotEmpty) {
        chunks.add(value);
      }
      buffer.clear();
    }

    for (final paragraph in paragraphs) {
      if (paragraph.length > normalizedLimit) {
        flush();
        chunks.addAll(_splitLongParagraph(paragraph, normalizedLimit));
        continue;
      }

      final separator = buffer.isEmpty ? '' : '\n\n';
      if (buffer.length + separator.length + paragraph.length >
          normalizedLimit) {
        flush();
      }
      if (buffer.isNotEmpty) {
        buffer.write('\n\n');
      }
      buffer.write(paragraph);
    }

    flush();
    return chunks;
  }

  static List<String> _paragraphs(String text) {
    return text
        .split(RegExp(r'\n\s*\n'))
        .map((paragraph) => paragraph.trim())
        .where((paragraph) => paragraph.isNotEmpty)
        .toList();
  }

  static List<String> _splitLongParagraph(String paragraph, int limit) {
    final parts = <String>[];
    var remaining = paragraph.trim();

    while (remaining.length > limit) {
      final splitIndex = _bestSplitIndex(remaining, limit);
      parts.add(remaining.substring(0, splitIndex).trim());
      remaining = remaining.substring(splitIndex).trim();
    }

    if (remaining.isNotEmpty) {
      parts.add(remaining);
    }
    return parts;
  }

  static int _bestSplitIndex(String text, int limit) {
    final searchStart = (limit * 0.55).floor();
    final candidates = [
      '\n',
      '。',
      '！',
      '？',
      '.',
      '!',
      '?',
      ';',
      '；',
      ',',
      '，',
      ' '
    ];

    for (final candidate in candidates) {
      final index = text.lastIndexOf(candidate, limit);
      if (index >= searchStart) {
        return index + candidate.length;
      }
    }

    return limit;
  }
}
