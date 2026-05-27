import 'package:clear_translate/shared/errors/translation_error_mapper.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps 404 errors to base url guidance', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/chat/completions'),
      response: Response(
        requestOptions: RequestOptions(path: '/chat/completions'),
        statusCode: 404,
      ),
    );

    expect(
      TranslationErrorMapper.message(error),
      contains('API Base URL'),
    );
  });

  test('maps timeout errors to readable message', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/chat/completions'),
      type: DioExceptionType.receiveTimeout,
    );

    expect(TranslationErrorMapper.message(error), contains('请求超时'));
  });
}
