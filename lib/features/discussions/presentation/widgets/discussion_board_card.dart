import 'package:flutter/material.dart';

import '../../domain/entities/discussion.dart';

class DiscussionBoardCard extends StatelessWidget {
  const DiscussionBoardCard({
    required this.discussion,
    required this.isDeveloper,
    required this.isBusy,
    required this.onOpen,
    required this.onManageAssignments,
    required this.onAssignToMe,
    required this.onChangeStatus,
    super.key,
  });

  final Discussion discussion;
  final bool isDeveloper;
  final bool isBusy;
  final VoidCallback onOpen;
  final VoidCallback onManageAssignments;
  final VoidCallback onAssignToMe;
  final void Function(DiscussionRecordStatus status) onChangeStatus;

  @override
  Widget build(BuildContext context) {
    final title = discussion.title.trim().isEmpty
        ? '(Sin titulo)'
        : discussion.title.trim();
    final theme = Theme.of(context);
    final unreadCardColor = discussion.isUnread
        ? Color.lerp(
            theme.colorScheme.surface,
            theme.colorScheme.primaryContainer,
            0.32,
          )
        : null;

    return Card(
      color: unreadCardColor,
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (discussion.isUnread)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.brightness_1,
                        size: 10,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      title,
                      style: (discussion.isUnread
                              ? Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                )
                              : Theme.of(context).textTheme.titleSmall),
                    ),
                  ),
                  if (discussion.isUnread)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Nuevo',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  Chip(label: Text('Tipo: ${discussion.type.apiValue}')),
                  Chip(label: Text('Estado: ${discussion.status.apiValue}')),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Apps: ${discussion.applications.length} | Indicators: ${discussion.indicators.length}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Creador: ${_creatorLabel(discussion)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Asignados',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 4),
              if (discussion.assignedDevelopers.isEmpty)
                Text(
                  'Sin asignar',
                  style: Theme.of(context).textTheme.bodySmall,
                )
              else
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: discussion.assignedDevelopers
                      .map((developer) => Chip(label: Text(developer.fullName)))
                      .toList(growable: false),
                ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: isBusy ? null : onOpen,
                    child: const Text('Detalle'),
                  ),
                  if (isDeveloper)
                    OutlinedButton(
                      onPressed: isBusy ? null : onAssignToMe,
                      child: const Text('Asignarme'),
                    ),
                  if (isDeveloper)
                    OutlinedButton(
                      onPressed: isBusy ? null : onManageAssignments,
                      child: const Text('Asignar developers'),
                    ),
                ],
              ),
              if (isDeveloper) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<DiscussionRecordStatus>(
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
                  onChanged: isBusy
                      ? null
                      : (status) {
                          if (status == null || status == discussion.status) {
                            return;
                          }
                          onChangeStatus(status);
                        },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _creatorLabel(Discussion discussion) {
    final creator = discussion.createdBy;
    if (creator == null) {
      return '-';
    }

    final fullName = creator.fullName?.trim();
    if (fullName != null && fullName.isNotEmpty) {
      return fullName;
    }

    return creator.id;
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
}
