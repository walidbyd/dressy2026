import 'dart:async';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../../../config/ps_config.dart';
import '../../../../config/route/route_paths.dart';
import '../../../../core/vendor/constant/ps_constants.dart';
import '../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../core/vendor/provider/story/story_provider.dart';
import '../../../../core/vendor/utils/story_filter_helper.dart';
import '../../../../core/vendor/viewobject/common/ps_value_holder.dart';
import '../../../../core/vendor/viewobject/default_photo.dart';
import '../../../../core/vendor/viewobject/holder/intent_holder/product_detail_intent_holder.dart';
import '../../../../core/vendor/viewobject/vendor_story.dart';
import '../common/ps_ui_widget.dart';

class StoryViewerView extends StatefulWidget {
  const StoryViewerView({
    Key? key,
    required this.stories,
    this.initialIndex = 0,
    this.vendorName,
    this.vendorLogo,
  }) : super(key: key);

  final List<VendorStory> stories;
  final int initialIndex;
  final String? vendorName;
  final String? vendorLogo;

  @override
  State<StoryViewerView> createState() => _StoryViewerVieState();
}

class _StoryViewerVieState extends State<StoryViewerView>
    with SingleTickerProviderStateMixin {
  late List<VendorStory> _stories;
  late int _currentIndex;
  late AnimationController _animController;
  VideoPlayerController? _videoController;
  bool _isPaused = false;
  bool _isDeleting = false;
  bool _isClosing = false;
  late void Function(AnimationStatus) _statusListener;

  void _closeViewer() {
    if (_isClosing) {
      return;
    }
    _isClosing = true;
    _animController.stop();
    _videoController?.pause();
    _videoController?.dispose();
    _videoController = null;
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  void initState() {
    super.initState();
    _stories = List<VendorStory>.from(widget.stories);
    _currentIndex = widget.initialIndex < _stories.length ? widget.initialIndex : 0;

    _animController = AnimationController(vsync: this);
    _statusListener = (AnimationStatus status) {
      if (!_isClosing && mounted && status == AnimationStatus.completed) {
        _onSlideComplete();
      }
    };
    _animController.addStatusListener(_statusListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isClosing) {
        _loadSlide(_currentIndex);
      }
    });
  }

  @override
  void dispose() {
    _isClosing = true;
    _animController.removeStatusListener(_statusListener);
    _animController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  String _getStoryMediaUrl(VendorStory story) {
    if (story.mediaUrl != null && story.mediaUrl!.isNotEmpty) {
      return story.mediaUrl!;
    }
    final String raw = story.mediaPath ?? '';
    if (raw.isEmpty) {
      return '';
    }
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }
    final String clean = raw.replaceAll(RegExp(r'^/?uploads/'), '');
    return '${PsConfig.ps_core_url}/uploads/$clean';
  }

  Widget _buildAvatar(VendorStory story) {
    final String rawPath = story.avatarPath ?? story.vendorLogoPath ?? '';
    final String rawUrl = story.avatarUrl ?? story.vendorLogo ?? widget.vendorLogo ?? story.userPhoto ?? '';

    // If relative path is available, use PsNetworkCircleImage
    if (rawPath.isNotEmpty && !rawPath.startsWith('http://') && !rawPath.startsWith('https://')) {
      return PsNetworkCircleImage(
        photoKey: '',
        imagePath: rawPath,
        width: 36,
        height: 36,
        boxfit: BoxFit.cover,
      );
    }

    final String finalUrl = rawUrl.isNotEmpty
        ? rawUrl
        : (rawPath.startsWith('http://') || rawPath.startsWith('https://') ? rawPath : '');

    if (finalUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: finalUrl,
        width: 36,
        height: 36,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          color: Colors.grey.shade800,
          child: const Center(
            child: SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Color(0xFFED7768),
              ),
            ),
          ),
        ),
        errorWidget: (BuildContext ctx, String url, dynamic err) {
          print('[StoryViewer] Error loading avatar: $url - $err');
          return Container(
            color: Colors.grey.shade800,
            child: const Icon(Icons.person, color: Colors.white70, size: 20),
          );
        },
      );
    }

    return Container(
      color: Colors.grey.shade800,
      child: const Icon(Icons.person, color: Colors.white70, size: 20),
    );
  }

  Widget _buildItemThumbnail(VendorStory story) {
    final String imgPath = story.itemImagePath ?? story.item?.imagePath ?? '';
    final String rawUrl = story.itemImageUrl ?? story.item?.imageUrl ?? story.item?.photo ?? '';

    // If relative image path is present, use PsNetworkImage
    if (imgPath.isNotEmpty && !imgPath.startsWith('http://') && !imgPath.startsWith('https://')) {
      return PsNetworkImage(
        photoKey: '',
        defaultPhoto: DefaultPhoto(imgPath: imgPath),
        imageAspectRation: PsConst.Aspect_Ratio_1x,
        width: 44,
        height: 44,
        boxfit: BoxFit.cover,
      );
    }

    final String finalUrl = rawUrl.isNotEmpty
        ? rawUrl
        : (imgPath.startsWith('http://') || imgPath.startsWith('https://')
            ? imgPath
            : (imgPath.isNotEmpty ? '${PsConfig.ps_app_image_url}$imgPath' : ''));

    if (finalUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: finalUrl,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          width: 44,
          height: 44,
          color: Colors.grey.shade800,
          child: const Center(
            child: SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Color(0xFFED7768),
              ),
            ),
          ),
        ),
        errorWidget: (BuildContext ctx, String url, dynamic err) {
          print('[StoryViewer] Error loading product thumbnail: $url - $err');
          return Container(
            width: 44,
            height: 44,
            color: Colors.grey.shade800,
            child: const Icon(
              Icons.shopping_bag_outlined,
              color: Colors.white70,
              size: 22,
            ),
          );
        },
      );
    }

    return Container(
      width: 44,
      height: 44,
      color: Colors.grey.shade800,
      child: const Icon(
        Icons.shopping_bag_outlined,
        color: Colors.white70,
        size: 22,
      ),
    );
  }

  void _loadSlide(int index) {
    if (_isClosing || !mounted) {
      return;
    }
    if (_stories.isEmpty) {
      _closeViewer();
      return;
    }

    _animController.stop();
    _animController.reset();
    _videoController?.dispose();
    _videoController = null;

    final VendorStory currentStory = _stories[index];
    final String mediaUrl = _getStoryMediaUrl(currentStory);

    // Record view if buyer
    final PsValueHolder psValueHolder =
        Provider.of<PsValueHolder>(context, listen: false);
    final String loginUserId = psValueHolder.loginUserId ?? '';
    final bool isOwner = currentStory.isOwner ||
        (loginUserId.isNotEmpty && loginUserId != 'nologinuser' && loginUserId == currentStory.userId);

    if (!isOwner && currentStory.id != null) {
      final StoryProvider storyProvider =
          Provider.of<StoryProvider>(context, listen: false);
      storyProvider.recordView(currentStory.id!);
    }

    if (currentStory.mediaType == 'video' && mediaUrl.isNotEmpty) {
      try {
        _videoController = VideoPlayerController.networkUrl(
          Uri.parse(mediaUrl),
        )..initialize().then((_) {
            if (mounted && !_isClosing) {
              setState(() {});
              final Duration videoDuration = _videoController!.value.duration;
              _animController.duration = videoDuration > Duration.zero
                  ? videoDuration
                  : const Duration(seconds: 15);
              _videoController?.play();
              if (!_isPaused) {
                _animController.forward();
              }
            }
          }).catchError((dynamic err) {
            print('[StoryViewer] Error initializing video: $err, url: $mediaUrl');
            if (mounted && !_isClosing) {
              final int slideSeconds = currentStory.duration != null && currentStory.duration! > 0
                  ? currentStory.duration!
                  : 5;
              _animController.duration = Duration(seconds: slideSeconds);
              if (!_isPaused) {
                _animController.forward();
              }
            }
          });
      } catch (err) {
        print('[StoryViewer] Exception creating video controller: $err');
        final int slideSeconds = currentStory.duration != null && currentStory.duration! > 0
            ? currentStory.duration!
            : 5;
        _animController.duration = Duration(seconds: slideSeconds);
        if (!_isPaused && !_isClosing) {
          _animController.forward();
        }
      }
    } else {
      final int slideSeconds = currentStory.duration != null && currentStory.duration! > 0
          ? currentStory.duration!
          : 5;
      _animController.duration = Duration(seconds: slideSeconds);
      if (!_isPaused && !_isClosing) {
        _animController.forward();
      }
    }

    if (mounted && !_isClosing) {
      setState(() {});
    }
  }

  void _onSlideComplete() {
    if (_isClosing || !mounted) {
      return;
    }
    if (_currentIndex < _stories.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _loadSlide(_currentIndex);
    } else {
      _closeViewer();
    }
  }

  void _pauseStory() {
    if (!_isPaused && !_isClosing) {
      setState(() {
        _isPaused = true;
      });
      _animController.stop();
      _videoController?.pause();
    }
  }

  void _resumeStory() {
    if (_isPaused && !_isDeleting && !_isClosing) {
      setState(() {
        _isPaused = false;
      });
      _animController.forward();
      _videoController?.play();
    }
  }

  void _previousSlide() {
    if (_isClosing || !mounted) {
      return;
    }
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _loadSlide(_currentIndex);
    } else {
      _loadSlide(_currentIndex);
    }
  }

  void _nextSlide() {
    if (_isClosing || !mounted) {
      return;
    }
    if (_currentIndex < _stories.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _loadSlide(_currentIndex);
    } else {
      _closeViewer();
    }
  }

  Future<void> _confirmDeleteStory(BuildContext context) async {
    _pauseStory();

    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dContext) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade900,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: <Widget>[
              const Icon(Icons.delete_outline_rounded,
                  color: Color(0xFFED7768), size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'story__delete_title'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'story__delete_body'.tr,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dContext, false),
              child: Text(
                'dialog__cancel'.tr,
                style: const TextStyle(color: Colors.white60),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFED7768),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.pop(dContext, true),
              child: Text(
                'story__delete_confirm'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      setState(() {
        _isDeleting = true;
      });

      final VendorStory target = _stories[_currentIndex];
      final StoryProvider storyProvider =
          Provider.of<StoryProvider>(context, listen: false);

      final bool success = await storyProvider.deleteStory(target.id ?? '');

      if (mounted) {
        setState(() {
          _isDeleting = false;
        });

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('story__deleted_success'.tr),
              backgroundColor: const Color(0xFFED7768),
              behavior: SnackBarBehavior.floating,
            ),
          );

          _stories.removeAt(_currentIndex);
          if (_stories.isEmpty) {
            _closeViewer();
          } else {
            if (_currentIndex >= _stories.length) {
              _currentIndex = _stories.length - 1;
            }
            _loadSlide(_currentIndex);
          }
        } else {
          _resumeStory();
        }
      }
    } else {
      _resumeStory();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_stories.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFED7768)),
        ),
      );
    }

    final VendorStory currentStory = _stories[_currentIndex];
    final PsValueHolder psValueHolder =
        Provider.of<PsValueHolder>(context, listen: false);
    final String loginUserId = psValueHolder.loginUserId ?? '';
    final bool isOwner = currentStory.isOwner ||
        (loginUserId.isNotEmpty && loginUserId != 'nologinuser' && loginUserId == currentStory.userId);

    final String displayName = currentStory.vendorName ??
        widget.vendorName ??
        currentStory.userName ??
        'Dressy Vendeur';

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        _isClosing = true;
        _animController.stop();
        _videoController?.pause();
        _videoController?.dispose();
        _videoController = null;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onLongPressStart: (_) => _pauseStory(),
          onLongPressEnd: (_) => _resumeStory(),
          onVerticalDragEnd: (DragEndDetails details) {
            if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
              _closeViewer();
            }
          },
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            // 1. Media with GPU Filter
            Center(
              child: ColorFiltered(
                colorFilter: StoryFilterHelper.getColorFilter(
                    currentStory.filterPreset),
                child: currentStory.mediaType == 'video'
                    ? (_videoController != null &&
                            _videoController!.value.isInitialized
                        ? SizedBox.expand(
                            child: FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: _videoController!.value.size.width,
                                height: _videoController!.value.size.height,
                                child: VideoPlayer(_videoController!),
                              ),
                            ),
                          )
                        : const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFED7768),
                            ),
                          ))
                    : CachedNetworkImage(
                        imageUrl: _getStoryMediaUrl(currentStory),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        placeholder: (_, __) => const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFED7768),
                          ),
                        ),
                        errorWidget: (BuildContext ctx, String url, dynamic error) {
                          print('[StoryViewer] Error loading story image: $url - $error');
                          return const Center(
                            child: Icon(Icons.broken_image,
                                color: Colors.white54, size: 48),
                          );
                        },
                      ),
              ),
            ),

            // 2. Gradients for text contrast
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 140,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[Colors.black87, Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 220,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[Colors.transparent, Colors.black87],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // 3. Touch Navigation Zones (Tap Left / Tap Right)
            Positioned.fill(
              child: Row(
                children: <Widget>[
                  Expanded(
                    flex: 1,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _previousSlide,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _nextSlide,
                    ),
                  ),
                ],
              ),
            ),

            // 4. Top Header & Segmented Progress Bar
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // Segmented Story Bars
                    Row(
                      children: List<Widget>.generate(
                        _stories.length,
                        (int index) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.0),
                            child: _buildProgressBar(index),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // User / Vendor Header Row
                    Row(
                      children: <Widget>[
                        // Logo Avatar with Warm Coral Ring
                        Container(
                          width: 40,
                          height: 40,
                          padding: const EdgeInsets.all(2.0),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: <Color>[
                                Color(0xFFED7768),
                                Color(0xFFF4A261),
                              ],
                            ),
                          ),
                          child: ClipOval(
                            child: _buildAvatar(currentStory),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Name & Time
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                displayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (currentStory.timeAgo != null &&
                                  currentStory.timeAgo!.isNotEmpty)
                                Text(
                                  currentStory.timeAgo!,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Owner Delete Action Button
                        if (isOwner)
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: Colors.white, size: 22),
                            onPressed: () => _confirmDeleteStory(context),
                          ),

                        // Close Button
                        IconButton(
                          icon: const Icon(Icons.close,
                              color: Colors.white, size: 24),
                          onPressed: _closeViewer,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 5. Views Counter (Bottom-Left) on Seller's Own Slide
            if (isOwner)
              Positioned(
                left: 16,
                bottom: currentStory.item != null ? 100 : 36,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(Icons.visibility_outlined,
                              color: Colors.white70, size: 14),
                          const SizedBox(width: 5),
                          Text(
                            '${currentStory.viewsCount ?? 0} ${'story__views_count'.tr}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // 6. Caption Text (Bottom)
            if (currentStory.caption != null &&
                currentStory.caption!.isNotEmpty)
              Positioned(
                left: 20,
                right: 20,
                bottom: currentStory.item != null ? 90 : 28,
                child: Text(
                  currentStory.caption!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    shadows: <Shadow>[
                      Shadow(
                        color: Colors.black87,
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // 7. Tagged Product Interactive Pill (Bottom)
            if ((currentStory.itemId != null && currentStory.itemId!.isNotEmpty) ||
                currentStory.item != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: 24,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: InkWell(
                      onTap: () {
                        final String pId = currentStory.itemId ?? currentStory.item?.id ?? '';
                        if (pId.isNotEmpty) {
                          _pauseStory();
                          Navigator.pushNamed(
                            context,
                            RoutePaths.productDetail,
                            arguments: ProductDetailIntentHolder(
                              productId: pId,
                              heroTagImage: '',
                              heroTagTitle: '',
                            ),
                          ).then((_) => _resumeStory());
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFFED7768).withValues(alpha: 0.8),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            // Product Thumbnail
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _buildItemThumbnail(currentStory),
                            ),
                            const SizedBox(width: 10),

                            // Title & Price
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Text(
                                    currentStory.itemTitle ?? currentStory.item?.title ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    '${currentStory.itemPrice ?? currentStory.item?.price ?? '0'} ${currentStory.currencySymbol ?? currentStory.item?.currencySymbol ?? 'DZD'}',
                                    style: const TextStyle(
                                      color: Color(0xFFED7768),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // "Voir l'article" Pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFED7768),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Text(
                                    'story__view_product'.tr,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_forward_ios_rounded,
                                      color: Colors.white, size: 10),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildProgressBar(int index) {
    if (index < _currentIndex) {
      return Container(
        height: 3,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(2),
        ),
      );
    } else if (index == _currentIndex) {
      return AnimatedBuilder(
        animation: _animController,
        builder: (BuildContext context, Widget? child) {
          return LinearProgressIndicator(
            value: _animController.value,
            backgroundColor: Colors.white30,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFED7768)),
            minHeight: 3,
            borderRadius: BorderRadius.circular(2),
          );
        },
      );
    } else {
      return Container(
        height: 3,
        decoration: BoxDecoration(
          color: Colors.white30,
          borderRadius: BorderRadius.circular(2),
        ),
      );
    }
  }
}
