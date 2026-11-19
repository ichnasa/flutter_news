import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/env.dart';
import '../models/article_model.dart';
import '../models/news_response_model.dart';
import 'api_exception.dart';

class NewsApiService {
  final Dio _dio;

  NewsApiService({Dio? dio}) : _dio = dio ?? _buatDio();

  static Dio _buatDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: Env.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        queryParameters: {
          if (Env.pakaiKeyLangsung) 'apikey': Env.apiKey,
          'lang': 'en',
          'country': 'us',
          'max': 10,
        },
      ),
    );
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          responseBody: true,
          logPrint: (value) => debugPrint(Env.samarkan(value.toString())),
        ),
      );
    }
    return dio;
  }

  Future<List<ArticleModel>> getTopHeadlines({String category = 'general'}) {
    return _ambilArtikel('/top-headlines', {'category': category});
  }

  Future<List<ArticleModel>> searchNews(String keyword) async {
    final cleanKeyword = keyword.trim();
    if (cleanKeyword.isEmpty) {
      return Future.error(
        const ApiException(
          'Permintaan tidak valid: Kata kunci pencarian tidak boleh kosong.',
          statusCode: 400,
        ),
      );
    }
    if (cleanKeyword.length > 200) {
      return Future.error(
        const ApiException(
          'Permintaan tidak valid: Kata kunci maksimal 200 karakter.',
          statusCode: 400,
        ),
      );
    }
    return _ambilArtikel('/search', {
      'q': cleanKeyword,
      'sortby': 'publishedAt',
    });
  }

  Future<List<ArticleModel>> _ambilArtikel(
    String path,
    Map<String, dynamic> query,
  ) async {
    if (!Env.lengkap) {
      throw const ApiException(
        'Konfigurasi belum diisi. Jalankan dengan '
        '--dart-define-from-file=config/env.json',
      );
    }
    try {
      final response = await _dio.get(path, queryParameters: query);
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const ApiException('Format data dari server tidak dikenali.');
      }
      return NewsResponseModel.fromJson(data).articles;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    } on TypeError catch (_) {
      throw const ApiException('Struktur data dari server berbeda dari model.');
    } on FormatException catch (error) {
      throw ApiException(error.message);
    }
  }
}
