import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../../../config/ps_colors.dart';
import '../../../../../../config/route/route_paths.dart';
import '../../../../../../core/vendor/constant/ps_dimens.dart';
import '../../../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../../../core/vendor/provider/story/story_provider.dart';
import '../../../../../../core/vendor/utils/utils.dart';
import '../../../../../../core/vendor/viewobject/common/ps_value_holder.dart';
import '../../../../../../core/vendor/viewobject/vendor_story.dart';
import '../../../../common/ps_ui_widget.dart';

class LatestVendorListWidget extends StatefulWidget {
  const LatestVendorListWidget({Key? key, required this.animationController})
      : super(key: key);

  final AnimationController? animationController;

  @override
  State<LatestVendorListWidget> createState() => _LatestVendorListWidgetState();
}

class _LatestVendorListWidgetState extends State<LatestVendorListWidget> {
  bool _hasLoadedStories = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoadedStories) {
      _hasLoadedStories = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          try {
            Provider.of<StoryProvider>(context, listen: false).loadFeed();
          } catch (_) {}
        }
      });
    }
  }

  Future<void> _pickAndComposeStory() async {
    final ImagePicker picker = ImagePicker();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bContext) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(bContext).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined,
                    color: Color(0xFFED7768)),
                title: Text('story__take_photo'.tr),
                onTap: () async {
                  Navigator.pop(bContext);
                  final XFile? photo =
                      await picker.pickImage(source: ImageSource.camera);
                  if (photo != null && mounted) {
                    Navigator.pushNamed(
                      context,
                      RoutePaths.storyComposer,
                      arguments: <String, dynamic>{
                        'mediaPath': photo.path,
                        'mediaType': 'image',
                      },
                    ).then((_) {
                      if (mounted) {
                        Provider.of<StoryProvider>(context, listen: false).loadFeed();
                      }
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam_outlined,
                    color: Color(0xFFED7768)),
                title: Text('story__record_video'.tr),
                onTap: () async {
                  Navigator.pop(bContext);
                  final XFile? video = await picker.pickVideo(
                    source: ImageSource.camera,
                    maxDuration: const Duration(seconds: 15),
                  );
                  if (video != null && mounted) {
                    Navigator.pushNamed(
                      context,
                      RoutePaths.storyComposer,
                      arguments: <String, dynamic>{
                        'mediaPath': video.path,
                        'mediaType': 'video',
                      },
                    ).then((_) {
                      if (mounted) {
                        Provider.of<StoryProvider>(context, listen: false).loadFeed();
                      }
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: Color(0xFFED7768)),
                title: Text('story__choose_gallery'.tr),
                onTap: () async {
                  Navigator.pop(bContext);
                  final XFile? media = await picker.pickMedia();
                  if (media != null && mounted) {
                    final String ext = media.path.toLowerCase();
                    final String type = (ext.endsWith('.mp4') ||
                            ext.endsWith('.mov') ||
                            ext.endsWith('.avi') ||
                            ext.endsWith('.m4v') ||
                            ext.endsWith('.webm'))
                        ? 'video'
                        : 'image';
                    Navigator.pushNamed(
                      context,
                      RoutePaths.storyComposer,
                      arguments: <String, dynamic>{
                        'mediaPath': media.path,
                        'mediaType': type,
                      },
                    ).then((_) {
                      if (mounted) {
                        Provider.of<StoryProvider>(context, listen: false).loadFeed();
                      }
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMyStoryItem(
      BuildContext context, StoryProvider storyProvider, PsValueHolder valueHolder) {
    final bool hasStories = storyProvider.hasMyActiveStories;
    final String myAvatarPath = (hasStories && storyProvider.myStories.isNotEmpty)
        ? (storyProvider.myStories.first.avatarPath ?? '')
        : '';
    final String myAvatarUrl = (hasStories && storyProvider.myStories.isNotEmpty)
        ? (storyProvider.myStories.first.avatarUrl ?? '')
        : '';

    return GestureDetector(
      onTap: () {
        if (hasStories) {
          Navigator.pushNamed(
            context,
            RoutePaths.storyViewer,
            arguments: <String, dynamic>{
              'stories': storyProvider.myStories,
              'vendorName': valueHolder.loginUserName ?? 'story__my_story'.tr,
              'vendorLogo': myAvatarUrl,
            },
          ).then((_) {
            if (mounted) {
              storyProvider.loadFeed();
            }
          });
        } else {
          _pickAndComposeStory();
        }
      },
      child: Container(
        width: 76,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Stack(
              children: <Widget>[
                // Gradient Story Ring in brand coral
                Container(
                  width: 64,
                  height: 64,
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: hasStories
                        ? const LinearGradient(
                            colors: <Color>[
                              Color(0xFFED7768),
                              Color(0xFFF4A261),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    border: hasStories
                        ? null
                        : Border.all(
                            color: const Color(0xFFED7768).withValues(alpha: 0.6),
                            width: 1.5,
                          ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Utils.isLightMode(context)
                          ? PsColors.backgroundColor
                          : PsColors.achromatic800,
                    ),
                    child: ClipOval(
                      child: myAvatarPath.isNotEmpty && !myAvatarPath.startsWith('http')
                          ? PsNetworkCircleImage(
                              photoKey: '',
                              imagePath: myAvatarPath,
                              width: 56,
                              height: 56,
                              boxfit: BoxFit.cover,
                            )
                          : (myAvatarUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: myAvatarUrl,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => const Icon(
                                    Icons.person_rounded,
                                    size: 32,
                                    color: Color(0xFFED7768),
                                  ),
                                )
                              : const Icon(
                                  Icons.person_rounded,
                                  size: 32,
                                  color: Color(0xFFED7768),
                                )),
                    ),
                  ),
                ),
                // Small + Add badge on bottom right
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: () => _pickAndComposeStory(),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Utils.isLightMode(context)
                            ? PsColors.backgroundColor
                            : PsColors.achromatic800,
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Color(0xFFED7768),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            SizedBox(
              width: 72,
              child: Text(
                'story__my_story'.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: hasStories
                      ? const Color(0xFFED7768)
                      : (Utils.isLightMode(context)
                          ? PsColors.text800
                          : PsColors.text100),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryGroupItem(
      BuildContext context, VendorStoriesGroup group, StoryProvider storyProvider) {
    final String displayName = group.vendorName ?? 'Vendeur';
    final String avatarPath = group.avatarPath ?? group.vendorLogoPath ?? '';
    final String avatarUrl = group.avatarUrl ?? group.vendorLogo ?? '';
    final bool isVendor = group.vendorId != null && group.vendorId!.isNotEmpty && group.vendorId != '0';

    return GestureDetector(
      onTap: () {
        if (group.stories.isNotEmpty) {
          Navigator.pushNamed(
            context,
            RoutePaths.storyViewer,
            arguments: <String, dynamic>{
              'stories': group.stories,
              'vendorName': group.vendorName,
              'vendorLogo': avatarUrl.isNotEmpty ? avatarUrl : group.vendorLogo,
            },
          ).then((_) {
            if (mounted) {
              storyProvider.loadFeed();
            }
          });
        }
      },
      child: Container(
        width: 76,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Stack(
              children: <Widget>[
                // Coral gradient ring for active stories
                Container(
                  width: 64,
                  height: 64,
                  padding: const EdgeInsets.all(2.5),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: <Color>[
                        Color(0xFFED7768),
                        Color(0xFFF4A261),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Utils.isLightMode(context)
                          ? PsColors.backgroundColor
                          : PsColors.achromatic800,
                    ),
                    child: ClipOval(
                      child: avatarPath.isNotEmpty && !avatarPath.startsWith('http')
                          ? PsNetworkCircleImage(
                              photoKey: '',
                              imagePath: avatarPath,
                              width: 56,
                              height: 56,
                              boxfit: BoxFit.cover,
                            )
                          : (avatarUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: avatarUrl,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(
                                    color: Utils.isLightMode(context)
                                        ? PsColors.text100
                                        : PsColors.text700,
                                  ),
                                  errorWidget: (_, __, ___) => Icon(
                                    isVendor ? Icons.storefront : Icons.person,
                                    size: 28,
                                    color: const Color(0xFFED7768),
                                  ),
                                )
                              : Icon(
                                  isVendor ? Icons.storefront : Icons.person,
                                  size: 28,
                                  color: const Color(0xFFED7768),
                                )),
                    ),
                  ),
                ),
                // Small verified checkmark badge at bottom-right for verified vendors
                if (isVendor)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(1.5),
                      decoration: BoxDecoration(
                        color: Utils.isLightMode(context)
                            ? PsColors.backgroundColor
                            : PsColors.achromatic800,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Color(0xFFED7768),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            SizedBox(
              width: 72,
              child: Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Utils.isLightMode(context)
                      ? PsColors.text800
                      : PsColors.text100,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerItem(BuildContext context) {
    return Container(
      width: 76,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: <Widget>[
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Utils.isLightMode(context)
                  ? PsColors.text100
                  : PsColors.text700,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 48,
            height: 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Utils.isLightMode(context)
                  ? PsColors.text100
                  : PsColors.text700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final PsValueHolder valueHolder =
        Provider.of<PsValueHolder>(context, listen: false);

    final bool isUserLoggedIn = Utils.checkUserLoginId(valueHolder) != 'nologinuser' &&
        Utils.checkUserLoginId(valueHolder).isNotEmpty;

    return SliverToBoxAdapter(
        child: Consumer<StoryProvider>(
          builder: (BuildContext context, StoryProvider storyProvider, Widget? child) {
            final List<VendorStoriesGroup> activeGroups = storyProvider.storiesByVendor;
            final bool isLoading = storyProvider.isLoading;

            // If no stories exist and user is not logged in, hide section entirely
            if (!isLoading && activeGroups.isEmpty && !isUserLoggedIn && !storyProvider.hasMyActiveStories) {
              return const SizedBox.shrink();
            }

            // Total items: 1 (My Story) + active vendor story groups
            final int totalItems = isUserLoggedIn
                ? (isLoading && activeGroups.isEmpty ? 1 + 3 : 1 + activeGroups.length)
                : (isLoading && activeGroups.isEmpty ? 3 : activeGroups.length);

            if (totalItems == 0) {
              return const SizedBox.shrink();
            }

            return Column(
              children: <Widget>[
                  // Header Row with "Vendors" and "See all" pill
                  Padding(
                    padding: const EdgeInsets.only(
                      left: PsDimens.space16,
                      right: PsDimens.space16,
                      top: PsDimens.space8,
                      bottom: PsDimens.space8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          'home__vendors'.tr.isNotEmpty &&
                                  'home__vendors'.tr != 'home__vendors'
                              ? 'home__vendors'.tr
                              : 'dashboard__latest_vendor'.tr,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                    color: Utils.isLightMode(context)
                                        ? PsColors.text900
                                        : PsColors.text50,
                                  ),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              RoutePaths.latestVendorList,
                            );
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFED7768).withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              'home__see_all'.tr.isNotEmpty &&
                                      'home__see_all'.tr != 'home__see_all'
                                  ? 'home__see_all'.tr
                                  : 'profile__view_all'.tr,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFED7768),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              // Instagram-Style Stories Horizontal List:
              // Index 0 is always the seller's "+ Ajouter votre story" ring.
              // Subsequent items are strictly active stories from psx_vendor_stories where expires_at > NOW().
              Container(
                height: 98,
                child: ListView.builder(
                  shrinkWrap: false,
                  padding: const EdgeInsets.symmetric(
                      horizontal: PsDimens.space10),
                  scrollDirection: Axis.horizontal,
                  itemCount: totalItems,
                  itemBuilder: (BuildContext context, int index) {
                    if (isUserLoggedIn && index == 0) {
                      return _buildMyStoryItem(
                          context, storyProvider, valueHolder);
                    }
                    final int groupIndex = isUserLoggedIn ? index - 1 : index;
                    if (isLoading && activeGroups.isEmpty) {
                      return _buildShimmerItem(context);
                    }
                    if (groupIndex < activeGroups.length) {
                      final VendorStoriesGroup group = activeGroups[groupIndex];
                      return _buildStoryGroupItem(
                          context, group, storyProvider);
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
