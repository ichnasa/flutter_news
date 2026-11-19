import 'package:flutter/material.dart';

import '../views/detail_view.dart';
import '../views/home_view.dart';
import '../views/search_view.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();

  static final routes = <String, WidgetBuilder>{
    AppRoutes.home: (_) => const HomeView(),
    AppRoutes.detail: (_) => const DetailView(),
    AppRoutes.search: (context) {
      final keyword = ModalRoute.of(context)!.settings.arguments as String;
      return SearchView(keyword: keyword);
    },
  };
}
