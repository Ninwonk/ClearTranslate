import 'package:dio/dio.dart';

class TranslationErrorMapper {
  const TranslationErrorMapper._();

  static String message(Object error) {
    if (error is DioException) {
      return _dioMessage(error);
    }

    if (error is StateError) {
      return error.message;
    }

    return '翻译失败，请稍后重试。';
  }

  static String _dioMessage(DioException error) {
    final statusCode = error.response?.statusCode;

    if (statusCode == 401 || statusCode == 403) {
      return 'API Key 无效或无权限，请检查设置。';
    }
    if (statusCode == 404) {
      return '接口地址不存在，请检查 API Base URL 是否包含正确版本路径，例如 /v1。';
    }
    if (statusCode == 429) {
      return '请求过于频繁或额度不足，请稍后再试。';
    }
    if (statusCode != null && statusCode >= 500) {
      return '服务商暂时不可用，请稍后再试。';
    }

    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        '请求超时，请检查网络或稍后重试。',
      DioExceptionType.connectionError => '网络连接失败，请检查网络。',
      DioExceptionType.cancel => '翻译已取消。',
      _ => '翻译请求失败，请检查 API 设置和网络。',
    };
  }
}
