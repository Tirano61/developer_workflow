import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../../core/router/app_router.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../discussion_messages/domain/entities/discussion_message.dart';
import '../../../discussion_messages/presentation/bloc/discussion_message_bloc.dart';
import '../../../discussion_messages/presentation/bloc/discussion_message_event.dart';
import '../../../discussion_messages/presentation/bloc/discussion_message_state.dart';
import '../../../notifications/presentation/bloc/notification_bloc.dart';
import '../../../notifications/presentation/bloc/notification_event.dart';
import '../../../notifications/presentation/bloc/notification_state.dart';
import '../../domain/entities/discussion.dart';
import '../bloc/discussion_bloc.dart';
import '../bloc/discussion_event.dart';
import '../bloc/discussion_state.dart';
import 'discussion_route_args.dart';
import '../widgets/messages/discussion_audio_message.dart';
import '../widgets/messages/discussion_file_message.dart';
import '../widgets/messages/discussion_image_message.dart';
import '../widgets/messages/discussion_text_message.dart';
import '../widgets/messages/discussion_video_message.dart';

class DiscussionDetailPage extends StatefulWidget {
  const DiscussionDetailPage({
    required this.discussionId,
    this.embedded = false,
    super.key,
  });

  final String discussionId;
  final bool embedded;

  @override
  State<DiscussionDetailPage> createState() => _DiscussionDetailPageState();
}

