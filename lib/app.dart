import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/constants/app_constants.dart';
import 'core/di/service_locator.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_state.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (_) => sl<AuthBloc>(),
      child: BlocListener<AuthBloc, AuthState>(
        listenWhen: (previous, current) =>
            previous.status != current.status ||
            previous.infoMessage != current.infoMessage,
        listener: (context, state) {
          final navigator = AppRouter.navigatorKey.currentState;
          final messenger = AppRouter.scaffoldMessengerKey.currentState;

          if (state.infoMessage.isNotEmpty) {
            messenger
              ?..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.infoMessage)));
          }

          if (state.status == AuthStatus.authenticated) {
            navigator?.pushNamedAndRemoveUntil(
              AppRoutes.home,
              (route) => false,
            );
            return;
          }

          if (state.status == AuthStatus.unauthenticated) {
            navigator?.pushNamedAndRemoveUntil(
              AppRoutes.login,
              (route) => false,
            );
          }
        },
        child: MaterialApp(
          title: AppConstants.appName,
          theme: AppTheme.light,
          navigatorKey: AppRouter.navigatorKey,
          scaffoldMessengerKey: AppRouter.scaffoldMessengerKey,
          initialRoute: AppRoutes.login,
          onGenerateRoute: AppRouter.onGenerateRoute,
        ),
      ),
    );
  }
}
