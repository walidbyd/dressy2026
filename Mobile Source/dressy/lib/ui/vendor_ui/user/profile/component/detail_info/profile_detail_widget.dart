import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../../../config/ps_colors.dart';
import '../../../../../../config/route/route_paths.dart';
import '../../../../../../core/vendor/constant/ps_dimens.dart';
import '../../../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../../../core/vendor/provider/story/story_provider.dart';
import '../../../../../../core/vendor/provider/user/user_provider.dart';
import '../../../../../../core/vendor/utils/ps_animation.dart';
import '../../../../../../core/vendor/utils/utils.dart';
import '../../../../../../core/vendor/viewobject/common/ps_value_holder.dart';
import '../../../../../../core/vendor/viewobject/holder/intent_holder/item_list_intent_holder.dart';
import '../../../../../../core/vendor/viewobject/user.dart';
import '../../../../../../core/vendor/viewobject/vendor_story.dart';
import '../../../../common/bluemark_icon.dart';
import '../../../../common/ps_ui_widget.dart';
import '../../../../ads/widgets/story_boost_helper.dart';

class ProfileDetailWidget extends StatefulWidget {
  const ProfileDetailWidget(
      {Key? key,
      required this.animationController,
      required this.callLogoutCallBack})
      : super(key: key);

  final AnimationController? animationController;
  final Function callLogoutCallBack;

  @override
  __ProfileDetailWidgetState createState() => __ProfileDetailWidgetState();
}

