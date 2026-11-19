import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:news_api/config/env.dart';
import 'package:news_api/services/api_exception.dart';

DioException _badResponse(int statusCode, dynamic data) {
  final options = RequestOptions(path: '/top-headlines');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: options, statusCode: statusCode, data: data),
  );
}

DioException _byType(DioExceptionType type) {
  return DioException(
    requestOptions: RequestOptions(path: '/top-headlines'),
    type: type,
  );
}

void main() {
  group('ApiException.fromDio', () {
    test('timeout menghasilkan pesan koneksi lambat', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.transformTimeout,
      ]) {
        expect(
          ApiException.fromDio(_byType(type)).message,
          contains('Koneksi lambat'),
        );
      }
    });

    test('connectionError menghasilkan pesan tanpa internet', () {
      expect(
        ApiException.fromDio(
          _byType(DioExceptionType.connectionError),
        ).message,
        contains('Tidak ada koneksi internet'),
      );
    });

    test('badCertificate dan cancel punya pesan sendiri', () {
      expect(
        ApiException.fromDio(
          _byType(DioExceptionType.badCertificate),
        ).message,
        contains('Sertifikat'),
      );
      expect(
        ApiException.fromDio(_byType(DioExceptionType.cancel)).message,
        contains('dibatalkan'),
      );
    });

    test('401, 403, 404, 429, dan 5xx dipetakan ke pesan berbeda', () {
      expect(
        ApiException.fromDio(_badResponse(401, null)).message,
        'API key salah atau tidak terdaftar.',
      );
      expect(
        ApiException.fromDio(_badResponse(403, null)).message,
        contains('Kuota harian habis'),
      );
      expect(
        ApiException.fromDio(_badResponse(404, null)).message,
        contains('endpoint tidak ditemukan'),
      );
      expect(
        ApiException.fromDio(_badResponse(429, null)).message,
        contains('1 request per detik'),
      );
      expect(
        ApiException.fromDio(_badResponse(500, null)).message,
        contains('Server GNews sedang bermasalah'),
      );
    });

    test('400 mengambil pesan errors berbentuk List', () {
      final error = ApiException.fromDio(
        _badResponse(400, {
          'errors': ['The API key is malformed.'],
        }),
      );

      expect(error.statusCode, 400);
      expect(error.message, contains('The API key is malformed.'));
    });

    test('400 mengambil pesan errors berbentuk Map', () {
      final error = ApiException.fromDio(
        _badResponse(400, {
          'errors': {'q': 'Kata kunci tidak valid'},
        }),
      );

      expect(error.message, contains('Kata kunci tidak valid'));
    });

    test('unknown memakai pesan tak terduga dan menyamarkan key', () {
      final error = ApiException.fromDio(
        DioException(
          requestOptions: RequestOptions(path: '/top-headlines'),
          type: DioExceptionType.unknown,
          message: 'Request gagal: apikey=secret123',
        ),
      );

      expect(error.message, contains('Terjadi kesalahan tak terduga'));
      expect(error.message, contains('apikey=***'));
      expect(error.message, isNot(contains('secret123')));
    });
  });

  group('ApiException.toString', () {
    test('hanya mengembalikan message tanpa prefix Exception', () {
      const error = ApiException('Pesan jelas');

      expect(error.toString(), 'Pesan jelas');
      expect(error.toString(), isNot(contains('Exception:')));
    });
  });

  group('Env.samarkan', () {
    test('menyamarkan nilai apikey pada URL', () {
      expect(
        Env.samarkan('https://gnews.io/api/v4?apikey=secret123&lang=id'),
        'https://gnews.io/api/v4?apikey=***&lang=id',
      );
    });

    test('tidak peka huruf besar-kecil', () {
      expect(
        Env.samarkan('https://gnews.io/api/v4?APIKEY=abc123'),
        'https://gnews.io/api/v4?APIKEY=***',
      );
    });
  });
}
