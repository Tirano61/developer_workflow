import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../router/app_router.dart';

class IntegrationMenuPage extends StatelessWidget {
  const IntegrationMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDeveloper =
        context.watch<AuthBloc>().state.session?.user.isDeveloper ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Develop Workflow - Integracion REST'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesion',
            onPressed: () {
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Develop Workflow',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (isDeveloper) ...[
                  ElevatedButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.applications),
                    child: const Text('Administrar catalogos'),
                  ),
                  const SizedBox(height: 12),
                ],
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.discussions),
                  child: const Text('Discussions'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
