import 'package:clear_translate/domain/entities/dictionary_entry.dart';
import 'package:clear_translate/domain/entities/translation_request.dart';
import 'package:clear_translate/domain/entities/translation_result.dart';
import 'package:clear_translate/domain/providers/translation_provider.dart';

class FakeTranslationProvider implements TranslationProvider {
  FakeTranslationProvider(this.output,
      {this.outputs, this.failAtCalls = const {}, this.onTranslate});

  final String output;
  final List<String>? outputs;
  final Set<int> failAtCalls;
  final Future<void> Function(int callCount)? onTranslate;
  TranslationRequest? lastRequest;
  final List<TranslationRequest> requests = [];
  bool wasCancelled = false;
  int _callCount = 0;

  @override
  Future<void> cancel(String requestId) async {
    wasCancelled = true;
  }

  @override
  Future<DictionaryEntry> lookup(String term) {
    throw UnimplementedError();
  }

  @override
  Future<TranslationResult> translate(TranslationRequest request) async {
    _callCount++;
    lastRequest = request;
    requests.add(request);

    await onTranslate?.call(_callCount);

    if (failAtCalls.contains(_callCount)) {
      throw StateError('planned failure $_callCount');
    }

    final translatedText = outputs == null
        ? output
        : outputs![(_callCount - 1).clamp(0, outputs!.length - 1)];

    return TranslationResult(
      sourceText: request.sourceText,
      translatedText: translatedText,
      sourceLanguage: request.sourceLanguage,
      targetLanguage: request.targetLanguage,
      mode: request.mode,
      provider: 'fake',
      model: 'fake-model',
    );
  }
}
