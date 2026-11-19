import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/article_model.dart';
import '../utils/date_formatter.dart';
import '../widgets/news_image.dart';

class DetailView extends StatelessWidget {
  const DetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final article = ModalRoute.of(context)!.settings.arguments as ArticleModel;
    return Scaffold(
      appBar: AppBar(title: const Text('News Detail')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          if (article.urlToImage != null)
            NewsImage(url: article.urlToImage!, height: 260),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.title,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Text(
                  '${article.author ?? 'Sumber berita'} • ${DateFormatter.formatDate(article.publishedAt)}',
                ),
                const Divider(height: 32),
                Text(
                  article.content ??
                      article.description ??
                      'Konten berita tidak tersedia.',
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(height: 1.6),
                ),
                if (article.url != null) ...[
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final uri = Uri.tryParse(article.url!);
                      if (uri != null) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Buka sumber berita'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
