import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../discussion_messages/domain/entities/discussion_message.dart';
import 'discussion_attachment_helpers.dart';

class DiscussionFileMessage extends StatelessWidget {
  const DiscussionFileMessage({
    required this.message,
    required this.onOpen,
    super.key,
  });

  final DiscussionMessage message;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final hasUrl = (message.attachmentUrl?.trim().isNotEmpty ?? false);
    final displayName = resolveAttachmentDisplayName(message);
    final sizeLabel = formatFileSize(message.attachmentSizeBytes);
    final mime = message.attachmentMimeType?.trim();
    final details = <String>[
      if (mime != null && mime.isNotEmpty) mime,
      if (sizeLabel != '-') sizeLabel,
    ];
    final caption = message.content.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(resolveAttachmentIcon(message)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName, overflow: TextOverflow.ellipsis),
                    if (details.isNotEmpty)
                      Text(
                        details.join(' · '),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              if (hasUrl)
                TextButton.icon(
                  onPressed: onOpen,
                  icon: Icon(
                    kIsWeb ? Icons.download_outlined : Icons.open_in_new,
                  ),
                  label: Text(kIsWeb ? 'Descargar' : 'Abrir'),
                )
              else
                const Text('Sin URL'),
            ],
          ),
        ),
        if (caption.isNotEmpty) ...[const SizedBox(height: 8), Text(caption)],
      ],
    );
  }
}
