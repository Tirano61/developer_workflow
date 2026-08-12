import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/app_router.dart';
import '../../../applications/domain/entities/application.dart';
import '../../../applications/presentation/bloc/application_bloc.dart';
import '../../../applications/presentation/bloc/application_event.dart';
import '../../../applications/presentation/bloc/application_state.dart';
import '../../../indicators/domain/entities/indicator.dart';
import '../../../indicators/presentation/bloc/indicator_bloc.dart';
import '../../../indicators/presentation/bloc/indicator_event.dart';
import '../../../indicators/presentation/bloc/indicator_state.dart';
import '../../../tags/domain/entities/tag.dart';
import '../../../tags/presentation/bloc/tag_bloc.dart';
import '../../../tags/presentation/bloc/tag_event.dart';
import '../../../tags/presentation/bloc/tag_state.dart';
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

  final Set<String> _selectedApplicationIds = <String>{};
  final Set<String> _selectedIndicatorIds = <String>{};
  final Set<String> _selectedTagIds = <String>{};

  DiscussionType? _selectedType;
  DiscussionRecordStatus? _selectedStatus;
  bool _mine = false;

  @override
  void initState() {
    super.initState();
    context.read<ApplicationBloc>().add(const LoadApplicationsEvent());
    context.read<IndicatorBloc>().add(const LoadIndicatorsEvent());
    context.read<TagBloc>().add(const LoadTagsEvent());
    _requestList();
  }

  @override
  void dispose() {
    _idController.dispose();
    _pageController.dispose();
    _limitController.dispose();
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
          final applicationState = context.watch<ApplicationBloc>().state;
          final indicatorState = context.watch<IndicatorBloc>().state;
          final tagState = context.watch<TagBloc>().state;
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
              _buildMultiSelectSection<Application>(
                title: 'Filtro Applications',
                subtitle: 'Filtra por una o varias applications.',
                items: applicationState.applications,
                selectedIds: _selectedApplicationIds,
                isLoading: applicationState.status == ApplicationStatus.loading,
                errorMessage: applicationState.status == ApplicationStatus.error
                    ? applicationState.errorMessage
                    : null,
                idOf: (item) => item.id,
                labelOf: (item) => item.name,
                onRetry: () => context.read<ApplicationBloc>().add(
                  const LoadApplicationsEvent(),
                ),
                onToggle: _toggleApplication,
              ),
              const SizedBox(height: 8),
              _buildMultiSelectSection<Indicator>(
                title: 'Filtro Indicators',
                subtitle: 'Filtra por uno o varios indicators.',
                items: indicatorState.indicators,
                selectedIds: _selectedIndicatorIds,
                isLoading: indicatorState.status == IndicatorStatus.loading,
                errorMessage: indicatorState.status == IndicatorStatus.error
                    ? indicatorState.errorMessage
                    : null,
                idOf: (item) => item.id,
                labelOf: (item) => item.name,
                onRetry: () => context.read<IndicatorBloc>().add(
                  const LoadIndicatorsEvent(),
                ),
                onToggle: _toggleIndicator,
              ),
              const SizedBox(height: 8),
              _buildMultiSelectSection<Tag>(
                title: 'Filtro Tags',
                subtitle: 'Filtra por tags de la discussion.',
                items: tagState.tags,
                selectedIds: _selectedTagIds,
                isLoading: tagState.status == TagStatus.loading,
                errorMessage: tagState.status == TagStatus.error
                    ? tagState.errorMessage
                    : null,
                idOf: (item) => item.id,
                labelOf: (item) => item.name,
                onRetry: () =>
                    context.read<TagBloc>().add(const LoadTagsEvent()),
                onToggle: _toggleTag,
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

  Widget _buildMultiSelectSection<T>({
    required String title,
    required String subtitle,
    required List<T> items,
    required Set<String> selectedIds,
    required bool isLoading,
    required String? errorMessage,
    required String? Function(T item) idOf,
    required String Function(T item) labelOf,
    required VoidCallback onRetry,
    required void Function(String id, bool selected) onToggle,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle),
            const SizedBox(height: 8),
            if (isLoading && items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              ),
            if (errorMessage != null && errorMessage.trim().isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    errorMessage,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: onRetry,
                    child: const Text('Reintentar carga'),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            if (!isLoading && items.isEmpty)
              const Text('No hay opciones disponibles.'),
            if (items.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: items
                    .map((item) {
                      final id = idOf(item)?.trim();
                      if (id == null || id.isEmpty) {
                        return null;
                      }

                      final label = labelOf(item).trim();
                      final selected = selectedIds.contains(id);

                      return FilterChip(
                        label: Text(label.isEmpty ? id : label),
                        selected: selected,
                        onSelected: (value) => onToggle(id, value),
                      );
                    })
                    .whereType<Widget>()
                    .toList(growable: false),
              ),
            const SizedBox(height: 8),
            Text('Seleccionados: ${selectedIds.length}'),
          ],
        ),
      ),
    );
  }

  void _toggleApplication(String id, bool selected) {
    setState(() {
      if (selected) {
        _selectedApplicationIds.add(id);
      } else {
        _selectedApplicationIds.remove(id);
      }
    });
  }

  void _toggleIndicator(String id, bool selected) {
    setState(() {
      if (selected) {
        _selectedIndicatorIds.add(id);
      } else {
        _selectedIndicatorIds.remove(id);
      }
    });
  }

  void _toggleTag(String id, bool selected) {
    setState(() {
      if (selected) {
        _selectedTagIds.add(id);
      } else {
        _selectedTagIds.remove(id);
      }
    });
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
      applicationIds: _sortedIds(_selectedApplicationIds),
      indicatorIds: _sortedIds(_selectedIndicatorIds),
      tagIds: _sortedIds(_selectedTagIds),
      mine: _mine,
    );
  }

  void _clearFilters() {
    setState(() {
      _pageController.text = '1';
      _limitController.text = '20';
      _selectedType = null;
      _selectedStatus = null;
      _mine = false;
      _selectedApplicationIds.clear();
      _selectedIndicatorIds.clear();
      _selectedTagIds.clear();
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

  List<String> _sortedIds(Set<String> values) {
    final list = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);

    final sorted = List<String>.from(list)..sort();
    return sorted;
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
