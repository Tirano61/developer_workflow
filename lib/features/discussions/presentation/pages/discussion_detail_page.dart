import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/app_router.dart';
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
  @override
  void initState() {
    super.initState();
    _loadDiscussion();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Discussion Detail')),
      body: BlocConsumer<DiscussionBloc, DiscussionState>(
        listener: (context, state) {
          if (state.status == DiscussionStatus.error &&
              state.errorMessage.isNotEmpty) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errorMessage)));
          }
        },
        builder: (context, state) {
          final discussion = _resolveDiscussion(state);

          if (state.status == DiscussionStatus.loading && discussion == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (discussion == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No se encontraron datos para la discussion.'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _loadDiscussion,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
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
                      _detailRow(
                        'Created by',
                        _formatCreator(discussion.createdBy),
                      ),
                      _detailRow(
                        'Created at',
                        _formatDate(discussion.createdAt),
                      ),
                      _detailRow(
                        'Updated at',
                        _formatDate(discussion.updatedAt),
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
              _buildTagSection(
                title: 'Tags',
                values: _extractTagLabels(discussion),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: _loadDiscussion,
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
            ],
          );
        },
      ),
    );
  }

  void _loadDiscussion() {
    context.read<DiscussionBloc>().add(
      LoadDiscussionEvent(widget.discussionId),
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
}
