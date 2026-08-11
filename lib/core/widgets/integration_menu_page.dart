import 'package:flutter/material.dart';

import '../router/app_router.dart';

class IntegrationMenuPage extends StatelessWidget {
  const IntegrationMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Develop Workflow - Integracion REST')),
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
                  'Fase 3: Applications + Indicators + Discussions',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.applications),
                  child: const Text('Probar Applications'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.indicators),
                  child: const Text('Probar Indicators'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.discussions),
                  child: const Text('Probar Discussions'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
