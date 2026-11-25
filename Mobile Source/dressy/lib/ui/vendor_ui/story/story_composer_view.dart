import 'dart:io';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_video_thumbnail_plus/flutter_video_thumbnail_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../../../config/ps_config.dart';
import '../../../../core/vendor/api/common/ps_resource.dart';
import '../../../../core/vendor/api/common/ps_status.dart';
import '../../../../core/vendor/api/ps_api_service.dart';
import '../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../core/vendor/provider/story/story_provider.dart';
import '../../../../core/vendor/utils/story_filter_helper.dart';
import '../../../../core/vendor/viewobject/common/ps_value_holder.dart';
import '../../../../core/vendor/viewobject/holder/product_parameter_holder.dart';
import '../../../../core/vendor/viewobject/product.dart';
import '../../../../core/vendor/viewobject/vendor_story.dart';
import '../common/dialog/warning_dialog_view.dart';
import '../ads/widgets/story_boost_helper.dart';

class StoryComposerView extends StatefulWidget {
  const StoryComposerView({
    Key? key,
    required this.mediaPath,
    required this.mediaType,
  }) : super(key: key);

  final String mediaPath;
  final String mediaType; // 'image' or 'video'

  @override
  State<StoryComposerView> createState() => _StoryComposerViewState();
}

