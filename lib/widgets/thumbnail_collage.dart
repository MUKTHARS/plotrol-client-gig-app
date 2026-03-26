import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ThumbCollage extends StatelessWidget {
  final List<String> urls;
  final double height;
  final double width;
  final double borderRadius;
  final double spacing;

  const ThumbCollage({
    Key? key,
    required this.urls,
    required this.height,
    required this.width,
    this.borderRadius = 8,
    this.spacing = 2,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPrint('[ThumbCollage] Received ${urls.length} URLs: $urls');
    final display = urls.where((u) => u.isNotEmpty && (u.startsWith('http://') || u.startsWith('https://'))).take(5).toList();
    final filtered = urls.where((u) => u.isNotEmpty && !(u.startsWith('http://') || u.startsWith('https://'))).toList();
    if (filtered.isNotEmpty) {
      debugPrint('[ThumbCollage] FILTERED OUT (not http/https): $filtered');
    }
    debugPrint('[ThumbCollage] Displaying ${display.length} URLs: $display');
    final extra = urls.length - display.length;

    // If no images, show a neutral placeholder
    if (display.isEmpty) {
      debugPrint('[ThumbCollage] No valid URLs to display — showing placeholder');
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          height: height,
          width: width,
          color: Colors.grey.shade200,
          alignment: Alignment.center,
          child: const Icon(Icons.image_outlined, size: 32, color: Colors.grey),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        height: height,
        width: width,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          itemCount: display.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: 1, // squares
          ),
          itemBuilder: (context, i) {
            final isLastWithMore = (i == display.length - 1) && extra > 0;
            final url = display[i];
            return Stack(
              fit: StackFit.expand,
              children: [
                _Thumb(url: url),
                if (isLastWithMore)
                  Container(
                    color: Colors.black45,
                    alignment: Alignment.center,
                    child: Text(
                      '+$extra',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final String url;
  const _Thumb({Key? key, required this.url}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPrint('[_Thumb] Loading image: $url');
    return Image.network(
      url,
      fit: BoxFit.cover,
      // lightweight loader
      frameBuilder: (context, child, frame, _) {
        if (frame != null) {
          debugPrint('[_Thumb] Frame loaded for: $url');
          return child;
        }
        return Container(
          color: Colors.grey.shade200,
          alignment: Alignment.center,
          child: const SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: Colors.grey.shade200,
          alignment: Alignment.center,
          child: const SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      errorBuilder: (_, error, stackTrace) {
        debugPrint('[_Thumb] ERROR loading $url — $error');
        return Container(
          color: Colors.grey.shade200,
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
        );
      },
      // downsample thumbnails for perf
      cacheWidth: 256,
      cacheHeight: 256,
    );
  }
}
