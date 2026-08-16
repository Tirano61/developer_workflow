import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/app_router.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../notifications/presentation/bloc/notification_state.dart';
import '../../../notifications/presentation/bloc/notification_bloc.dart';
import '../../domain/entities/discussion.dart';
import '../../domain/entities/discussion_filters.dart';
import '../bloc/discussion_bloc.dart';
import '../bloc/discussion_event.dart';
import '../bloc/discussion_state.dart';
import '../widgets/discussion_board_card.dart';
import 'discussion_detail_page.dart';
import 'discussion_route_args.dart';

enum _DiscussionViewFilter { all, mine, assignedToMe }

class DiscussionsPage extends StatefulWidget {
  const DiscussionsPage({super.key});

  @override
  State<DiscussionsPage> createState() => _DiscussionsPageState();
}

class _DiscussionsPageState extends State<DiscussionsPage> {
  static const double _desktopBreakpoint = 980;

  _DiscussionViewFilter _viewFilter = _DiscussionViewFilter.all;
  bool _unreadOnly = false;
  DiscussionRecordStatus _mobileStatus = DiscussionRecordStatus.newDiscussion;
  String? _selectedDiscussionId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _requestDiscussions(forDesktop: _isDesktop(context));
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDeveloper = _isDeveloper(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Develop Workflow'),
        actions: [
          IconButton(
            tooltip: 'Nueva discussion',
            onPressed: () async {
              final changed = await Navigator.pushNamed(
                context,
                AppRoutes.discussionCreate,
              );

              if (!context.mounted) {
                return;
              }

              if (changed == true) {
                _requestDiscussions(forDesktop: _isDesktop(context));
              }
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<NotificationBloc, NotificationState>(
            listenWhen: (previous, current) =>
                previous.notificationEventVersion !=
                current.notificationEventVersion,
            listener: (context, notificationState) {
              if (!_shouldRefreshKanbanForNotification(notificationState)) {
                return;
              }

              _requestDiscussions(
                forDesktop: _isDesktop(context),
                silent: true,
              );
            },
          ),
        ],
        child: BlocConsumer<DiscussionBloc, DiscussionState>(
          listener: (context, state) {
            if (state.errorMessage.isNotEmpty) {
              _showMessage(state.errorMessage);
              context.read<DiscussionBloc>().add(
                const ClearDiscussionOperationMessageEvent(),
              );
            }

            if (state.operationMessage.isNotEmpty) {
              _showMessage(state.operationMessage);
              context.read<DiscussionBloc>().add(
                const ClearDiscussionOperationMessageEvent(),
              );
            }

            final selected = state.selectedDiscussion;
            if (selected?.id != null && selected!.id!.isNotEmpty) {
              setState(() {
                _selectedDiscussionId = selected.id;
              });
            }
          },
          builder: (context, state) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= _desktopBreakpoint;

                if (state.status == DiscussionStatus.loading &&
                    state.discussions.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (isDesktop) {
                  return _buildDesktopBoard(context, state, isDeveloper);
                }

                return _buildMobileBoard(context, state, isDeveloper);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildDesktopBoard(
    BuildContext context,
    DiscussionState state,
    bool isDeveloper,
  ) {
    final grouped = _groupByStatus(state.discussions);

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _buildBoardTopBar(context, isDeveloper: isDeveloper),
              if (state.status == DiscussionStatus.loading)
                const LinearProgressIndicator(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      _buildKanbanColumn(
                        context,
                        title: 'Entrada',
                        status: DiscussionRecordStatus.newDiscussion,
                        items:
                            grouped[DiscussionRecordStatus.newDiscussion] ??
                            const <Discussion>[],
                        isDeveloper: isDeveloper,
                        state: state,
                      ),
                      _buildKanbanColumn(
                        context,
                        title: 'Revision',
                        status: DiscussionRecordStatus.review,
                        items: grouped[DiscussionRecordStatus.review] ??
                            const <Discussion>[],
                        isDeveloper: isDeveloper,
                        state: state,
                      ),
                      _buildKanbanColumn(
                        context,
                        title: 'Trabajando',
                        status: DiscussionRecordStatus.inProgress,
                        items:
                            grouped[DiscussionRecordStatus.inProgress] ??
                            const <Discussion>[],
                        isDeveloper: isDeveloper,
                        state: state,
                      ),
                      _buildKanbanColumn(
                        context,
                        title: 'Resuelto',
                        status: DiscussionRecordStatus.resolved,
                        items: grouped[DiscussionRecordStatus.resolved] ??
                            const <Discussion>[],
                        isDeveloper: isDeveloper,
                        state: state,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(width: 1, color: Theme.of(context).dividerColor),
        Expanded(
          flex: 2,
          child: _selectedDiscussionId == null
              ? const Center(child: Text('Selecciona una discussion'))
              : DiscussionDetailPage(
                  discussionId: _selectedDiscussionId!,
                  embedded: true,
                ),
        ),
      ],
    );
  }

  Widget _buildKanbanColumn(
    BuildContext context, {
    required String title,
    required DiscussionRecordStatus status,
    required List<Discussion> items,
    required bool isDeveloper,
    required DiscussionState state,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  '$title (${items.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: items.isEmpty
                    ? const Center(child: Text('Sin discussions'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final discussion = items[index];
                          return DiscussionBoardCard(
                            discussion: discussion,
                            isDeveloper: isDeveloper,
                            isBusy: _isDiscussionBusy(state, discussion.id),
                            onOpen: () => _openDiscussionFromBoard(
                              discussionId: discussion.id,
                              desktopSelection: true,
                            ),
                            onManageAssignments: () =>
                                _openAssignmentsDialog(discussion),
                            onAssignToMe: () => _assignToMe(discussion),
                            onChangeStatus: (nextStatus) =>
                                _changeDiscussionStatus(discussion, nextStatus),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileBoard(
    BuildContext context,
    DiscussionState state,
    bool isDeveloper,
  ) {
    return Column(
      children: [
        _buildBoardTopBar(context, isDeveloper: isDeveloper),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: DropdownButtonFormField<DiscussionRecordStatus>(
            initialValue: _mobileStatus,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Estado',
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
            onChanged: (status) {
              if (status == null) {
                return;
              }

              setState(() {
                _mobileStatus = status;
              });

              _requestDiscussions(forDesktop: false);
            },
          ),
        ),
        if (state.status == DiscussionStatus.loading)
          const LinearProgressIndicator(),
        Expanded(
          child: state.discussions.isEmpty
              ? const Center(child: Text('Sin discussions para este estado.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: state.discussions.length,
                  itemBuilder: (context, index) {
                    final discussion = state.discussions[index];
                    return DiscussionBoardCard(
                      discussion: discussion,
                      isDeveloper: isDeveloper,
                      isBusy: _isDiscussionBusy(state, discussion.id),
                      onOpen: () => _openDiscussionFromBoard(
                        discussionId: discussion.id,
                        desktopSelection: false,
                      ),
                      onManageAssignments: () => _openAssignmentsDialog(discussion),
                      onAssignToMe: () => _assignToMe(discussion),
                      onChangeStatus: (nextStatus) =>
                          _changeDiscussionStatus(discussion, nextStatus),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildBoardTopBar(
    BuildContext context, {
    required bool isDeveloper,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Todas'),
                    selected: _viewFilter == _DiscussionViewFilter.all,
                    onSelected: (_) => _setViewFilter(_DiscussionViewFilter.all),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Creadas por mi'),
                    selected: _viewFilter == _DiscussionViewFilter.mine,
                    onSelected: (_) => _setViewFilter(_DiscussionViewFilter.mine),
                  ),
                  if (isDeveloper) ...[
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Asignadas a mi'),
                      selected: _viewFilter == _DiscussionViewFilter.assignedToMe,
                      onSelected: (_) =>
                          _setViewFilter(_DiscussionViewFilter.assignedToMe),
                    ),
                  ],
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('No leidas'),
                    selected: _unreadOnly,
                    onSelected: (selected) {
                      setState(() {
                        _unreadOnly = selected;
                      });
                      _requestDiscussions(forDesktop: _isDesktop(context));
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Recargar',
            onPressed: () => _requestDiscussions(forDesktop: _isDesktop(context)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }

  void _setViewFilter(_DiscussionViewFilter filter) {
    if (_viewFilter == filter) {
      return;
    }

    setState(() {
      _viewFilter = filter;
    });

    _requestDiscussions(forDesktop: _isDesktop(context));
  }

  void _requestDiscussions({required bool forDesktop, bool silent = false}) {
    final filters = _buildFilters(forDesktop: forDesktop);
    context.read<DiscussionBloc>().add(
      LoadDiscussionsEvent(filters: filters, silent: silent),
    );
  }

  bool _shouldRefreshKanbanForNotification(NotificationState state) {
    const supportedTypes = <String>{
      'DISCUSSION_CREATED',
      'DISCUSSION_MESSAGE',
      'DISCUSSION_STATUS_CHANGED',
      'DISCUSSION_ASSIGNMENT_CHANGED',
    };

    final type = state.lastNotificationType.trim();
    if (type.isEmpty || !supportedTypes.contains(type)) {
      return false;
    }

    return true;
  }

  DiscussionFilters _buildFilters({required bool forDesktop}) {
    final statusFilter = forDesktop ? null : _mobileStatus;

    return DiscussionFilters(
      page: 1,
      limit: 100,
      status: statusFilter,
      mine: _viewFilter == _DiscussionViewFilter.mine,
      assignedToMe: _viewFilter == _DiscussionViewFilter.assignedToMe,
      unread: _unreadOnly ? true : null,
    );
  }

  Map<DiscussionRecordStatus, List<Discussion>> _groupByStatus(
    List<Discussion> discussions,
  ) {
    final grouped = <DiscussionRecordStatus, List<Discussion>>{
      DiscussionRecordStatus.newDiscussion: <Discussion>[],
      DiscussionRecordStatus.review: <Discussion>[],
      DiscussionRecordStatus.inProgress: <Discussion>[],
      DiscussionRecordStatus.resolved: <Discussion>[],
    };

    for (final discussion in discussions) {
      final status = discussion.status;
      if (!grouped.containsKey(status)) {
        continue;
      }
      grouped[status]!.add(discussion);
    }

    return grouped;
  }

  bool _isDeveloper(BuildContext context) {
    final user = context.read<AuthBloc>().state.session?.user;
    return user?.isDeveloper ?? false;
  }

  bool _isDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= _desktopBreakpoint;
  }

  bool _isDiscussionBusy(DiscussionState state, String? discussionId) {
    if (discussionId == null || discussionId.isEmpty) {
      return false;
    }

    return state.operationDiscussionId == discussionId &&
        (state.isUpdatingAssignments || state.isUpdatingStatus);
  }

  Future<void> _openDiscussionFromBoard({
    required String? discussionId,
    required bool desktopSelection,
  }) async {
    if (discussionId == null || discussionId.isEmpty) {
      return;
    }

    context.read<DiscussionBloc>().add(MarkDiscussionAsReadEvent(discussionId));

    if (desktopSelection) {
      setState(() {
        _selectedDiscussionId = discussionId;
      });
      context.read<DiscussionBloc>().add(SelectDiscussionEvent(discussionId));
      context.read<DiscussionBloc>().add(LoadDiscussionEvent(discussionId));
      return;
    }

    final changed = await Navigator.pushNamed(
      context,
      AppRoutes.discussionDetail,
      arguments: DiscussionDetailRouteArgs(discussionId: discussionId),
    );

    if (!mounted) {
      return;
    }

    if (changed == true) {
      _requestDiscussions(forDesktop: false);
    }
  }

  void _changeDiscussionStatus(
    Discussion discussion,
    DiscussionRecordStatus nextStatus,
  ) {
    final discussionId = discussion.id;
    if (discussionId == null || discussionId.isEmpty) {
      return;
    }

    context.read<DiscussionBloc>().add(
      ChangeDiscussionStatusEvent(discussionId: discussionId, status: nextStatus),
    );
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
