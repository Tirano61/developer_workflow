import 'package:flutter/material.dart';

import '../../domain/entities/discussion.dart';

class DiscussionListTile extends StatelessWidget {
  const DiscussionListTile({
    required this.discussion,
    required this.onOpenDetail,
    required this.onEdit,
    super.key,
  });

  final Discussion discussion;
  final VoidCallback onOpenDetail;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final title = discussion.title.trim().isEmpty
        ? '(Sin titulo)'
        : discussion.title.trim();

    final subtitle = [
      'Tipo: ${discussion.type.apiValue}',
      'Estado: ${discussion.status.apiValue}',
      'Apps: ${discussion.resolvedApplicationIds.length}',
      'Indicators: ${discussion.resolvedIndicatorIds.length}',
      'Tags: ${discussion.resolvedTagIds.length}',
    ].join(' | ');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'detail') {
              onOpenDetail();
            }
            if (value == 'edit') {
              onEdit();
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem<String>(value: 'detail', child: Text('Ver detalle')),
            PopupMenuItem<String>(value: 'edit', child: Text('Editar')),
          ],
        ),
        onTap: onOpenDetail,
      ),
    );
  }
}