class __ProfileDetailWidgetState extends State<ProfileDetailWidget> {
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          final StoryProvider storyProvider =
              Provider.of<StoryProvider>(context, listen: false);
          storyProvider.loadFeed();
        } catch (_) {}
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final PsValueHolder psValueHolder =
        Provider.of<PsValueHolder>(context, listen: false);
    animation = curveAnimation(widget.animationController!);


    return SliverToBoxAdapter(
      child: Consumer2<UserProvider, StoryProvider>(builder:
          (BuildContext context, UserProvider provider, StoryProvider storyProvider, Widget? child) {
        if (provider.hasData) {
          /**
               * UI SECTION
               */
          final User user = provider.user.data!;
          return AnimatedBuilder(
              animation: widget.animationController!,
              child: Column(
                children: <Widget>[
                  const SizedBox(height: PsDimens.space12),
                  // Centered Avatar with #ED7768 accent ring
                  Center(
                    child: Container(
                      width: 86.0,
                      height: 86.0,
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFED7768),
                          width: 2.5,
                        ),
                      ),
                      child: ClipOval(
                        child: (user.userCoverPhoto != null &&
                                user.userCoverPhoto!.isNotEmpty)
                            ? PsNetworkCircleImageForUser(
                                photoKey: '',
                                imagePath: user.userCoverPhoto,
                                width: 80.0,
                                height: 80.0,
                                boxfit: BoxFit.cover,
                                onTap: () {},
                              )
                            : CircleAvatar(
                                backgroundColor: const Color(0xFFFDEEEB),
                                child: Text(
                                  user.name?.isNotEmpty == true
                                      ? user.name![0].toUpperCase()
                                      : 'D',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFED7768),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Display Name & Verified Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          user.name ?? '',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 19,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user.isVefifiedBlueMarkUser) ...<Widget>[
                        const SizedBox(width: 4.0),
                        const BluemarkIcon(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Membre depuis pill
                  if (user.addedDate != null && user.addedDate!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: Utils.isLightMode(context)
                            ? const Color(0xFFF3F4F6)
                            : const Color(0xFF374151),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Membre depuis ${user.addedDate}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Utils.isLightMode(context)
                              ? PsColors.text600
                              : PsColors.text300,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  // Unified 4-Column Stats Card
                  Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 4.0),
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 8.0),
                    decoration: BoxDecoration(
                      color: Utils.isLightMode(context)
                          ? const Color(0xFFFAF7F2)
                          : PsColors.achromatic800,
                      borderRadius: BorderRadius.circular(14.0),
                      border: Border.all(
                        color: Utils.isLightMode(context)
                            ? const Color(0xFFEBE5DC)
                            : PsColors.achromatic700,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        _buildStorefrontCounter(
                          context,
                          count: user.activeItemCount ?? '0',
                          label: 'profile__listing'.tr,
                          onTap: () {
                            Navigator.pushNamed(context, RoutePaths.userItemList,
                                arguments: ItemListIntentHolder(
                                    userId: Utils.checkUserLoginId(psValueHolder),
                                    status: '1',
                                    title: 'profile__listing'.tr));
                          },
                        ),
                        Container(
                            width: 1,
                            height: 28,
                            color: Utils.isLightMode(context)
                                ? const Color(0xFFE0D8CE)
                                : Colors.white24),
                        _buildStorefrontCounter(
                          context,
                          count: user.followerCount ?? '0',
                          label: 'profile__follower'.tr,
                          onTap: () {
                            Navigator.pushNamed(
                                context, RoutePaths.followerUserList);
                          },
                        ),
                        Container(
                            width: 1,
                            height: 28,
                            color: Utils.isLightMode(context)
                                ? const Color(0xFFE0D8CE)
                                : Colors.white24),
                        _buildStorefrontCounter(
                          context,
                          count: user.followingCount ?? '0',
                          label: 'profile__following'.tr,
                          onTap: () {
                            Navigator.pushNamed(
                                context, RoutePaths.followingUserList);
                          },
                        ),
                        Container(
                            width: 1,
                            height: 28,
                            color: Utils.isLightMode(context)
                                ? const Color(0xFFE0D8CE)
                                : Colors.white24),
                        _buildStorefrontCounter(
                          context,
                          count: (user.overallRating != null &&
                                  user.overallRating!.isNotEmpty &&
                                  user.overallRating != '0')
                              ? '${double.tryParse(user.overallRating!)?.toStringAsFixed(1) ?? user.overallRating!} ★'
                              : (user.ratingCount != null && user.ratingCount != '0'
                                  ? user.ratingCount!
                                  : '5.0 ★'),
                          label: 'Avis ★',
                          onTap: () {
                            Navigator.pushNamed(
                                context, RoutePaths.ratingList,
                                arguments: user.userId);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildStoriesSection(
                      context, storyProvider, user, psValueHolder),
                ],
              ),
              builder: (BuildContext context, Widget? child) {
                return FadeTransition(
                    opacity: animation,
                    child: Transform(
                        transform: Matrix4.translationValues(
                            0.0, 100 * (1.0 - animation.value), 0.0),
                        child: child));
              });
        } else {
          return const SizedBox();
        }
      }),
    );
  }

  Widget _buildStorefrontCounter(
    BuildContext context, {
    required String count,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              vertical: PsDimens.space10, horizontal: 4.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                count.isEmpty ? '0' : count,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3.0),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
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

  Future<void> _confirmDeleteStory(
      BuildContext context, StoryProvider storyProvider, VendorStory story) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
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
      final bool success = await storyProvider.deleteStory(story.id ?? '');
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('story__deleted_success'.tr),
            backgroundColor: const Color(0xFFED7768),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildStoriesSection(
    BuildContext context,
    StoryProvider storyProvider,
    User user,
    PsValueHolder psValueHolder,
  ) {
    final bool isMyProfile = psValueHolder.loginUserId == user.userId;
    if (!isMyProfile) {
      return const SizedBox();
    }

    final List<VendorStory> myStories = storyProvider.myStories;

    if (myStories.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        'story__active_stories'.tr,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFED7768).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${myStories.length}',
                          style: const TextStyle(
                            color: Color(0xFFED7768),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => _pickAndComposeStory(),
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.add, size: 16, color: Color(0xFFED7768)),
                        const SizedBox(width: 2),
                        Text(
                          'story__add'.tr,
                          style: const TextStyle(
                            color: Color(0xFFED7768),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 106,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: myStories.length + 1,
                itemBuilder: (BuildContext context, int index) {
                  if (index == 0) {
                    return GestureDetector(
                      onTap: () => _pickAndComposeStory(),
                      child: Container(
                        width: 72,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFED7768).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFED7768)
                                .withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFED7768),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'story__add'.tr,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFED7768),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final VendorStory story = myStories[index - 1];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        RoutePaths.storyViewer,
                        arguments: <String, dynamic>{
                          'stories': myStories,
                          'initialIndex': index - 1,
                          'vendorName': user.name,
                          'vendorLogo': user.userCoverPhoto,
                        },
                      ).then((_) {
                        if (mounted) {
                          storyProvider.loadFeed();
                        }
                      });
                    },
                    child: Container(
                      width: 72,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color:
                              const Color(0xFFED7768).withValues(alpha: 0.8),
                          width: 1.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          fit: StackFit.expand,
                          children: <Widget>[
                            CachedNetworkImage(
                              imageUrl:
                                  story.thumbnailUrl ?? story.mediaUrl ?? '',
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: Colors.grey.shade300,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFFED7768),
                                  ),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.image,
                                    color: Colors.grey),
                              ),
                            ),
                            Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: <Color>[
                                    Colors.black54,
                                    Colors.transparent,
                                    Color(0x99000000),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              left: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${story.remainingHours ?? 24}h',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () => _confirmDeleteStory(
                                    context, storyProvider, story),
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFED7768),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 11,
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
              ),
            ),
            const SizedBox(height: 8),
            Builder(
              builder: (BuildContext bCtx) {
                final bool hasBoosted = myStories.any((VendorStory s) => s.isBoosted);
                if (hasBoosted) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F1635),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFFD166), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(Icons.bolt_rounded, color: Color(0xFFFFD166), size: 15),
                        const SizedBox(width: 5),
                        Text(
                          'ads__story_boosted_badge'.tr,
                          style: const TextStyle(
                            color: Color(0xFFFFD166),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return InkWell(
                  onTap: () async {
                    final bool boosted = await StoryBoostHelper.showBoostSheet(
                      context,
                      storyId: myStories.first.id ?? '',
                    );
                    if (boosted && mounted) {
                      storyProvider.loadFeed();
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: <Color>[Color(0xFF1F1635), Color(0xFF3E1C59)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(Icons.bolt_rounded, color: Color(0xFFFFD166), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'ads__profile_boost_story'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _pickAndComposeStory(),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                const Color(0xFFED7768).withValues(alpha: 0.12),
                const Color(0xFFED7768).withValues(alpha: 0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFED7768).withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFED7768),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      'story__add'.tr,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFFED7768),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Mettez en avant vos nouveaux articles (24h)',
                      style: TextStyle(
                        fontSize: 11,
                        color: Utils.isLightMode(context)
                            ? Colors.grey.shade700
                            : Colors.grey.shade300,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFED7768),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
