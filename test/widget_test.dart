import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:news_api/models/article_model.dart';
import 'package:news_api/routes/app_routes.dart';
import 'package:news_api/services/api_exception.dart';
import 'package:news_api/services/news_api_service.dart';
import 'package:news_api/views/detail_view.dart';
import 'package:news_api/views/home_view.dart';
import 'package:news_api/views/search_view.dart';
import 'package:news_api/widgets/article_card.dart';
import 'package:news_api/widgets/error_view.dart';

class FakeNewsApiService extends NewsApiService {
  FakeNewsApiService(this.handler) : super(dio: Dio());

  final Future<List<ArticleModel>> Function(String category) handler;
  int calls = 0;

  @override
  Future<List<ArticleModel>> getTopHeadlines({String category = 'general'}) {
    calls++;
    return handler(category);
  }
}

class FakeSearchService extends NewsApiService {
  FakeSearchService(this.handler) : super(dio: Dio());

  final Future<List<ArticleModel>> Function(String keyword) handler;
  int calls = 0;

  @override
  Future<List<ArticleModel>> searchNews(String keyword) {
    calls++;
    return handler(keyword);
  }
}

const _article = ArticleModel(
  title: 'Judul Berita Uji',
  description: 'Ringkasan berita uji',
  url: 'https://news.example.com/1',
  publishedAt: '2026-11-18T00:30:00Z',
  author: 'detikcom',
  content: 'Isi berita uji',
);

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('ErrorView', () {
    testWidgets('menampilkan pesan dan memanggil onRetry', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        _wrap(
          ErrorView(
            message: 'Tidak ada koneksi internet. Periksa jaringan Anda.',
            onRetry: () => retried = true,
          ),
        ),
      );

      expect(
        find.text('Tidak ada koneksi internet. Periksa jaringan Anda.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Coba Lagi'));
      expect(retried, isTrue);
    });
  });

  group('ArticleCard', () {
    testWidgets('menampilkan judul, sumber, dan tanggal', (tester) async {
      await tester.pumpWidget(
        _wrap(ArticleCard(article: _article, onTap: () {})),
      );

      expect(find.text('Judul Berita Uji'), findsOneWidget);
      expect(find.text('Ringkasan berita uji'), findsOneWidget);
      expect(find.text('detikcom'), findsOneWidget);
      expect(find.textContaining('Nov 18, 2026'), findsOneWidget);
    });
  });

  group('HomeView dengan FutureBuilder', () {
    testWidgets('menampilkan loading saat Future belum selesai', (tester) async {
      final completer = Completer<List<ArticleModel>>();
      final service = FakeNewsApiService((_) => completer.future);

      await tester.pumpWidget(_wrap(HomeView(service: service)));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(ArticleCard), findsNothing);
    });

    testWidgets('menampilkan daftar saat Future sukses', (tester) async {
      final service = FakeNewsApiService((_) async => [_article]);

      await tester.pumpWidget(_wrap(HomeView(service: service)));
      await tester.pumpAndSettle();

      expect(find.byType(ArticleCard), findsOneWidget);
      expect(find.text('Judul Berita Uji'), findsOneWidget);
    });

    testWidgets('menampilkan state kosong saat data kosong', (tester) async {
      final service = FakeNewsApiService((_) async => []);

      await tester.pumpWidget(_wrap(HomeView(service: service)));
      await tester.pumpAndSettle();

      expect(
        find.text('No news available for this category.'),
        findsOneWidget,
      );
    });

    testWidgets('menampilkan ErrorView saat Future gagal', (tester) async {
      final service = FakeNewsApiService(
        (_) async => throw const ApiException(
          'Tidak ada koneksi internet. Periksa jaringan Anda.',
        ),
      );

      await tester.pumpWidget(_wrap(HomeView(service: service)));
      await tester.pumpAndSettle();

      expect(find.byType(ErrorView), findsOneWidget);
      expect(
        find.text('Tidak ada koneksi internet. Periksa jaringan Anda.'),
        findsOneWidget,
      );
    });

    testWidgets('tombol Coba Lagi memicu request ulang', (tester) async {
      final service = FakeNewsApiService(
        (_) => Future<List<ArticleModel>>.delayed(
          const Duration(milliseconds: 10),
          () => throw const ApiException('Gagal memuat data.'),
        ),
      );

      await tester.pumpWidget(_wrap(HomeView(service: service)));
      await tester.pumpAndSettle();
      expect(service.calls, 1);

      await tester.tap(find.text('Coba Lagi'));
      await tester.pumpAndSettle();

      expect(service.calls, 2);
    });

    testWidgets('memilih chip kategori memuat Future kategori tersebut', (
      tester,
    ) async {
      final service = FakeNewsApiService((_) async => [_article]);

      await tester.pumpWidget(_wrap(HomeView(service: service)));
      await tester.pumpAndSettle();
      expect(service.calls, 1);

      await tester.tap(find.text('Technology'));
      await tester.pumpAndSettle();

      expect(service.calls, 2);
    });

    testWidgets('pull-to-refresh memuat ulang data', (tester) async {
      final service = FakeNewsApiService((_) async => [_article]);

      await tester.pumpWidget(_wrap(HomeView(service: service)));
      await tester.pumpAndSettle();
      expect(service.calls, 1);

      final list = find.descendant(
        of: find.byType(RefreshIndicator),
        matching: find.byType(ListView),
      );
      await tester.drag(list, const Offset(0, 400));
      await tester.pumpAndSettle();

      expect(service.calls, 2);
    });

    testWidgets('kembali ke kategori sebelumnya memakai cache', (tester) async {
      final service = FakeNewsApiService((_) async => [_article]);

      await tester.pumpWidget(_wrap(HomeView(service: service)));
      await tester.pumpAndSettle();
      expect(service.calls, 1);

      await tester.tap(find.text('Technology'));
      await tester.pumpAndSettle();
      expect(service.calls, 2);

      await tester.tap(find.text('Top Stories'));
      await tester.pumpAndSettle();
      expect(service.calls, 2, reason: 'Future kategori harus diambil dari cache');
    });

    testWidgets('IconButton membuka dialog dan halaman hasil pencarian', (
      tester,
    ) async {
      final homeService = FakeNewsApiService((_) async => [_article]);
      final searchService = FakeSearchService((_) async => [_article]);

      await tester.pumpWidget(
        MaterialApp(
          home: HomeView(service: homeService),
          onGenerateRoute: (settings) {
            if (settings.name == AppRoutes.search) {
              return MaterialPageRoute(
                builder: (_) => SearchView(
                  keyword: settings.arguments as String,
                  service: searchService,
                ),
              );
            }
            return null;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'technology');
      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();

      expect(find.text('Results: technology'), findsOneWidget);
      expect(find.byType(ArticleCard), findsOneWidget);
      expect(searchService.calls, 1);
    });
  });

  group('SearchView dengan FutureBuilder', () {
    testWidgets('menampilkan hasil pencarian', (tester) async {
      final service = FakeSearchService((_) async => [_article]);

      await tester.pumpWidget(
        MaterialApp(
          home: SearchView(keyword: 'technology', service: service),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ArticleCard), findsOneWidget);
      expect(find.text('Judul Berita Uji'), findsOneWidget);
    });

    testWidgets('menampilkan state kosong', (tester) async {
      final service = FakeSearchService((_) async => []);

      await tester.pumpWidget(
        MaterialApp(home: SearchView(keyword: 'tidak-ada', service: service)),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Tidak ada berita untuk kata kunci ini.'),
        findsOneWidget,
      );
    });

    testWidgets('menampilkan error dan bisa retry', (tester) async {
      final service = FakeSearchService(
        (_) => Future<List<ArticleModel>>.delayed(
          const Duration(milliseconds: 10),
          () => throw const ApiException('Gagal memuat data.'),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(home: SearchView(keyword: 'technology', service: service)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ErrorView), findsOneWidget);
      expect(service.calls, 1);

      await tester.tap(find.text('Coba Lagi'));
      await tester.pumpAndSettle();

      expect(service.calls, 2);
    });
  });

  group('DetailView', () {
    testWidgets('menampilkan isi artikel dan tombol sumber', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    '/detail',
                    arguments: _article,
                  ),
                  child: const Text('Buka Detail'),
                ),
              ),
            ),
          ),
          routes: {'/detail': (_) => const DetailView()},
        ),
      );

      await tester.tap(find.text('Buka Detail'));
      await tester.pumpAndSettle();

      expect(find.text('Judul Berita Uji'), findsOneWidget);
      expect(find.text('Isi berita uji'), findsOneWidget);
      expect(find.text('Buka sumber berita'), findsOneWidget);
    });
  });
}
