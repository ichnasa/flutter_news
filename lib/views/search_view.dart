import 'package:flutter/material.dart';

import '../models/article_model.dart';
import '../routes/app_routes.dart';
import '../services/news_api_service.dart';
import '../widgets/article_card.dart';
import '../widgets/error_view.dart';

class SearchView extends StatefulWidget {
  final String keyword;

  /// Dapat diinjeksi pada test; null berarti memakai service production.
  final NewsApiService? service;

  const SearchView({super.key, required this.keyword, this.service});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  late final NewsApiService _service = widget.service ?? NewsApiService();
  late Future<List<ArticleModel>> _futureResults;

  @override
  void initState() {
    super.initState();
    _futureResults = _service.searchNews(widget.keyword);
  }

  void _retry() {
    final future = _service.searchNews(widget.keyword);
    // Cegah unhandled error bila Future gagal sebelum FutureBuilder rebuild.
    future.ignore();
    setState(() {
      _futureResults = future;
    });
  }

  Future<void> _refresh() async {
    _retry();
    try {
      await _futureResults;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Results: ${widget.keyword}')),
      body: FutureBuilder<List<ArticleModel>>(
        future: _futureResults,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorView(
              message: snapshot.error.toString(),
              onRetry: _retry,
            );
          }
          final articles = snapshot.data ?? [];
          if (articles.isEmpty) {
            return const Center(
              child: Text('Tidak ada berita untuk kata kunci ini.'),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: articles.length,
              itemBuilder: (context, index) => ArticleCard(
                article: articles[index],
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.detail,
                  arguments: articles[index],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
