import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/application.dart';
import '../bloc/application_bloc.dart';
import '../bloc/application_event.dart';
import '../bloc/application_state.dart';

class ApplicationsPage extends StatefulWidget {
  const ApplicationsPage({super.key});

  @override
  State<ApplicationsPage> createState() => _ApplicationsPageState();
}

class _ApplicationsPageState extends State<ApplicationsPage> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ApplicationBloc>().add(const LoadApplicationsEvent());
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Applications'),
      ),
      body: BlocConsumer<ApplicationBloc, ApplicationState>(
        listener: (context, state) {
          final selected = state.selectedApplication;
          if (selected != null) {
            _idController.text = selected.id ?? '';
            _nameController.text = selected.name;
            _descriptionController.text = selected.description ?? '';
          }

          if (state.status == ApplicationStatus.error &&
              state.errorMessage.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage)),
            );
          }
        },
        builder: (context, state) {
          final bloc = context.read<ApplicationBloc>();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Integracion de endpoints REST para Applications.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _idController,
                  decoration: const InputDecoration(
                    labelText: 'ID',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: () => bloc.add(const LoadApplicationsEvent()),
                      child: const Text('Listar'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final id = _idController.text.trim();
                        if (id.isEmpty) {
                          _showMessage(
                            context,
                            'Ingresa un ID para consultar.',
                          );
                          return;
                        }
                        bloc.add(LoadApplicationEvent(id));
                      },
                      child: const Text('Obtener por ID'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final name = _nameController.text.trim();
                        if (name.isEmpty) {
                          _showMessage(
                            context,
                            'El nombre es obligatorio para crear.',
                          );
                          return;
                        }

                        final entity = Application(
                          name: name,
                          description: _nullableText(_descriptionController.text),
                        );
                        bloc.add(CreateApplicationEvent(entity));
                      },
                      child: const Text('Crear'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final id = _idController.text.trim();
                        final name = _nameController.text.trim();
                        if (id.isEmpty || name.isEmpty) {
                          _showMessage(
                            context,
                            'ID y nombre son obligatorios para actualizar.',
                          );
                          return;
                        }

                        final entity = Application(
                          id: id,
                          name: name,
                          description: _nullableText(_descriptionController.text),
                        );
                        bloc.add(UpdateApplicationEvent(entity));
                      },
                      child: const Text('Actualizar'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Estado: ${state.status.name}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (state.status == ApplicationStatus.loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: LinearProgressIndicator(),
                  ),
                const SizedBox(height: 8),
                Expanded(
                  child: state.applications.isEmpty
                      ? const Center(
                          child: Text('Sin datos de Applications.'),
                        )
                      : ListView.separated(
                          itemCount: state.applications.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final application = state.applications[index];
                            return ListTile(
                              title: Text(application.name),
                              subtitle: Text(application.description ?? '-'),
                              trailing: Text(application.id ?? '-'),
                              onTap: () {
                                if (application.id != null &&
                                    application.id!.isNotEmpty) {
                                  bloc.add(
                                    LoadApplicationEvent(application.id!),
                                  );
                                } else {
                                  _idController.text = '';
                                  _nameController.text = application.name;
                                  _descriptionController.text =
                                      application.description ?? '';
                                }
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String? _nullableText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}