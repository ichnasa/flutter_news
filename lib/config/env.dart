class Env {
  Env._();

  static const _baseUrlDefine = String.fromEnvironment('GNEWS_BASE_URL');
  static const _apiKeyDefine = String.fromEnvironment('GNEWS_API_KEY');

  /// URL dan API key hanya dibaca dari --dart-define-from-file.
  /// Tidak ada fallback yang ditulis di kode agar key tidak ikut ke repo/APK.
  static String get baseUrl => _baseUrlDefine;
  static String get apiKey => _apiKeyDefine;

  /// Mode production (proxy) cukup membutuhkan base URL.
  static bool get lengkap => baseUrl.isNotEmpty;
  static bool get pakaiKeyLangsung => apiKey.isNotEmpty;

  /// Menyamarkan API key di teks log / pesan error.
  static String samarkan(String teks) {
    var hasil = teks.replaceAllMapped(
      RegExp(r'(apikey=)[^&\s"]+', caseSensitive: false),
      (match) => '${match[1]}***',
    );
    if (apiKey.isNotEmpty) hasil = hasil.replaceAll(apiKey, '***');
    return hasil;
  }
}
