import 'package:flutter_test/flutter_test.dart';
import 'package:news_api/models/article_model.dart';
import 'package:news_api/models/news_response_model.dart';

void main() {
  group('ArticleModel.fromJson', () {
    test('memetakan field GNews ke field aplikasi', () {
      final article = ArticleModel.fromJson({
        'title': 'Judul Berita',
        'description': 'Ringkasan berita',
        'url': 'https://news.detik.com/berita/1',
        'image': 'https://img.example.com/berita.jpg',
        'publishedAt': '2026-11-18T00:30:00Z',
        'content': 'Isi berita [988 chars]',
        'source': {'name': 'detikcom'},
      });

      expect(article.title, 'Judul Berita');
      expect(article.description, 'Ringkasan berita');
      expect(article.url, 'https://news.detik.com/berita/1');
      expect(article.urlToImage, 'https://img.example.com/berita.jpg');
      expect(article.publishedAt, '2026-11-18T00:30:00Z');
      expect(article.author, 'detikcom');
      expect(article.content, 'Isi berita...');
    });

    test('memberi nilai aman saat field kosong atau null', () {
      final article = ArticleModel.fromJson({
        'title': null,
        'description': null,
        'url': null,
        'image': null,
        'publishedAt': null,
        'content': null,
        'source': null,
      });

      expect(article.title, 'Tanpa Judul');
      expect(article.description, isNull);
      expect(article.url, isNull);
      expect(article.urlToImage, isNull);
      expect(article.publishedAt, '');
      expect(article.author, isNull);
      expect(article.content, isNull);
    });

    test('author diambil dari source.name', () {
      final article = ArticleModel.fromJson({
        'title': 'Berita',
        'publishedAt': '2026-11-18T00:30:00Z',
        'source': {'id': 'detik', 'name': 'detikcom'},
      });

      expect(article.author, 'detikcom');
    });
  });

  group('NewsResponseModel.fromJson', () {
    test('mem-parsing daftar artikel dan totalArticles', () {
      final response = NewsResponseModel.fromJson({
        'totalArticles': 2,
        'articles': [
          {'title': 'Pertama', 'publishedAt': '2026-11-18T00:30:00Z'},
          {'title': 'Kedua', 'publishedAt': '2026-11-18T01:00:00Z'},
        ],
      });

      expect(response.totalArticles, 2);
      expect(response.articles, hasLength(2));
      expect(response.articles.first.title, 'Pertama');
      expect(response.articles.last.title, 'Kedua');
    });

    test('mengembalikan daftar kosong bila articles null', () {
      final response = NewsResponseModel.fromJson({'totalArticles': 0});

      expect(response.totalArticles, 0);
      expect(response.articles, isEmpty);
    });

    test('melempar FormatException bila articles bukan List', () {
      expect(
        () => NewsResponseModel.fromJson({'articles': 'bukan list'}),
        throwsFormatException,
      );
    });
  });
}
