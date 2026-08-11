import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../discussion_messages/domain/entities/discussion_message.dart';
import '../../../discussion_messages/presentation/bloc/discussion_message_bloc.dart';
import '../../../discussion_messages/presentation/bloc/discussion_message_event.dart';
import '../../../discussion_messages/presentation/bloc/discussion_message_state.dart';
import '../../domain/entities/discussion.dart';
import '../bloc/discussion_bloc.dart';
import '../bloc/discussion_event.dart';
import '../bloc/discussion_state.dart';

enum _SubmitFlowStage {
  idle,
  creatingDiscussion,
  creatingInitialMessage,
  updatingDiscussion,
}

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
  final TextEditingController _applicationIdsController =
      TextEditingController();
  final TextEditingController _indicatorIdsController = TextEditingController();
  final TextEditingController _tagIdsController = TextEditingController();

  DiscussionType _selectedType = DiscussionType.idea;
  DiscussionRecordStatus _status = DiscussionRecordStatus.newDiscussion;
  bool _submitInProgress = false;
  _SubmitFlowStage _submitFlowStage = _SubmitFlowStage.idle;
  String? _pendingInitialMessage;

  @override
  void initState() {
    super.initState();

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
    _applicationIdsController.dispose();
    _indicatorIdsController.dispose();
    _tagIdsController.dispose();
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
          BlocListener<DiscussionMessageBloc, DiscussionMessageState>(
            listener: _onDiscussionMessageStateChanged,
          ),
        ],
        child: BlocBuilder<DiscussionBloc, DiscussionState>(
          builder: (context, state) {
            final messageState = context.watch<DiscussionMessageBloc>().state;
            final isLoading = state.status == DiscussionStatus.loading;
            final isBusy =
                isLoading ||
                _submitInProgress ||
                messageState.isSending ||
                messageState.isUpdating;

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
      _pendingInitialMessage = null;
      _showMessage(state.errorMessage);
      return;
    }

    if (state.status != DiscussionStatus.success || !_submitInProgress) {
      return;
    }

    if (_submitFlowStage == _SubmitFlowStage.updatingDiscussion) {
      _finishSubmitWithSuccess();
      return;
    }

    if (_submitFlowStage != _SubmitFlowStage.creatingDiscussion) {
      return;
    }

    final created = state.selectedDiscussion;
    final createdId = created?.id?.trim();
    if (createdId == null || createdId.isEmpty) {
      _submitInProgress = false;
      _submitFlowStage = _SubmitFlowStage.idle;
      _pendingInitialMessage = null;
      _showMessage(
        'La discussion se creo sin id valido. No se pudo crear el mensaje inicial.',
      );
      return;
    }

    final initialMessage = _pendingInitialMessage?.trim();
    if (initialMessage == null || initialMessage.isEmpty) {
      _finishSubmitWithSuccess();
      return;
    }

    _submitFlowStage = _SubmitFlowStage.creatingInitialMessage;
    context.read<DiscussionMessageBloc>().add(
      CreateDiscussionMessageEvent(
        discussionId: createdId,
        type: DiscussionMessageType.text,
        content: initialMessage,
      ),
    );
  }

  void _onDiscussionMessageStateChanged(
    BuildContext context,
    DiscussionMessageState state,
  ) {
    if (_submitFlowStage != _SubmitFlowStage.creatingInitialMessage) {
      return;
    }

    if (state.status == DiscussionMessageStatus.error &&
        state.errorMessage.isNotEmpty &&
        !state.isSending) {
      _submitInProgress = false;
      _submitFlowStage = _SubmitFlowStage.idle;
      _showMessage(
        'La discussion se creo, pero fallo el mensaje inicial: ${state.errorMessage}',
      );
      return;
    }

    if (!state.isSending && state.status == DiscussionMessageStatus.success) {
      _finishSubmitWithSuccess();
    }
  }

  bool get _isEditing => _idController.text.trim().isNotEmpty;

  void _finishSubmitWithSuccess() {
    _submitInProgress = false;
    _submitFlowStage = _SubmitFlowStage.idle;
    _pendingInitialMessage = null;

    _showMessage('Discussion guardada correctamente.');
    Navigator.pop(context, true);
  }

  void _applyDiscussion(Discussion discussion) {
    _idController.text = discussion.id ?? '';
    _titleController.text = discussion.title;
    _applicationIdsController.text = discussion.resolvedApplicationIds.join(
      ',',
    );
    _indicatorIdsController.text = discussion.resolvedIndicatorIds.join(',');
    _tagIdsController.text = discussion.resolvedTagIds.join(',');

    setState(() {
      _selectedType = discussion.type == DiscussionType.unknown
          ? DiscussionType.idea
          : discussion.type;
      _status = discussion.status == DiscussionRecordStatus.unknown
          ? DiscussionRecordStatus.newDiscussion
          : discussion.status;
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
      status: _status,
      applicationIds: _parseCsvIds(_applicationIdsController.text),
      indicatorIds: _parseCsvIds(_indicatorIdsController.text),
      tagIds: _parseCsvIds(_tagIdsController.text),
    );

    _submitInProgress = true;
    _pendingInitialMessage = isEditing ? null : initialMessage;
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

  String? _nullableText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  List<String> _parseCsvIds(String value) {
    return value
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
