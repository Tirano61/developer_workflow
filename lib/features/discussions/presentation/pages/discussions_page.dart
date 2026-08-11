import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/app_router.dart';
import '../../domain/entities/discussion.dart';
import '../../domain/entities/discussion_filters.dart';
import '../bloc/discussion_bloc.dart';
import '../bloc/discussion_event.dart';
import '../bloc/discussion_state.dart';
import '../widgets/discussion_list_tile.dart';
import 'discussion_route_args.dart';

class DiscussionsPage extends StatefulWidget {
  const DiscussionsPage({super.key});

  @override
  State<DiscussionsPage> createState() => _DiscussionsPageState();
}

class _DiscussionsPageState extends State<DiscussionsPage> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _pageController = TextEditingController(
    text: '1',
  );
  final TextEditingController _limitController = TextEditingController(
    text: '20',
  );
  final TextEditingController _applicationIdsController =
      TextEditingController();
  final TextEditingController _indicatorIdsController = TextEditingController();
  final TextEditingController _tagIdsController = TextEditingController();
  final TextEditingController _createdByController = TextEditingController();

  DiscussionType? _selectedType;
  DiscussionRecordStatus? _selectedStatus;
  bool _mine = false;

  @override
  void initState() {
    super.initState();
    _requestList();
  }

  @override
  void dispose() {
    _idController.dispose();
    _pageController.dispose();
    _limitController.dispose();
    _applicationIdsController.dispose();
    _indicatorIdsController.dispose();
    _tagIdsController.dispose();
    _createdByController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Discussions')),
      body: BlocConsumer<DiscussionBloc, DiscussionState>(
        listener: (context, state) {
          final selected = state.selectedDiscussion;
          if (selected != null &&
              selected.id != null &&
              selected.id!.isNotEmpty) {
            _idController.text = selected.id!;
          }

          if (state.status == DiscussionStatus.error &&
              state.errorMessage.isNotEmpty) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errorMessage)));
          }
        },
        builder: (context, state) {
          final bloc = context.read<DiscussionBloc>();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Fase 3: listado y gestion de Discussions con filtros y paginacion.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _idController,
                decoration: const InputDecoration(
                  labelText: 'ID discussion (detalle/edicion)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: 130,
                    child: TextField(
                      controller: _pageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Page',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 130,
                    child: TextField(
                      controller: _limitController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Limit',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<DiscussionType?>(
                key: ValueKey<DiscussionType?>(_selectedType),
                initialValue: _selectedType,
                items: [
                  const DropdownMenuItem<DiscussionType?>(
                    value: null,
                    child: Text('Tipo: todos'),
                  ),
                  ...DiscussionType.values
                      .where((type) => type != DiscussionType.unknown)
                      .map(
                        (type) => DropdownMenuItem<DiscussionType?>(
                          value: type,
                          child: Text(type.apiValue),
                        ),
                      ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedType = value;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Filtro type',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<DiscussionRecordStatus?>(
                key: ValueKey<DiscussionRecordStatus?>(_selectedStatus),
                initialValue: _selectedStatus,
                items: [
                  const DropdownMenuItem<DiscussionRecordStatus?>(
                    value: null,
                    child: Text('Estado: todos'),
                  ),
                  ...DiscussionRecordStatus.values
                      .where(
                        (status) => status != DiscussionRecordStatus.unknown,
                      )
                      .map(
                        (status) => DropdownMenuItem<DiscussionRecordStatus?>(
                          value: status,
                          child: Text(status.apiValue),
                        ),
                      ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Filtro status',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _applicationIdsController,
                decoration: const InputDecoration(
                  labelText: 'applicationIds (CSV UUID)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _indicatorIdsController,
                decoration: const InputDecoration(
                  labelText: 'indicatorIds (CSV UUID)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _tagIdsController,
                decoration: const InputDecoration(
                  labelText: 'tagIds (CSV UUID)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _createdByController,
                decoration: const InputDecoration(
                  labelText: 'createdBy (UUID usuario)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 4),
              SwitchListTile.adaptive(
                title: const Text('Solo mis discussions (mine=true)'),
                value: _mine,
                onChanged: (value) {
                  setState(() {
                    _mine = value;
                  });
                },
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: _requestList,
                    child: const Text('Listar'),
                  ),
                  ElevatedButton(
                    onPressed: _clearFilters,
                    child: const Text('Limpiar filtros'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final id = _idController.text.trim();
                      if (id.isEmpty) {
                        _showMessage(context, 'Ingresa un ID para consultar.');
                        return;
                      }
                      bloc.add(LoadDiscussionEvent(id));
                    },
                    child: const Text('Obtener por ID'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final changed = await Navigator.pushNamed(
                        context,
                        AppRoutes.discussionCreate,
                      );

                      if (!mounted) {
                        return;
                      }

                      if (changed == true) {
                        _requestList();
                      }
                    },
                    child: const Text('Nueva Discussion'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final selected = state.selectedDiscussion;
                      if (selected == null) {
                        _showMessage(
                          context,
                          'Selecciona una discussion o consulta por ID primero.',
                        );
                        return;
                      }

                      final changed = await Navigator.pushNamed(
                        context,
                        AppRoutes.discussionCreate,
                        arguments: DiscussionEditorRouteArgs(
                          discussion: selected,
                          discussionId: selected.id,
                        ),
                      );

                      if (!mounted) {
                        return;
                      }

                      if (changed == true) {
                        _requestList();
                      }
                    },
                    child: const Text('Editar seleccionada'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final id = _idController.text.trim();
                      if (id.isEmpty) {
                        _showMessage(
                          context,
                          'Ingresa un ID para ver detalle.',
                        );
                        return;
                      }

                      final changed = await Navigator.pushNamed(
                        context,
                        AppRoutes.discussionDetail,
                        arguments: DiscussionDetailRouteArgs(discussionId: id),
                      );

                      if (!mounted) {
                        return;
                      }

                      if (changed == true) {
                        _requestList();
                      }
                    },
                    child: const Text('Ver detalle'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Estado: ${state.status.name}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                'Page ${state.page.page} | Limit ${state.page.limit} | '
                'Total ${state.page.total} | TotalPages ${state.page.totalPages}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (state.status == DiscussionStatus.loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: LinearProgressIndicator(),
                ),
              const SizedBox(height: 8),
              if (state.discussions.isEmpty)
                const Text('Sin datos de Discussions.')
              else
                ...state.discussions.map(
                  (discussion) => DiscussionListTile(
                    discussion: discussion,
                    onOpenDetail: () async {
                      if (discussion.id == null || discussion.id!.isEmpty) {
                        _showMessage(
                          context,
                          'La discussion seleccionada no tiene id valido.',
                        );
                        return;
                      }

                      final changed = await Navigator.pushNamed(
                        context,
                        AppRoutes.discussionDetail,
                        arguments: DiscussionDetailRouteArgs(
                          discussionId: discussion.id!,
                        ),
                      );

                      if (!mounted) {
                        return;
                      }

                      if (changed == true) {
                        _requestList();
                      }
                    },
                    onEdit: () async {
                      final changed = await Navigator.pushNamed(
                        context,
                        AppRoutes.discussionCreate,
                        arguments: DiscussionEditorRouteArgs(
                          discussion: discussion,
                          discussionId: discussion.id,
                        ),
                      );

                      if (!mounted) {
                        return;
                      }

                      if (changed == true) {
                        _requestList();
                      }
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _requestList() {
    final filters = _buildFilters();
    context.read<DiscussionBloc>().add(LoadDiscussionsEvent(filters: filters));
  }

  DiscussionFilters _buildFilters() {
    return DiscussionFilters(
      page: _parsePositiveInt(_pageController.text, fallback: 1),
      limit: _parsePositiveInt(_limitController.text, fallback: 20),
      type: _selectedType,
      status: _selectedStatus,
      applicationIds: _parseCsvIds(_applicationIdsController.text),
      indicatorIds: _parseCsvIds(_indicatorIdsController.text),
      tagIds: _parseCsvIds(_tagIdsController.text),
      createdBy: _nullableText(_createdByController.text),
      mine: _mine,
    );
  }

  void _clearFilters() {
    setState(() {
      _pageController.text = '1';
      _limitController.text = '20';
      _applicationIdsController.clear();
      _indicatorIdsController.clear();
      _tagIdsController.clear();
      _createdByController.clear();
      _selectedType = null;
      _selectedStatus = null;
      _mine = false;
    });

    _requestList();
  }

  int _parsePositiveInt(String value, {required int fallback}) {
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed <= 0) {
      return fallback;
    }
    return parsed;
  }

  List<String> _parseCsvIds(String value) {
    return value
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  String? _nullableText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
