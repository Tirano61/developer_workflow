import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/app_router.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../discussion_messages/domain/entities/discussion_message.dart';
import '../../../discussion_messages/presentation/bloc/discussion_message_bloc.dart';
import '../../../discussion_messages/presentation/bloc/discussion_message_event.dart';
import '../../../discussion_messages/presentation/bloc/discussion_message_state.dart';
import '../../domain/entities/discussion.dart';
import '../bloc/discussion_bloc.dart';
import '../bloc/discussion_event.dart';
import '../bloc/discussion_state.dart';
import 'discussion_route_args.dart';

class DiscussionDetailPage extends StatefulWidget {
  const DiscussionDetailPage({required this.discussionId, super.key});

  final String discussionId;

  @override
  State<DiscussionDetailPage> createState() => _DiscussionDetailPageState();
}

class _DiscussionDetailPageState extends State<DiscussionDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _contentScrollController = ScrollController();

  bool _pendingComposerClear = false;

  @override
  void initState() {
    super.initState();
    _loadDiscussion();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _contentScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Discussion Detail')),
      body: MultiBlocListener(
        listeners: [
          BlocListener<DiscussionBloc, DiscussionState>(
            listener: (context, state) {
              if (state.status == DiscussionStatus.error &&
                  state.errorMessage.isNotEmpty) {
                _showMessage(state.errorMessage);
              }
            },
          ),
          BlocListener<DiscussionMessageBloc, DiscussionMessageState>(
            listener: _onDiscussionMessageStateChanged,
          ),
        ],
        child: Column(
          children: [
            Expanded(
              child: BlocBuilder<DiscussionBloc, DiscussionState>(
                builder: (context, discussionState) {
                  final discussion = _resolveDiscussion(discussionState);

                  return BlocBuilder<
                    DiscussionMessageBloc,
                    DiscussionMessageState
                  >(
                    builder: (context, messageState) {
                      if (discussionState.status == DiscussionStatus.loading &&
                          discussion == null) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (discussion == null) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'No se encontraron datos para la discussion.',
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    _loadDiscussion();
                                    _loadMessages();
                                  },
                                  child: const Text('Reintentar'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return _buildDetailContent(
                        discussion: discussion,
                        messageState: messageState,
                      );
                    },
                  );
                },
              ),
            ),
            _buildComposer(),
          ],
        ),
      ),
    );
  }

  void _loadDiscussion() {
    context.read<DiscussionBloc>().add(
      LoadDiscussionEvent(widget.discussionId),
    );
  }

  void _loadMessages({int page = 1}) {
    context.read<DiscussionMessageBloc>().add(
      LoadDiscussionMessagesEvent(
        discussionId: widget.discussionId,
        page: page,
        limit: 50,
      ),
    );
  }

  void _loadMoreMessages(DiscussionMessageState state) {
    if (state.isLoadingMore || !state.page.hasNext) {
      return;
    }

    context.read<DiscussionMessageBloc>().add(
      LoadMoreDiscussionMessagesEvent(
        discussionId: widget.discussionId,
        limit: state.page.limit,
      ),
    );
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) {
      _showMessage('Escribe un mensaje antes de enviar.');
      return;
    }

    _pendingComposerClear = true;
    context.read<DiscussionMessageBloc>().add(
      CreateDiscussionMessageEvent(
        discussionId: widget.discussionId,
        type: DiscussionMessageType.text,
        content: content,
      ),
    );
  }

  Future<void> _editMessage(DiscussionMessage message) async {
    final controller = TextEditingController(text: message.content);

    final newContent = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar mensaje'),
          content: TextField(
            controller: controller,
            minLines: 2,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Contenido',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (!mounted || newContent == null || newContent.isEmpty) {
      return;
    }

    context.read<DiscussionMessageBloc>().add(
      UpdateDiscussionMessageEvent(
        discussionId: widget.discussionId,
        messageId: message.id,
        content: newContent,
      ),
    );
  }

  void _onDiscussionMessageStateChanged(
    BuildContext context,
    DiscussionMessageState state,
  ) {
    if (state.status == DiscussionMessageStatus.error &&
        state.errorMessage.isNotEmpty) {
      _pendingComposerClear = false;
      _showMessage(state.errorMessage);
      return;
    }

    if (_pendingComposerClear &&
        !state.isSending &&
        state.status == DiscussionMessageStatus.success) {
      _pendingComposerClear = false;
      _messageController.clear();
      _scheduleScrollToBottom();
      return;
    }

    if (state.messages.isNotEmpty && !state.isLoadingMore) {
      _scheduleScrollToBottom();
    }
  }

  void _scheduleScrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_contentScrollController.hasClients) {
        return;
      }

      _contentScrollController.animateTo(
        _contentScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _buildDetailContent({
    required Discussion discussion,
    required DiscussionMessageState messageState,
  }) {
    final authState = context.watch<AuthBloc>().state;
    final currentUser = authState.session?.user;
    final currentUserId = currentUser?.id;
    final isDeveloper = currentUser?.isDeveloper ?? false;

    return ListView(
      controller: _contentScrollController,
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('ID', discussion.id ?? '-'),
                _detailRow('Title', discussion.title),
                _detailRow('Type', discussion.type.apiValue),
                _detailRow('Status', discussion.status.apiValue),
                _detailRow('Created by', _formatCreator(discussion.createdBy)),
                _detailRow('Created at', _formatDate(discussion.createdAt)),
                _detailRow('Updated at', _formatDate(discussion.updatedAt)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildTagSection(
          title: 'Applications',
          values: _extractApplicationLabels(discussion),
        ),
        const SizedBox(height: 8),
        _buildTagSection(
          title: 'Indicators',
          values: _extractIndicatorLabels(discussion),
        ),
        const SizedBox(height: 8),
        _buildTagSection(title: 'Tags', values: _extractTagLabels(discussion)),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                'Conversacion (${messageState.messages.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (messageState.status == DiscussionMessageStatus.loading ||
                messageState.isSending ||
                messageState.isUpdating)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (messageState.status == DiscussionMessageStatus.loading &&
            messageState.messages.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (messageState.messages.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('No hay mensajes en esta discussion todavia.'),
          )
        else
          ...messageState.messages.map((message) {
            final isOwnMessage =
                currentUserId != null && message.author.id == currentUserId;
            final canEditMessage = isOwnMessage || isDeveloper;
            final isUpdatingThisMessage =
                messageState.isUpdating &&
                messageState.updatingMessageId == message.id;

            return _buildMessageTile(
              message: message,
              isOwnMessage: isOwnMessage,
              canEditMessage: canEditMessage,
              isUpdatingThisMessage: isUpdatingThisMessage,
            );
          }),
        const SizedBox(height: 12),
        if (messageState.page.hasNext)
          Align(
            alignment: Alignment.center,
            child: OutlinedButton(
              onPressed: messageState.isLoadingMore
                  ? null
                  : () => _loadMoreMessages(messageState),
              child: Text(
                messageState.isLoadingMore
                    ? 'Cargando...'
                    : 'Cargar mas mensajes',
              ),
            ),
          ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton(
              onPressed: () {
                _loadDiscussion();
                _loadMessages(page: 1);
              },
              child: const Text('Recargar'),
            ),
            ElevatedButton(
              onPressed: () async {
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
                  _loadDiscussion();
                  _loadMessages(page: 1);
                }
              },
              child: const Text('Editar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Volver'),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildMessageTile({
    required DiscussionMessage message,
    required bool isOwnMessage,
    required bool canEditMessage,
    required bool isUpdatingThisMessage,
  }) {
    final bubbleColor = isOwnMessage
        ? Theme.of(context).colorScheme.primaryContainer
        : Theme.of(context).colorScheme.surfaceContainerHighest;

    return Align(
      alignment: isOwnMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Card(
          color: bubbleColor,
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '${message.author.displayName} · ${_formatDate(message.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    if (canEditMessage)
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        tooltip: 'Editar mensaje',
                        onPressed: isUpdatingThisMessage
                            ? null
                            : () => _editMessage(message),
                      ),
                  ],
                ),
                Text(message.content),
                if (isUpdatingThisMessage) ...[
                  const SizedBox(height: 8),
                  const LinearProgressIndicator(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComposer() {
    return BlocBuilder<DiscussionBloc, DiscussionState>(
      builder: (context, discussionState) {
        final hasDiscussion = _resolveDiscussion(discussionState) != null;

        return BlocBuilder<DiscussionMessageBloc, DiscussionMessageState>(
          builder: (context, messageState) {
            final isDisabled =
                !hasDiscussion ||
                messageState.isSending ||
                (messageState.status == DiscussionMessageStatus.loading &&
                    messageState.messages.isEmpty);

            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) {
                          if (!isDisabled) {
                            _sendMessage();
                          }
                        },
                        decoration: const InputDecoration(
                          hintText: 'Escribir mensaje...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 48,
                      width: 48,
                      child: ElevatedButton(
                        onPressed: isDisabled ? null : _sendMessage,
                        child: messageState.isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Discussion? _resolveDiscussion(DiscussionState state) {
    final selected = state.selectedDiscussion;
    if (selected != null && selected.id == widget.discussionId) {
      return selected;
    }

    for (final discussion in state.discussions) {
      if (discussion.id == widget.discussionId) {
        return discussion;
      }
    }

    return null;
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text('$label: $value'),
    );
  }

  Widget _buildTagSection({
    required String title,
    required List<String> values,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (values.isEmpty)
              const Text('-')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: values
                    .map((value) => Chip(label: Text(value)))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  List<String> _extractApplicationLabels(Discussion discussion) {
    if (discussion.applications.isNotEmpty) {
      return discussion.applications
          .map((application) {
            final id = application.id ?? '-';
            final name = application.name.trim().isEmpty
                ? '(sin nombre)'
                : application.name;
            return '$name ($id)';
          })
          .toList(growable: false);
    }

    return discussion.resolvedApplicationIds;
  }

  List<String> _extractIndicatorLabels(Discussion discussion) {
    if (discussion.indicators.isNotEmpty) {
      return discussion.indicators
          .map((indicator) {
            final id = indicator.id ?? '-';
            final name = indicator.name.trim().isEmpty
                ? '(sin nombre)'
                : indicator.name;
            return '$name ($id)';
          })
          .toList(growable: false);
    }

    return discussion.resolvedIndicatorIds;
  }

  List<String> _extractTagLabels(Discussion discussion) {
    if (discussion.tags.isNotEmpty) {
      return discussion.tags
          .map((tag) {
            final name = tag.name.trim().isEmpty ? '(sin nombre)' : tag.name;
            return '$name (${tag.id})';
          })
          .toList(growable: false);
    }

    return discussion.resolvedTagIds;
  }

  String _formatCreator(DiscussionCreator? creator) {
    if (creator == null) {
      return '-';
    }

    final name = creator.fullName?.trim();
    final email = creator.email?.trim();
    final id = creator.id;

    if (name != null && name.isNotEmpty && email != null && email.isNotEmpty) {
      return '$name <$email> ($id)';
    }

    if (name != null && name.isNotEmpty) {
      return '$name ($id)';
    }

    if (email != null && email.isNotEmpty) {
      return '$email ($id)';
    }

    return id;
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return '-';
    }

    return value.toLocal().toIso8601String();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
