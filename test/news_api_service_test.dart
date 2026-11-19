import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:news_api/services/api_exception.dart';
import 'package:news_api/services/news_api_service.dart';

void main() {
  group('NewsApiService.searchNews', () {
    late NewsApiService service;

    setUp(() {
      // Dio tidak dipakai untuk validasi input, jadi cukup instance kosong.
      service = NewsApiService(dio: Dio());
    });

    test('menolak kata kunci kosong tanpa mengirim request', () async {
      await expectLater(
        service.searchNews('   '),
        throwsA(
          isA<ApiException>().having(
            (error) => error.message,
            'message',
            contains('tidak boleh kosong'),
          ),
        ),
      );
    });

    test('menolak kata kunci lebih dari 200 karakter', () async {
      await expectLater(
        service.searchNews('a' * 201),
        throwsA(
          isA<ApiException>().having(
            (error) => error.message,
            'message',
            contains('maksimal 200 karakter'),
          ),
        ),
      );
    });
  });
}
