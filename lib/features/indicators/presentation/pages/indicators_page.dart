import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/indicator.dart';
import '../bloc/indicator_bloc.dart';
import '../bloc/indicator_event.dart';
import '../bloc/indicator_state.dart';

class IndicatorsPage extends StatefulWidget {
  const IndicatorsPage({super.key});

  @override
  State<IndicatorsPage> createState() => _IndicatorsPageState();
}

class _IndicatorsPageState extends State<IndicatorsPage> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<IndicatorBloc>().add(const LoadIndicatorsEvent());
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
        title: const Text('Indicators'),
      ),
      body: BlocConsumer<IndicatorBloc, IndicatorState>(
        listener: (context, state) {
          final selected = state.selectedIndicator;
          if (selected != null) {
            _idController.text = selected.id ?? '';
            _nameController.text = selected.name;
            _descriptionController.text = selected.description ?? '';
          }

          if (state.status == IndicatorStatus.error &&
              state.errorMessage.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage)),
            );
          }
        },
        builder: (context, state) {
          final bloc = context.read<IndicatorBloc>();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Integracion de endpoints REST para Indicators.',
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
                      onPressed: () => bloc.add(const LoadIndicatorsEvent()),
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
                        bloc.add(LoadIndicatorEvent(id));
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

                        final entity = Indicator(
                          name: name,
                          description: _nullableText(_descriptionController.text),
                        );
                        bloc.add(CreateIndicatorEvent(entity));
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

                        final entity = Indicator(
                          id: id,
                          name: name,
                          description: _nullableText(_descriptionController.text),
                        );
                        bloc.add(UpdateIndicatorEvent(entity));
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
                if (state.status == IndicatorStatus.loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: LinearProgressIndicator(),
                  ),
                const SizedBox(height: 8),
                Expanded(
                  child: state.indicators.isEmpty
                      ? const Center(
                          child: Text('Sin datos de Indicators.'),
                        )
                      : ListView.separated(
                          itemCount: state.indicators.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final indicator = state.indicators[index];
                            return ListTile(
                              title: Text(indicator.name),
                              subtitle: Text(indicator.description ?? '-'),
                              trailing: Text(indicator.id ?? '-'),
                              onTap: () {
                                if (indicator.id != null &&
                                    indicator.id!.isNotEmpty) {
                                  bloc.add(
                                    LoadIndicatorEvent(indicator.id!),
                                  );
                                } else {
                                  _idController.text = '';
                                  _nameController.text = indicator.name;
                                  _descriptionController.text =
                                      indicator.description ?? '';
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
