import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class FullScreenImageGallery extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final String? title;

  const FullScreenImageGallery({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
    this.title,
  });

  /// Helper to open the gallery with a smooth fade/scale transition
  static Future<void> open(
    BuildContext context, {
    required List<String> imageUrls,
    int initialIndex = 0,
    String? title,
  }) {
    if (imageUrls.isEmpty) return Future.value();
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.95),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FullScreenImageGallery(
            imageUrls: imageUrls,
            initialIndex: initialIndex.clamp(0, imageUrls.length - 1),
            title: title,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  State<FullScreenImageGallery> createState() => _FullScreenImageGalleryState();
}

class _FullScreenImageGalleryState extends State<FullScreenImageGallery>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;
  bool _showControls = true;
  final Map<int, TransformationController> _transformControllers = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final controller in _transformControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TransformationController _getControllerForIndex(int index) {
    if (!_transformControllers.containsKey(index)) {
      _transformControllers[index] = TransformationController();
    }
    return _transformControllers[index]!;
  }

  void _resetZoom(int index) {
    if (_transformControllers.containsKey(index)) {
      _transformControllers[index]!.value = Matrix4.identity();
    }
  }

  void _handleDoubleTap(int index) {
    final controller = _getControllerForIndex(index);
    if (controller.value != Matrix4.identity()) {
      setState(() {
        controller.value = Matrix4.identity();
      });
    } else {
      setState(() {
        // Zoom into center 2.5x
        controller.value = Matrix4.diagonal3Values(2.5, 2.5, 1.0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.imageUrls.length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Black backdrop with tap to toggle controls
            GestureDetector(
              onTap: () {
                setState(() => _showControls = !_showControls);
              },
              child: Container(color: Colors.black),
            ),

            // Swipeable Full-Length Image PageView
            PageView.builder(
              controller: _pageController,
              itemCount: total,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (index) {
                _resetZoom(_currentIndex);
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) {
                final url = widget.imageUrls[index];
                final transformController = _getControllerForIndex(index);

                return GestureDetector(
                  onDoubleTap: () => _handleDoubleTap(index),
                  onTap: () {
                    setState(() => _showControls = !_showControls);
                  },
                  child: Center(
                    child: InteractiveViewer(
                      transformationController: transformController,
                      minScale: 1.0,
                      maxScale: 4.5,
                      clipBehavior: Clip.none,
                      child: CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.contain, // Shows full vertical & horizontal length without cropping
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height,
                        placeholder: (context, url) => const Center(
                          child: SizedBox(
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Color(0xFFE8DCC4),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.broken_image_rounded,
                                color: Colors.white54,
                                size: 54,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Unable to load photo',
                                style: GoogleFonts.inter(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // Top Bar Overlay (Close, Counter, Title)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              top: _showControls ? 0 : -120,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        // Back / Close Button with Frosted Glass
                        ClipOval(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Material(
                              color: Colors.white.withValues(alpha: 0.18),
                              child: InkWell(
                                onTap: () => Navigator.of(context).pop(),
                                child: const Padding(
                                  padding: EdgeInsets.all(10),
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Title (Mess Name)
                        Expanded(
                          child: widget.title != null && widget.title!.isNotEmpty
                              ? Text(
                                  widget.title!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: 0.2,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),

                        // Image Counter Badge e.g. "1 / 4"
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${_currentIndex + 1} / $total',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Bar Overlay (Thumbnails strip & swipe hint)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              bottom: _showControls ? 0 : -140,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20, top: 16, left: 16, right: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Hint text
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.swipe_rounded,
                              size: 14,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Swipe left/right to browse • Double-tap to zoom',
                              style: GoogleFonts.inter(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        if (total > 1) ...[
                          const SizedBox(height: 14),
                          // Horizontal thumbnail strip for quick jump
                          SizedBox(
                            height: 48,
                            child: Center(
                              child: ListView.separated(
                                shrinkWrap: true,
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                itemCount: total,
                                separatorBuilder: (context, index) => const SizedBox(width: 8),
                                itemBuilder: (context, thumbIdx) {
                                  final isSelected = thumbIdx == _currentIndex;
                                  return GestureDetector(
                                    onTap: () {
                                      _pageController.animateToPage(
                                        thumbIdx,
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOutCubic,
                                      );
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: isSelected ? 48 : 40,
                                      height: isSelected ? 48 : 40,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFFE8DCC4)
                                              : Colors.white.withValues(alpha: 0.25),
                                          width: isSelected ? 2.5 : 1,
                                        ),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.5),
                                                  blurRadius: 8,
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: CachedNetworkImage(
                                          imageUrl: widget.imageUrls[thumbIdx],
                                          fit: BoxFit.cover,
                                          placeholder: (c, u) => Container(
                                            color: Colors.white10,
                                          ),
                                          errorWidget: (c, u, e) => Container(
                                            color: Colors.white12,
                                            child: const Icon(
                                              Icons.broken_image,
                                              size: 16,
                                              color: Colors.white54,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
