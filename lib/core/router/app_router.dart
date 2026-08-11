import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/applications/presentation/bloc/application_bloc.dart';
import '../../features/applications/presentation/pages/applications_page.dart';
import '../../features/discussions/domain/entities/discussion.dart';
import '../../features/discussions/presentation/bloc/discussion_bloc.dart';
import '../../features/discussions/presentation/pages/discussion_detail_page.dart';
import '../../features/discussions/presentation/pages/discussion_editor_page.dart';
import '../../features/discussions/presentation/pages/discussion_route_args.dart';
import '../../features/discussions/presentation/pages/discussions_page.dart';
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
  static const String discussions = '/discussions';
  static const String discussionDetail = '/discussions/detail';
  static const String discussionCreate = '/discussions/create';
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
      case AppRoutes.discussions:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => BlocProvider<DiscussionBloc>(
            create: (_) => sl<DiscussionBloc>(),
            child: const DiscussionsPage(),
          ),
        );
      case AppRoutes.discussionDetail:
        final discussionId = _readDiscussionId(settings.arguments);
        if (discussionId == null || discussionId.isEmpty) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const AppPlaceholderPage(
              title: 'Discussion Detail',
              description:
                  'Falta un discussionId valido para abrir la pantalla de detalle.',
            ),
          );
        }

        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => BlocProvider<DiscussionBloc>(
            create: (_) => sl<DiscussionBloc>(),
            child: DiscussionDetailPage(discussionId: discussionId),
          ),
        );
      case AppRoutes.discussionCreate:
        final editorArgs = _readEditorArgs(settings.arguments);
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => BlocProvider<DiscussionBloc>(
            create: (_) => sl<DiscussionBloc>(),
            child: DiscussionEditorPage(
              initialDiscussion: editorArgs.discussion,
              discussionId: editorArgs.discussionId,
            ),
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

  static String? _readDiscussionId(Object? args) {
    if (args is DiscussionDetailRouteArgs) {
      return args.discussionId;
    }

    if (args is String) {
      return args;
    }

    return null;
  }

  static DiscussionEditorRouteArgs _readEditorArgs(Object? args) {
    if (args is DiscussionEditorRouteArgs) {
      return args;
    }

    if (args is Discussion) {
      return DiscussionEditorRouteArgs(discussion: args, discussionId: args.id);
    }

    if (args is String) {
      return DiscussionEditorRouteArgs(discussionId: args);
    }

    return const DiscussionEditorRouteArgs();
  }
}
