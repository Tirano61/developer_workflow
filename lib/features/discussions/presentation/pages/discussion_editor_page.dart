import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
import '../bloc/discussion_bloc.dart';
import '../bloc/discussion_event.dart';
import '../bloc/discussion_state.dart';

enum _SubmitFlowStage { idle, creatingDiscussion, updatingDiscussion }

class DiscussionEditorPage extends StatefulWidget {
  const DiscussionEditorPage({
    this.initialDiscussion,
    this.discussionId,
    super.key,
  });

  final Discussion? initialDiscussion;
  final String? discussionId;

  @override
  State<DiscussionEditorPage> createState() => _DiscussionEditorPageState();
}

class _DiscussionEditorPageState extends State<DiscussionEditorPage> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _initialMessageController =
      TextEditingController();

  final Set<String> _selectedApplicationIds = <String>{};
  final Set<String> _selectedIndicatorIds = <String>{};
  final Set<String> _selectedTagIds = <String>{};

  DiscussionType _selectedType = DiscussionType.idea;
  DiscussionRecordStatus _status = DiscussionRecordStatus.newDiscussion;
  bool _submitInProgress = false;
  _SubmitFlowStage _submitFlowStage = _SubmitFlowStage.idle;

  @override
  void initState() {
    super.initState();

    context.read<ApplicationBloc>().add(const LoadApplicationsEvent());
    context.read<IndicatorBloc>().add(const LoadIndicatorsEvent());
    context.read<TagBloc>().add(const LoadTagsEvent());

    final initial = widget.initialDiscussion;
    if (initial != null) {
      _applyDiscussion(initial);
      return;
    }

    final id = widget.discussionId?.trim();
    if (id != null && id.isNotEmpty) {
      context.read<DiscussionBloc>().add(LoadDiscussionEvent(id));
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _titleController.dispose();
    _initialMessageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Discussion' : 'Nueva Discussion'),
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<DiscussionBloc, DiscussionState>(
            listener: _onDiscussionStateChanged,
          ),
        ],
        child: BlocBuilder<DiscussionBloc, DiscussionState>(
          builder: (context, state) {
            final applicationState = context.watch<ApplicationBloc>().state;
            final indicatorState = context.watch<IndicatorBloc>().state;
            final tagState = context.watch<TagBloc>().state;

            final isLoading = state.status == DiscussionStatus.loading;
            final isBusy = isLoading || _submitInProgress;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
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
                  controller: _titleController,
                  maxLength: 150,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                    helperText: 'Requerido. Maximo 150 caracteres.',
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<DiscussionType>(
                  key: ValueKey<DiscussionType>(_selectedType),
                  initialValue: _selectedType,
                  items: DiscussionType.values
                      .where((type) => type != DiscussionType.unknown)
                      .map(
                        (type) => DropdownMenuItem<DiscussionType>(
                          value: type,
                          child: Text(type.apiValue),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _selectedType = value;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Status (solo lectura en esta fase)',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(_status.apiValue),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Usuario creador: se toma automaticamente del usuario autenticado.',
                ),
                const SizedBox(height: 12),
                _buildMultiSelectSection<Application>(
                  title: 'Applications',
                  subtitle: 'Selecciona una o varias applications.',
                  items: applicationState.applications,
                  selectedIds: _selectedApplicationIds,
                  isLoading:
                      applicationState.status == ApplicationStatus.loading,
                  errorMessage:
                      applicationState.status == ApplicationStatus.error
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
                  title: 'Indicators',
                  subtitle: 'Selecciona uno o varios indicators.',
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
                  title: 'Tags',
                  subtitle: 'Selecciona tags para clasificar la discussion.',
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
                if (!_isEditing) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _initialMessageController,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Mensaje inicial (TEXT)',
                      hintText:
                          'Describe el caso para iniciar la conversacion.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                if (isBusy)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: LinearProgressIndicator(),
                  ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: isBusy ? null : _saveDiscussion,
                      child: Text(
                        _isEditing ? 'Actualizar (PATCH)' : 'Crear (POST)',
                      ),
                    ),
                    OutlinedButton(
                      onPressed: isBusy
                          ? null
                          : () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                  ],
                ),
              ],
            );
          },
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

  void _onDiscussionStateChanged(BuildContext context, DiscussionState state) {
    final selected = state.selectedDiscussion;
    if (selected != null) {
      final selectedId = selected.id;
      final expectedId = widget.initialDiscussion?.id ?? widget.discussionId;
      final isExpectedSelection =
          expectedId == null ||
          expectedId.trim().isEmpty ||
          selectedId == expectedId ||
          _submitInProgress;

      if (isExpectedSelection) {
        _applyDiscussion(selected);
      }
    }

    if (state.status == DiscussionStatus.error &&
        state.errorMessage.isNotEmpty) {
      _submitInProgress = false;
      _submitFlowStage = _SubmitFlowStage.idle;
      _showMessage(state.errorMessage);
      return;
    }

    if (state.status != DiscussionStatus.success || !_submitInProgress) {
      return;
    }

    if (_submitFlowStage != _SubmitFlowStage.creatingDiscussion &&
        _submitFlowStage != _SubmitFlowStage.updatingDiscussion) {
      return;
    }

    _finishSubmitWithSuccess();
  }

  bool get _isEditing => _idController.text.trim().isNotEmpty;

  void _finishSubmitWithSuccess() {
    _submitInProgress = false;
    _submitFlowStage = _SubmitFlowStage.idle;

    _showMessage('Discussion guardada correctamente.');
    Navigator.pop(context, true);
  }

  void _applyDiscussion(Discussion discussion) {
    _idController.text = discussion.id ?? '';
    _titleController.text = discussion.title;

    setState(() {
      _selectedType = discussion.type == DiscussionType.unknown
          ? DiscussionType.idea
          : discussion.type;
      _status = discussion.status == DiscussionRecordStatus.unknown
          ? DiscussionRecordStatus.newDiscussion
          : discussion.status;

      _selectedApplicationIds
        ..clear()
        ..addAll(discussion.resolvedApplicationIds);
      _selectedIndicatorIds
        ..clear()
        ..addAll(discussion.resolvedIndicatorIds);
      _selectedTagIds
        ..clear()
        ..addAll(discussion.resolvedTagIds);
    });
  }

  void _saveDiscussion() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showMessage('El title es obligatorio.');
      return;
    }

    final isEditing = _isEditing;
    final initialMessage = _initialMessageController.text.trim();
    if (!isEditing && initialMessage.isEmpty) {
      _showMessage('El mensaje inicial es obligatorio.');
      return;
    }

    final discussion = Discussion(
      id: _nullableText(_idController.text),
      type: _selectedType,
      title: title,
      initialMessageContent: isEditing ? null : initialMessage,
      status: _status,
      applicationIds: _sortedIds(_selectedApplicationIds),
      indicatorIds: _sortedIds(_selectedIndicatorIds),
      tagIds: _sortedIds(_selectedTagIds),
    );

    _submitInProgress = true;
    _submitFlowStage = isEditing
        ? _SubmitFlowStage.updatingDiscussion
        : _SubmitFlowStage.creatingDiscussion;

    final bloc = context.read<DiscussionBloc>();
    if (!isEditing) {
      bloc.add(CreateDiscussionEvent(discussion));
      return;
    }

    bloc.add(UpdateDiscussionEvent(discussion));
  }

  List<String> _sortedIds(Set<String> values) {
    final list = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);

    final sorted = List<String>.from(list)..sort();
    return sorted;
  }

  String? _nullableText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
