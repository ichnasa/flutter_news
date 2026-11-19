import 'package:flutter/material.dart';

import '../models/article_model.dart';
import '../routes/app_routes.dart';
import '../services/news_api_service.dart';
import '../utils/app_colors.dart';
import '../widgets/article_card.dart';
import '../widgets/error_view.dart';

class HomeView extends StatefulWidget {
  /// Dapat diinjeksi pada test; null berarti memakai service production.
  final NewsApiService? service;

  const HomeView({super.key, this.service});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late final NewsApiService _service = widget.service ?? NewsApiService();
  final Map<String, Future<List<ArticleModel>>> _categoryFutures = {};

  static const categories = <String, String>{
    'general': 'Top Stories',
    'nation': 'US',
    'technology': 'Technology',
    'business': 'Business',
    'sports': 'Sports',
    'health': 'Health',
    'science': 'Science',
  };

  String _selectedCategory = 'general';
  late Future<List<ArticleModel>> _futureNews;

  @override
  void initState() {
    super.initState();
    _futureNews = _futureForCategory(_selectedCategory);
  }

  Future<List<ArticleModel>> _futureForCategory(String category) {
    return _categoryFutures.putIfAbsent(category, () {
      final future = _service.getTopHeadlines(category: category);
      // Cegah unhandled error bila Future gagal sebelum FutureBuilder
      // sempat melakukan rebuild (misalnya pada tombol Coba Lagi).
      future.ignore();
      return future;
    });
  }

  void _changeCategory(String category) {
    if (category == _selectedCategory) return;
    setState(() {
      _selectedCategory = category;
      _futureNews = _futureForCategory(category);
    });
  }

  void _retry() {
    setState(() {
      _categoryFutures.remove(_selectedCategory);
      _futureNews = _futureForCategory(_selectedCategory);
    });
  }

  Future<void> _refresh() async {
    _categoryFutures.remove(_selectedCategory);
    _retry();
    try {
      await _futureNews;
    } catch (_) {}
  }

  Future<void> _showSearchDialog() async {
    final keyword = await showDialog<String>(
      context: context,
      builder: (context) => const _SearchDialog(),
    );
    if (!mounted || keyword == null || keyword.isEmpty) return;
    Navigator.pushNamed(context, AppRoutes.search, arguments: keyword);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('US News'),
        actions: [
          IconButton(
            onPressed: _showSearchDialog,
            tooltip: 'Search news',
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryChips(),
          Expanded(
            child: FutureBuilder<List<ArticleModel>>(
              future: _futureNews,
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
                    child: Text('No news available for this category.'),
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
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Container(
      height: 64,
      color: AppColors.surface,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        children: categories.entries
            .map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(entry.value),
                  selected: entry.key == _selectedCategory,
                  onSelected: (_) => _changeCategory(entry.key),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

/// Dialog mencari berita. Controller dimiliki oleh State dialog agar tidak
/// di-dispose saat animasi tutup dialog masih berjalan.
class _SearchDialog extends StatefulWidget {
  const _SearchDialog();

  @override
  State<_SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<_SearchDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.pop(context, _controller.text.trim());

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Search News'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _submit(),
        decoration: const InputDecoration(
          hintText: 'Example: US technology',
          prefixIcon: Icon(Icons.search),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Search')),
      ],
    );
  }
}
