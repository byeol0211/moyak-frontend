import 'package:flutter/foundation.dart';

/// Preview is selected explicitly; normal runs never silently use sample data.
abstract final class AppConfig {
  static final preview = ValueNotifier<bool>(
    const bool.fromEnvironment('PREVIEW_MODE'),
  );

  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  static Uri endpoint(String path) {
    if (apiBaseUrl.isNotEmpty) return Uri.parse(apiBaseUrl).resolve(path);
    if (kIsWeb && Uri.base.hasAuthority) return Uri.base.resolve(path);
    throw StateError('서버 연결을 준비 중이에요. 로그인 화면에서 화면 미리보기를 이용해주세요.');
  }
}
