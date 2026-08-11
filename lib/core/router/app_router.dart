import 'package:flutter/material.dart';

import '../widgets/app_placeholder_page.dart';

class AppRoutes {
  const AppRoutes._();

  static const String home = '/';
  static const String login = '/login';
}

class AppRouter {
  const AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const AppPlaceholderPage(
            title: 'Login',
            description: 'Pantalla base preparada para autenticacion.',
          ),
        );
      case AppRoutes.home:
      default:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const AppPlaceholderPage(
            title: 'Develop Workflow',
            description: 'Base de frontend lista para crecer por features.',
          ),
        );
    }
  }
}
