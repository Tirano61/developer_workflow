import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class DiscussionVideoMessage extends StatefulWidget {
  const DiscussionVideoMessage({
    required this.fileUrl,
    required this.caption,
    this.onOpenExternally,
    super.key,
  });

  final String? fileUrl;
  final String caption;
  final VoidCallback? onOpenExternally;

  @override
  State<DiscussionVideoMessage> createState() => _DiscussionVideoMessageState();
}

class _DiscussionVideoMessageState extends State<DiscussionVideoMessage> {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    final url = widget.fileUrl?.trim();
    if (url == null || url.isEmpty) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    final controller = VideoPlayerController.networkUrl(uri);

    try {
      await controller.initialize();
      await controller.setLooping(false);
      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _isLoading = false;
        _hasError = false;
      });
    } catch (_) {
      controller.dispose();
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _togglePlayback(VideoPlayerController controller) async {
    if (controller.value.isPlaying) {
      await controller.pause();
      return;
    }

    await controller.play();
  }

  @override
  Widget build(BuildContext context) {
    final caption = widget.caption.trim();

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
          child: _buildVideoContent(context),
        ),
        if (caption.isNotEmpty) ...[const SizedBox(height: 8), Text(caption)],
      ],
    );
  }

  Widget _buildVideoContent(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 210,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_hasError || _controller == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('No se pudo reproducir el video'),
          if (widget.onOpenExternally != null)
            TextButton.icon(
              onPressed: widget.onOpenExternally,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Abrir externamente'),
            ),
        ],
      );
    }

    final controller = _controller!;

    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final aspectRatio = value.aspectRatio > 0 ? value.aspectRatio : 16 / 9;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AspectRatio(
                aspectRatio: aspectRatio,
                child: GestureDetector(
                  onTap: () => _togglePlayback(controller),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      VideoPlayer(controller),
                      if (!value.isPlaying)
                        const Center(
                          child: Icon(
                            Icons.play_circle_fill,
                            size: 56,
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              children: [
                IconButton(
                  tooltip: value.isPlaying ? 'Pausar' : 'Reproducir',
                  onPressed: () => _togglePlayback(controller),
                  icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow),
                ),
                Expanded(
                  child: VideoProgressIndicator(
                    controller,
                    allowScrubbing: true,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
