// REMOVE this import:
// import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// ===== Image Grid Screen =====
class ImageGridScreen extends StatelessWidget {
  final List<String> imageUrls;
  final String title;
  final int? crossAxisCount; // If null, we compute based on width
  final double spacing;
  final double borderRadius;

  const ImageGridScreen({
    Key? key,
    required this.imageUrls,
    this.title = 'Images',
    this.crossAxisCount,
    this.spacing = 8,
    this.borderRadius = 12,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // Compute a nice column count if not provided (170–200px tiles)
    final computedCols = (width / 180).floor().clamp(2, 6);
    final cols = crossAxisCount ?? computedCols;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: imageUrls.isEmpty
          ? const Center(child: Text('No images to display', style: TextStyle(fontSize: 16)))
          : Padding(
        padding: EdgeInsets.all(spacing),
        child: GridView.builder(
          itemCount: imageUrls.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: 1, // square tiles
          ),
          itemBuilder: (context, index) {
            final url = imageUrls[index];
            return _ImageTile(
              url: url,
              borderRadius: borderRadius,
              heroTag: 'img-$index-$url',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FullScreenGallery(
                      imageUrls: imageUrls,
                      initialIndex: index,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// Single grid tile with rounded corners, loader, error state, and Hero
class _ImageTile extends StatelessWidget {
  final String url;
  final double borderRadius;
  final String heroTag;
  final VoidCallback onTap;

  const _ImageTile({
    Key? key,
    required this.url,
    required this.borderRadius,
    required this.heroTag,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPrint('[_ImageTile] Loading image: $url');
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: onTap,
        child: Hero(
          tag: heroTag,
          child: Image.network(
            url,
            fit: BoxFit.cover,
            // Show a simple skeleton until first frame arrives
            frameBuilder: (context, child, frame, _) {
              if (frame != null) {
                debugPrint('[_ImageTile] Frame loaded for: $url');
                return child;
              }
              return Container(
                color: Colors.grey.shade200,
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            },
            // Show byte progress while downloading
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              final total = progress.expectedTotalBytes;
              final loaded = progress.cumulativeBytesLoaded;
              final value = (total != null) ? loaded / total : null;
              return Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: Colors.grey.shade200),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(value: value, strokeWidth: 2),
                        if (value != null) ...[
                          const SizedBox(height: 8),
                          Text('${(value * 100).toStringAsFixed(0)}%'),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
            // Graceful error
            errorBuilder: (context, error, stackTrace) {
              debugPrint('[_ImageTile] ERROR loading $url — $error');
              return Container(
                color: Colors.grey.shade200,
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image_outlined, size: 36, color: Colors.grey),
              );
            },
            // Optional: downsample thumbnails to save memory/CPU
            cacheWidth: 512,
            cacheHeight: 512,
          ),
        ),
      ),
    );
  }
}

// ===== Full-screen swipeable + pinch-to-zoom gallery =====
class FullScreenGallery extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const FullScreenGallery({
    Key? key,
    required this.imageUrls,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<FullScreenGallery> {
  late final PageController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.imageUrls;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Preview'),
      ),
      body: PageView.builder(
        controller: _ctrl,
        itemCount: urls.length,
        itemBuilder: (context, index) {
          final url = urls[index];
          final heroTag = 'img-$index-$url';
          return InteractiveViewer(
            minScale: 0.8,
            maxScale: 4.0,
            child: Center(
              child: Hero(
                tag: heroTag,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image_outlined, size: 64, color: Colors.white70),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const SizedBox(
                      width: 32, height: 32,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
