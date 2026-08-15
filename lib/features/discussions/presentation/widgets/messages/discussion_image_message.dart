import 'package:flutter/material.dart';

class DiscussionImageMessage extends StatelessWidget {
  const DiscussionImageMessage({
    required this.fileUrl,
    required this.caption,
    super.key,
  });

  final String? fileUrl;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final url = fileUrl?.trim();
    final hasUrl = url != null && url.isNotEmpty;
    final trimmedCaption = caption.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasUrl)
          LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth.clamp(140.0, 280.0);
              return GestureDetector(
                onTap: () => _openImageViewer(context, url),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: maxWidth,
                    height: 180,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Theme.of(context).colorScheme.surface,
                              alignment: Alignment.center,
                              padding: const EdgeInsets.all(12),
                              child: const Text('No se pudo cargar la imagen'),
                            );
                          },
                        ),
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(
                                Icons.zoom_out_map,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          )
        else
          const Text('Imagen adjunta sin URL disponible.'),
        if (trimmedCaption.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(trimmedCaption),
        ],
      ],
    );
  }

  void _openImageViewer(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) {
        final size = MediaQuery.sizeOf(context);

        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          backgroundColor: Colors.black,
          child: SizedBox(
            width: size.width * 0.9,
            height: size.height * 0.9,
            child: Stack(
              children: [
                Positioned.fill(
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 5,
                    child: Center(
                      child: Image.network(
                        url,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              'No se pudo cargar la imagen',
                              style: TextStyle(color: Colors.white),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