class _DiscussionDetailPageState extends State<DiscussionDetailPage>
  with RouteAware {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _contentScrollController = ScrollController();

  bool _pendingComposerClear = false;
  bool _pendingAttachmentUpload = false;
  String? _markAsReadRequestedForDiscussionId;
  bool _routeObserverSubscribed = false;
  int _lastKnownMessageCount = 0;
  NotificationBloc? _notificationBloc;

  @override
  void initState() {
    super.initState();
    _lastKnownMessageCount = 0;
    _setActiveDiscussionId(widget.discussionId);
    _loadDiscussion();
    _loadMessages();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _notificationBloc ??= context.read<NotificationBloc>();

    if (_routeObserverSubscribed) {
      return;
    }

    final route = ModalRoute.of(context);
    if (route != null) {
      AppRouter.routeObserver.subscribe(this, route);
      _routeObserverSubscribed = true;
    }
  }

  @override
  void didUpdateWidget(covariant DiscussionDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.discussionId == widget.discussionId) {
      return;
    }

    _setActiveDiscussionId(widget.discussionId);
    _markAsReadRequestedForDiscussionId = null;
    _lastKnownMessageCount = 0;
    _loadDiscussion();
    _loadMessages();
  }

  @override
  void dispose() {
    if (_routeObserverSubscribed) {
      AppRouter.routeObserver.unsubscribe(this);
      _routeObserverSubscribed = false;
    }
    _clearActiveDiscussionId();
    _messageController.dispose();
    _contentScrollController.dispose();
    super.dispose();
  }

  @override
  void didPush() {
    _setActiveDiscussionId(widget.discussionId);
  }

  @override
  void didPopNext() {
    _setActiveDiscussionId(widget.discussionId);
  }

  @override
  void didPushNext() {
    _clearActiveDiscussionId();
  }

  @override
  void didPop() {
    _clearActiveDiscussionId();
  }

  @override
  Widget build(BuildContext context) {
    final content = MultiBlocListener(
        listeners: [
          BlocListener<DiscussionBloc, DiscussionState>(
            listener: _onDiscussionStateChanged,
          ),
          BlocListener<DiscussionMessageBloc, DiscussionMessageState>(
            listener: _onDiscussionMessageStateChanged,
          ),
          BlocListener<NotificationBloc, NotificationState>(
            listenWhen: (previous, current) =>
                previous.refreshRequestVersion != current.refreshRequestVersion,
            listener: _onNotificationRefreshRequested,
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
    );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Discussion Detail')),
      body: content,
    );
  }

  void _loadDiscussion() {
    context.read<DiscussionBloc>().add(
      LoadDiscussionEvent(widget.discussionId),
    );
  }

  void _setActiveDiscussionId(String discussionId) {
    _notificationBloc?.add(
      NotificationActiveDiscussionChangedEvent(discussionId: discussionId),
    );
  }

  void _clearActiveDiscussionId() {
    _notificationBloc?.add(
      const NotificationActiveDiscussionChangedEvent(discussionId: null),
    );
  }

  void _onNotificationRefreshRequested(
    BuildContext context,
    NotificationState state,
  ) {
    final refreshDiscussionId = state.refreshDiscussionId?.trim();
    if (refreshDiscussionId == null || refreshDiscussionId != widget.discussionId) {
      return;
    }

    _refreshDiscussionAndMessages();
  }

  void _onDiscussionStateChanged(BuildContext context, DiscussionState state) {
    if (state.status == DiscussionStatus.error && state.errorMessage.isNotEmpty) {
      _showMessage(state.errorMessage);
    }

    final discussion = _resolveDiscussion(state);
    if (discussion == null || !discussion.isUnread) {
      return;
    }

    if (_markAsReadRequestedForDiscussionId == widget.discussionId) {
      return;
    }

    _markAsReadRequestedForDiscussionId = widget.discussionId;
    context.read<DiscussionBloc>().add(
      MarkDiscussionAsReadEvent(widget.discussionId),
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

  void _refreshDiscussionAndMessages() {
    _loadDiscussion();
    debugPrint(
      '[DISCUSSION] refresh dispatched - ${_timestampNow()} - '
      'discussionId=${widget.discussionId}',
    );
    context.read<DiscussionMessageBloc>().add(
      RefreshDiscussionMessagesEvent(
        discussionId: widget.discussionId,
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

  Future<void> _pickAndSendAttachment() async {
    debugPrint(
      '[ATTACHMENT] button pressed '
      'discussionId=${widget.discussionId} web=$kIsWeb',
    );

    try {
      if (kIsWeb) {
        debugPrint('[ATTACHMENT] web picker opening');
      }

      final selection = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: true,
      );

      if (!mounted || selection == null || selection.files.isEmpty) {
        debugPrint('[ATTACHMENT] picker canceled or empty selection');
        return;
      }

      final picked = selection.files.first;
      final bytes = picked.bytes;
      final rawName = picked.name.trim();
      final fileName = rawName.isNotEmpty ? rawName : 'attachment';
      final inferredMimeType = _inferMimeTypeFromFileName(fileName);

      if (bytes == null || bytes.isEmpty) {
        _showMessage('No se pudo leer el archivo seleccionado.');
        return;
      }

      final type = _inferAttachmentType(
        fileName: fileName,
        mimeType: inferredMimeType,
      );
      final optionalContent = _messageController.text.trim();

      debugPrint(
        '[ATTACHMENT] file selected '
        'name=$fileName mime=${inferredMimeType ?? '-'} size=${bytes.length}',
      );
      debugPrint('[ATTACHMENT] upload started');

      _pendingComposerClear = true;
      _pendingAttachmentUpload = true;
      context.read<DiscussionMessageBloc>().add(
        CreateDiscussionAttachmentMessageEvent(
          discussionId: widget.discussionId,
          type: type,
          fileName: fileName,
          fileBytes: bytes,
          content: optionalContent.isEmpty ? null : optionalContent,
        ),
      );
    } on PlatformException catch (error) {
      debugPrint('[ATTACHMENT] picker error: $error');
      if (mounted) {
        _showMessage('No se pudo abrir el selector de archivos.');
      }
    } catch (error) {
      debugPrint('[ATTACHMENT] unexpected picker error: $error');
      if (mounted) {
        _showMessage('Ocurrio un error al adjuntar el archivo.');
      }
    }
  }

  DiscussionMessageType _inferAttachmentType({
    required String fileName,
    String? mimeType,
  }) {
    final normalizedMime = mimeType?.trim().toLowerCase() ?? '';
    if (normalizedMime.startsWith('image/')) {
      return DiscussionMessageType.image;
    }
    if (normalizedMime.startsWith('audio/')) {
      return DiscussionMessageType.audio;
    }
    if (normalizedMime.startsWith('video/')) {
      return DiscussionMessageType.video;
    }

    final dotIndex = fileName.lastIndexOf('.');
    final extension = dotIndex < 0
        ? ''
        : fileName.substring(dotIndex + 1).toLowerCase();

    const imageExtensions = <String>{
      'png',
      'jpg',
      'jpeg',
      'gif',
      'webp',
      'bmp',
      'heic',
      'heif',
      'svg',
    };

    const audioExtensions = <String>{
      'mp3',
      'wav',
      'm4a',
      'aac',
      'ogg',
      'opus',
      'flac',
      'amr',
    };

    const videoExtensions = <String>{
      'mp4',
      'mov',
      'avi',
      'mkv',
      'webm',
      'm4v',
      '3gp',
    };

    if (imageExtensions.contains(extension)) {
      return DiscussionMessageType.image;
    }

    if (audioExtensions.contains(extension)) {
      return DiscussionMessageType.audio;
    }

    if (videoExtensions.contains(extension)) {
      return DiscussionMessageType.video;
    }

    return DiscussionMessageType.file;
  }

  String? _inferMimeTypeFromFileName(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == fileName.length - 1) {
      return null;
    }

    final extension = fileName.substring(dotIndex + 1).trim().toLowerCase();
    if (extension.isEmpty) {
      return null;
    }

    const mimeByExtension = <String, String>{
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'bmp': 'image/bmp',
      'heic': 'image/heic',
      'heif': 'image/heif',
      'svg': 'image/svg+xml',
      'mp3': 'audio/mpeg',
      'wav': 'audio/wav',
      'm4a': 'audio/mp4',
      'aac': 'audio/aac',
      'ogg': 'audio/ogg',
      'opus': 'audio/opus',
      'flac': 'audio/flac',
      'amr': 'audio/amr',
      'mp4': 'video/mp4',
      'mov': 'video/quicktime',
      'avi': 'video/x-msvideo',
      'mkv': 'video/x-matroska',
      'webm': 'video/webm',
      'm4v': 'video/x-m4v',
      '3gp': 'video/3gpp',
      'pdf': 'application/pdf',
      'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    };

    return mimeByExtension[extension] ?? 'application/octet-stream';
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
    final hasNewMessages = state.messages.length > _lastKnownMessageCount;
    final shouldAutoScrollForIncoming =
        hasNewMessages && _isNearBottomBeforeUpdate();
    _lastKnownMessageCount = state.messages.length;

    if (state.status == DiscussionMessageStatus.error &&
        state.errorMessage.isNotEmpty) {
      if (_pendingAttachmentUpload) {
        debugPrint('[ATTACHMENT] upload failed');
      }
      _pendingAttachmentUpload = false;
      _pendingComposerClear = false;
      _showMessage(state.errorMessage);
      return;
    }

    if (_pendingComposerClear &&
        !state.isSending &&
        state.status == DiscussionMessageStatus.success) {
      if (_pendingAttachmentUpload) {
        debugPrint('[ATTACHMENT] upload completed');
      }
      _pendingAttachmentUpload = false;
      _pendingComposerClear = false;
      _messageController.clear();
      _scheduleScrollToBottom();
      return;
    }

    if (shouldAutoScrollForIncoming && !state.isLoadingMore) {
      _scheduleScrollToBottom();
    }
  }

  bool _isNearBottomBeforeUpdate() {
    if (!_contentScrollController.hasClients) {
      return true;
    }

    final position = _contentScrollController.position;
    return (position.maxScrollExtent - position.pixels) <= 120;
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
                _detailRow('Status', _statusLabel(discussion.status)),
                _detailRow('Created by', _formatCreator(discussion.createdBy)),
                _detailRow('Created at', _formatDate(discussion.createdAt)),
                _detailRow('Updated at', _formatDate(discussion.updatedAt)),
                const SizedBox(height: 12),
                _buildStatusSection(
                  discussion: discussion,
                  isDeveloper: isDeveloper,
                  messageState: messageState,
                ),
                const SizedBox(height: 12),
                _buildAssignmentsSection(
                  discussion: discussion,
                  isDeveloper: isDeveloper,
                ),
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
              messageState.isRefreshing ||
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
            if (!widget.embedded)
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

  Widget _buildStatusSection({
    required Discussion discussion,
    required bool isDeveloper,
    required DiscussionMessageState messageState,
  }) {
    final discussionState = context.watch<DiscussionBloc>().state;
    final isBusy = discussionState.isUpdatingStatus &&
        discussionState.operationDiscussionId == discussion.id;

    if (!isDeveloper) {
      return Text('Estado actual: ${_statusLabel(discussion.status)}');
    }

    return DropdownButtonFormField<DiscussionRecordStatus>(
      initialValue: discussion.status,
      decoration: const InputDecoration(
        labelText: 'Estado',
        border: OutlineInputBorder(),
      ),
      items: DiscussionRecordStatus.values
          .where((status) => status != DiscussionRecordStatus.unknown)
          .map(
            (status) => DropdownMenuItem<DiscussionRecordStatus>(
              value: status,
              child: Text(_statusLabel(status)),
            ),
          )
          .toList(growable: false),
      onChanged: isBusy || messageState.isSending
          ? null
          : (status) {
              final discussionId = discussion.id;
              if (status == null || discussionId == null || discussionId.isEmpty) {
                return;
              }

              if (status == discussion.status) {
                return;
              }

              context.read<DiscussionBloc>().add(
                ChangeDiscussionStatusEvent(
                  discussionId: discussionId,
                  status: status,
                ),
              );
            },
    );
  }

  Widget _buildAssignmentsSection({
    required Discussion discussion,
    required bool isDeveloper,
  }) {
    final discussionState = context.watch<DiscussionBloc>().state;
    final isBusy = discussionState.isUpdatingAssignments &&
        discussionState.operationDiscussionId == discussion.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Asignados', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        if (discussion.assignedDevelopers.isEmpty)
          const Text('Sin asignar')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: discussion.assignedDevelopers
                .map((developer) => Chip(label: Text(developer.fullName)))
                .toList(growable: false),
          ),
        const SizedBox(height: 8),
        if (isDeveloper)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: isBusy ? null : () => _openAssignmentsDialog(discussion),
                child: const Text('Asignar developers'),
              ),
              OutlinedButton(
                onPressed: isBusy ? null : () => _assignToMe(discussion),
                child: const Text('Asignarme'),
              ),
            ],
          ),
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
                _buildMessageBody(message),
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

  Widget _buildMessageBody(DiscussionMessage message) {
    switch (message.type) {
      case DiscussionMessageType.text:
        return DiscussionTextMessage(content: message.content);
      case DiscussionMessageType.image:
        return DiscussionImageMessage(
          fileUrl: message.attachmentUrl,
          caption: message.content,
        );
      case DiscussionMessageType.audio:
        return DiscussionAudioMessage(
          fileUrl: message.attachmentUrl,
          caption: message.content,
          onOpenExternally: () => _openAttachmentUrl(message.attachmentUrl),
        );
      case DiscussionMessageType.video:
        return DiscussionVideoMessage(
          fileUrl: message.attachmentUrl,
          caption: message.content,
          onOpenExternally: () => _openAttachmentUrl(message.attachmentUrl),
        );
      case DiscussionMessageType.file:
      case DiscussionMessageType.unknown:
        return DiscussionFileMessage(
          message: message,
          onOpen: () =>
              _openAttachmentUrl(message.attachmentUrl, preferDownload: kIsWeb),
        );
    }
  }

  Future<void> _openAttachmentUrl(
    String? rawUrl, {
    bool preferDownload = false,
  }) async {
    final normalizedUrl = rawUrl?.trim();
    if (normalizedUrl == null || normalizedUrl.isEmpty) {
      _showMessage('No se pudo abrir el archivo.');
      return;
    }

    final uri = Uri.tryParse(normalizedUrl);
    if (uri == null) {
      _showMessage('No se pudo abrir el archivo.');
      return;
    }

    final launchMode = kIsWeb
        ? LaunchMode.platformDefault
        : LaunchMode.externalApplication;
    final launched = await launchUrl(
      uri,
      mode: launchMode,
      webOnlyWindowName: preferDownload ? '_blank' : null,
    );

    if (!launched) {
      _showMessage('No se pudo abrir el archivo.');
    }
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
                      child: OutlinedButton(
                        onPressed: isDisabled ? null : _pickAndSendAttachment,
                        child: const Icon(Icons.attach_file),
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

  String _statusLabel(DiscussionRecordStatus status) {
    switch (status) {
      case DiscussionRecordStatus.newDiscussion:
        return 'Entrada';
      case DiscussionRecordStatus.review:
        return 'Revision';
      case DiscussionRecordStatus.inProgress:
        return 'Trabajando';
      case DiscussionRecordStatus.resolved:
        return 'Resuelto';
      case DiscussionRecordStatus.unknown:
        return 'Desconocido';
    }
  }

  void _assignToMe(Discussion discussion) {
    final discussionId = discussion.id;
    final currentUser = context.read<AuthBloc>().state.session?.user;

    if (discussionId == null || discussionId.isEmpty || currentUser == null) {
      return;
    }

    context.read<DiscussionBloc>().add(
      AssignDiscussionToMeEvent(
        discussionId: discussionId,
        currentDeveloperUserId: currentUser.id,
      ),
    );
  }

  Future<void> _openAssignmentsDialog(Discussion discussion) async {
    final discussionId = discussion.id;
    if (discussionId == null || discussionId.isEmpty) {
      return;
    }

    final bloc = context.read<DiscussionBloc>();
    bloc.add(const LoadAssignableDevelopersEvent());

    final selectedIds = discussion.assignedDevelopers
        .map((developer) => developer.id)
        .toSet();

    final savedIds = await showDialog<Set<String>>(
      context: context,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: bloc,
          child: StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              return AlertDialog(
                title: const Text('Asignar developers'),
                content: SizedBox(
                  width: 420,
                  child: BlocBuilder<DiscussionBloc, DiscussionState>(
                    builder: (context, state) {
                      if (state.isLoadingAssignableDevelopers &&
                          state.assignableDevelopers.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (state.assignableDevelopers.isEmpty) {
                        return const Text('No hay developers disponibles.');
                      }

                      return SingleChildScrollView(
                        child: Column(
                          children: state.assignableDevelopers
                              .map(
                                (developer) => CheckboxListTile(
                                  dense: true,
                                  value: selectedIds.contains(developer.id),
                                  title: Text(developer.fullName),
                                  subtitle: developer.email == null
                                      ? null
                                      : Text(developer.email!),
                                  onChanged: (checked) {
                                    setDialogState(() {
                                      if (checked == true) {
                                        selectedIds.add(developer.id);
                                      } else {
                                        selectedIds.remove(developer.id);
                                      }
                                    });
                                  },
                                ),
                              )
                              .toList(growable: false),
                        ),
                      );
                    },
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(
                      dialogContext,
                      Set<String>.from(selectedIds),
                    ),
                    child: const Text('Guardar'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (!mounted || savedIds == null) {
      return;
    }

    bloc.add(
      ReplaceDiscussionAssignmentsEvent(
        discussionId: discussionId,
        developerUserIds: _sortedIds(savedIds),
      ),
    );
  }

  List<String> _sortedIds(Set<String> ids) {
    final list = ids
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);

    final sorted = List<String>.from(list)..sort();
    return sorted;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _timestampNow() {
    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    final ms = now.millisecond.toString().padLeft(3, '0');
    return '$hh:$mm:$ss.$ms';
  }
}
