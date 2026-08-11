import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/applications/presentation/bloc/application_bloc.dart';
import '../../features/applications/presentation/pages/applications_page.dart';
import '../../features/indicators/presentation/bloc/indicator_bloc.dart';
import '../../features/indicators/presentation/pages/indicators_page.dart';
import '../di/service_locator.dart';
import '../widgets/integration_menu_page.dart';
import '../widgets/app_placeholder_page.dart';

class AppRoutes {
  const AppRoutes._();

  static const String home = '/';
  static const String login = '/login';
  static const String applications = '/applications';
  static const String indicators = '/indicators';
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
      case AppRoutes.applications:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => BlocProvider<ApplicationBloc>(
            create: (_) => sl<ApplicationBloc>(),
            child: const ApplicationsPage(),
          ),
        );
      case AppRoutes.indicators:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => BlocProvider<IndicatorBloc>(
            create: (_) => sl<IndicatorBloc>(),
            child: const IndicatorsPage(),
          ),
        );
      case AppRoutes.home:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const IntegrationMenuPage(),
        );
      default:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const AppPlaceholderPage(
            title: 'Develop Workflow',
            description: 'Ruta no encontrada en la configuracion de AppRouter.',
          ),
        );
    }
  }
}