class _StoryComposerViewState extends State<StoryComposerView> {
  final TextEditingController _captionController = TextEditingController();
  String _selectedPresetId = 'original';
  bool _showFilters = false;
  bool _isPublishing = false;
  Product? _selectedProduct;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    if (widget.mediaType == 'video') {
      _videoController = VideoPlayerController.file(File(widget.mediaPath))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
            _videoController?.setLooping(true);
            _videoController?.play();
          }
        });
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Widget _buildProductThumbnail(Product prod, {double size = 52, double radius = 10}) {
    final String? rawImg = prod.defaultPhoto?.imgPath;
    String fullUrl = '';
    if (rawImg != null && rawImg.trim().isNotEmpty) {
      if (rawImg.startsWith('http://') || rawImg.startsWith('https://')) {
        fullUrl = rawImg;
      } else {
        fullUrl = '${PsConfig.ps_app_image_url}$rawImg';
      }
    }

    Widget placeholder() {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFED7768).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Icon(
          Icons.shopping_bag_outlined,
          color: const Color(0xFFED7768),
          size: size * 0.45,
        ),
      );
    }

    if (fullUrl.isEmpty) {
      return placeholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CachedNetworkImage(
        imageUrl: fullUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          width: size,
          height: size,
          color: Colors.grey.shade200,
          child: const Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFED7768),
              ),
            ),
          ),
        ),
        errorWidget: (_, __, ___) => placeholder(),
      ),
    );
  }

  void _openProductTaggingSheet(BuildContext context) {
    final PsValueHolder psValueHolder =
        Provider.of<PsValueHolder>(context, listen: false);
    final PsApiService apiService =
        Provider.of<PsApiService>(context, listen: false);
    final String loginUserId = psValueHolder.loginUserId ?? '';

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext bContext) {
        return Container(
          height: MediaQuery.of(bContext).size.height * 0.65,
          decoration: BoxDecoration(
            color: Theme.of(bContext).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
          ),
          child: Column(
            children: <Widget>[
              // Sheet Header
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'story__select_product_to_tag'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(bContext),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Items List
              Expanded(
                child: FutureBuilder<PsResource<List<Product>>>(
                  future: () async {
                    final String langCode = psValueHolder.languageCode ?? 'fr';
                    if (loginUserId.isNotEmpty && loginUserId != 'nologinuser') {
                      try {
                        final PsResource<List<Product>> myItemsRes =
                            await apiService.getStoryMyItems(loginUserId, langCode);
                        if (myItemsRes.status == PsStatus.SUCCESS &&
                            myItemsRes.data != null &&
                            myItemsRes.data!.isNotEmpty) {
                          return myItemsRes;
                        }
                      } catch (_) {}
                    }
                    final ProductParameterHolder holder =
                        ProductParameterHolder().getLatestParameterHolder();
                    holder.addedUserId = loginUserId;
                    holder.status = '1';
                    return apiService.getProductList(
                      holder.toMap(),
                      loginUserId,
                      langCode,
                      30,
                      0,
                    );
                  }(),
                  builder: (BuildContext context,
                      AsyncSnapshot<PsResource<List<Product>>> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFED7768),
                        ),
                      );
                    }

                    final List<Product>? items = snapshot.data?.data;
                    if (items == null || items.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text(
                            'story__no_active_products'.tr,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (BuildContext context, int index) {
                        final Product prod = items[index];
                        final bool isSelected = _selectedProduct?.id == prod.id;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          leading: _buildProductThumbnail(prod, size: 52, radius: 10),
                          title: Text(
                            prod.title ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${prod.originalPrice ?? prod.currentPrice ?? '0'} ${prod.itemCurrency?.currencySymbol ?? 'DZD'}',
                            style: const TextStyle(
                              color: Color(0xFFED7768),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle,
                                  color: Color(0xFFED7768), size: 26)
                              : const Icon(Icons.radio_button_unchecked,
                                  color: Colors.grey, size: 24),
                          onTap: () {
                            setState(() {
                              _selectedProduct = prod;
                            });
                            Navigator.pop(bContext);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _publishStory() async {
    if (_isPublishing) {
      return;
    }

    setState(() {
      _isPublishing = true;
    });

    try {
      final StoryProvider storyProvider =
          Provider.of<StoryProvider>(context, listen: false);

      File uploadFile = File(widget.mediaPath);
      File? thumbnailFile;

      if (widget.mediaType == 'image') {
        // Compress image to 1080px max width and quality 82 as requested
        final Directory tempDir = await getTemporaryDirectory();
        final String targetPath =
            '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

        final XFile? compressed =
            await FlutterImageCompress.compressAndGetFile(
          uploadFile.absolute.path,
          targetPath,
          quality: 82,
          minWidth: 1080,
        );

        if (compressed != null) {
          uploadFile = File(compressed.path);
        }
      } else {
        // Video thumbnail generation
        try {
          final Directory tempDir = await getTemporaryDirectory();
          final String? thumbPath =
              await FlutterVideoThumbnailPlus.thumbnailFile(
            video: widget.mediaPath,
            thumbnailPath: tempDir.path,
            imageFormat: ImageFormat.jpeg,
            quality: 75,
          );
          if (thumbPath != null && thumbPath.isNotEmpty) {
            thumbnailFile = File(thumbPath);
          }
        } catch (_) {}
      }

      final PsResource<VendorStory> result = await storyProvider.uploadStory(
        mediaFile: uploadFile,
        mediaType: widget.mediaType,
        caption: _captionController.text.trim(),
        itemId: _selectedProduct?.id,
        filterPreset: _selectedPresetId,
        duration: widget.mediaType == 'video' ? 15 : 5,
        thumbnailFile: thumbnailFile,
      );

      if (result.status == PsStatus.SUCCESS && result.data != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('story__publish'.tr + ' !'),
              backgroundColor: const Color(0xFFED7768),
              behavior: SnackBarBehavior.floating,
            ),
          );
          await StoryBoostHelper.showBoostSheet(
            context,
            storyId: result.data!.id ?? '',
            isAfterPublish: true,
          );
          if (mounted) {
            Navigator.pop(context, true);
          }
        }
      } else {
        if (mounted) {
          showDialog<dynamic>(
            context: context,
            builder: (BuildContext dContext) {
              return WarningDialog(
                message: result.message.isNotEmpty
                    ? result.message
                    : 'Échec de la publication de la story',
                onPressed: () {},
              );
            },
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showDialog<dynamic>(
          context: context,
          builder: (BuildContext dContext) {
            return WarningDialog(
              message: e.toString(),
              onPressed: () {},
            );
          },
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPublishing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // 1. Full-screen preview with selected GPU color filter
          Center(
            child: ColorFiltered(
              colorFilter: StoryFilterHelper.getColorFilter(_selectedPresetId),
              child: widget.mediaType == 'video'
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
                  : Image.file(
                      File(widget.mediaPath),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
            ),
          ),

          // 2. Subtle gradient overlay for header and footer readability
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 140,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[Color(0xBD000000), Colors.transparent],
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
            height: 260,
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

          // 3. Floating Tagged Product Price Pill (if selected)
          if (_selectedProduct != null)
            Positioned(
              bottom: _showFilters ? 220 : 130,
              left: 20,
              right: 20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: const Color(0xFFED7768).withValues(alpha: 0.8),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        _buildProductThumbnail(_selectedProduct!, size: 36, radius: 8),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                _selectedProduct!.title ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_selectedProduct!.originalPrice ?? _selectedProduct!.currentPrice ?? '0'} ${_selectedProduct!.itemCurrency?.currencySymbol ?? 'DZD'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFED7768),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _selectedProduct = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white24,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // 4. Top Bar Controls
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  // Close Button in Frosted Glass Circle
                  ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        color: Colors.black45,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                  ),

                  // Top Action Pills
                  Row(
                    children: <Widget>[
                      // Filter Toggle Pill
                      _buildTopPill(
                        icon: Icons.tune_rounded,
                        label: 'story__filters'.tr,
                        isActive: _showFilters,
                        onTap: () {
                          setState(() {
                            _showFilters = !_showFilters;
                          });
                        },
                      ),
                      const SizedBox(width: 8),

                      // Tag Product Pill
                      _buildTopPill(
                        icon: Icons.sell_outlined,
                        label: _selectedProduct != null
                            ? '1 article'
                            : 'story__tag_product'.tr,
                        isActive: _selectedProduct != null,
                        onTap: () => _openProductTaggingSheet(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 5. Bottom Filter Strip + Caption + Publish Button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Horizontal Filter Strip
                  if (_showFilters)
                    Container(
                      height: 94,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        itemCount: StoryFilterHelper.presets.length,
                        itemBuilder: (BuildContext context, int index) {
                          final StoryFilterPreset preset =
                              StoryFilterHelper.presets[index];
                          final bool isSelected =
                              _selectedPresetId == preset.id;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedPresetId = preset.id;
                              });
                            },
                            child: Container(
                              width: 72,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFFED7768)
                                            : Colors.white38,
                                        width: isSelected ? 2.5 : 1.0,
                                      ),
                                      boxShadow: isSelected
                                          ? <BoxShadow>[
                                              BoxShadow(
                                                color: const Color(0xFFED7768)
                                                    .withValues(alpha: 0.5),
                                                blurRadius: 8,
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: ClipOval(
                                      child: ColorFiltered(
                                        colorFilter:
                                            ColorFilter.matrix(preset.matrix),
                                        child: Image.file(
                                          File(widget.mediaPath),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    preset.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isSelected
                                          ? const Color(0xFFED7768)
                                          : Colors.white,
                                      fontSize: 10,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    preset.subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white70
                                          : Colors.white54,
                                      fontSize: 8.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  // Caption Pill
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: TextField(
                            controller: _captionController,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                            maxLines: 2,
                            minLines: 1,
                            decoration: InputDecoration(
                              hintText: 'story__caption_hint'.tr,
                              hintStyle: const TextStyle(
                                color: Colors.white60,
                                fontSize: 13,
                              ),
                              border: InputBorder.none,
                              prefixIcon: const Icon(
                                Icons.edit_note_rounded,
                                color: Colors.white70,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Primary Publish Button
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 16, right: 16, top: 6, bottom: 12),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFED7768),
                          foregroundColor: Colors.white,
                          elevation: 6,
                          shadowColor:
                              const Color(0xFFED7768).withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _isPublishing ? null : _publishStory,
                        child: _isPublishing
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.2,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    'story__publish'.tr,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 18,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPill({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFFED7768)
                  : Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive ? const Color(0xFFED7768) : Colors.white24,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
