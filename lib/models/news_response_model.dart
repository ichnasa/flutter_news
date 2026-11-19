import 'article_model.dart';

class NewsResponseModel {
  final int totalArticles;
  final List<ArticleModel> articles;

  const NewsResponseModel({
    required this.totalArticles,
    required this.articles,
  });

  factory NewsResponseModel.fromJson(Map<String, dynamic> json) {
    final rawArticles = json['articles'];
    final totalArticles = json['totalArticles'] as int? ?? 0;
    if (rawArticles == null) {
      return NewsResponseModel(totalArticles: totalArticles, articles: []);
    }
    if (rawArticles is! List) {
      throw const FormatException('Field articles tidak valid.');
    }
    return NewsResponseModel(
      totalArticles: totalArticles,
      articles: rawArticles
          .map((item) => ArticleModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
