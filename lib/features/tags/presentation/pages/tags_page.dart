import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/tag.dart';
import '../bloc/tag_bloc.dart';
import '../bloc/tag_event.dart';
import '../bloc/tag_state.dart';

class TagsPage extends StatefulWidget {
  const TagsPage({super.key});

  @override
  State<TagsPage> createState() => _TagsPageState();
}

class _TagsPageState extends State<TagsPage> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _active = true;

  @override
  void initState() {
    super.initState();
    context.read<TagBloc>().add(const LoadTagsEvent());
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tags')),
      body: BlocConsumer<TagBloc, TagState>(
        listener: (context, state) {
          final selected = state.selectedTag;
          if (selected != null) {
            _idController.text = selected.id ?? '';
            _nameController.text = selected.name;
            _active = selected.active;
          }

          if (state.status == TagStatus.error &&
              state.errorMessage.isNotEmpty) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errorMessage)));
          }
        },
        builder: (context, state) {
          final bloc = context.read<TagBloc>();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Gestion de Tags: listado y creacion.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _idController,
                  readOnly: true,
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
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Activo'),
                  value: _active,
                  onChanged: (value) {
                    setState(() {
                      _active = value;
                    });
                  },
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: () => bloc.add(const LoadTagsEvent()),
                      child: const Text('Listar'),
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

                        bloc.add(
                          CreateTagEvent(Tag(name: name, active: _active)),
                        );
                      },
                      child: const Text('Crear Tag'),
                    ),
                    OutlinedButton(
                      onPressed: _clearForm,
                      child: const Text('Limpiar formulario'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Estado: ${state.status.name}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (state.status == TagStatus.loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: LinearProgressIndicator(),
                  ),
                const SizedBox(height: 8),
                Expanded(
                  child: state.tags.isEmpty
                      ? const Center(child: Text('Sin datos de Tags.'))
                      : ListView.separated(
                          itemCount: state.tags.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final tag = state.tags[index];
                            return ListTile(
                              title: Text(tag.name),
                              subtitle: Text(
                                tag.active ? 'Activo' : 'Inactivo',
                              ),
                              trailing: Text(tag.id ?? '-'),
                              onTap: () {
                                _idController.text = tag.id ?? '';
                                _nameController.text = tag.name;
                                setState(() {
                                  _active = tag.active;
                                });
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

  void _clearForm() {
    _idController.clear();
    _nameController.clear();
    setState(() {
      _active = true;
    });
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
