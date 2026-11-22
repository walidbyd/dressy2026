import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import '../../../../../../config/ps_colors.dart';
import '../../../../../../config/route/route_paths.dart';
import '../../../../../../core/vendor/api/common/ps_status.dart';
import '../../../../../../core/vendor/constant/ps_constants.dart';
import '../../../../../../core/vendor/constant/ps_dimens.dart';
import '../../../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../../../core/vendor/provider/story/story_provider.dart';
import '../../../../../../core/vendor/provider/vendor/search_vendor_provider.dart';
import '../../../../../../core/vendor/repository/vendor_search_repository.dart';
import '../../../../../../core/vendor/utils/utils.dart';
import '../../../../../../core/vendor/viewobject/common/ps_value_holder.dart';
import '../../../../../../core/vendor/viewobject/holder/intent_holder/vendor_user_intent_holder.dart';
import '../../../../../../core/vendor/viewobject/holder/request_path_holder.dart';
import '../../../../../../core/vendor/viewobject/holder/vendor_search_parameter_holder.dart';
import '../../../../../../core/vendor/viewobject/vendor_story.dart';
import '../../../../../../core/vendor/viewobject/vendor_user.dart';
import '../../../../common/ps_ui_widget.dart';

class LatestVendorListWidget extends StatefulWidget {
  const LatestVendorListWidget({Key? key, required this.animationController})
      : super(key: key);

  final AnimationController? animationController;

  @override
  State<LatestVendorListWidget> createState() => _LatestVendorListWidgetState();
}

class _LatestVendorListWidgetState extends State<LatestVendorListWidget> {
  VendorSearchProvider? vendorSearchProvider;
  VendorSearchRepository? vendorSearchRepository;
  late VendorSearchParameterHolder vendorSearchParameterHolder;
  bool _hasLoadedStories = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoadedStories) {
      _hasLoadedStories = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Provider.of<StoryProvider>(context, listen: false).loadFeed();
        }
      });
    }
  }

  Future<void> _pickAndComposeStory(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bContext) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
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
                      Provider.of<StoryProvider>(context, listen: false).loadFeed();
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
                      Provider.of<StoryProvider>(context, listen: false).loadFeed();
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
                      Provider.of<StoryProvider>(context, listen: false).loadFeed();
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

    return GestureDetector(
      onTap: () {
        if (hasStories) {
          Navigator.pushNamed(
            context,
            RoutePaths.storyViewer,
            arguments: <String, dynamic>{
              'stories': storyProvider.myStories,
              'vendorName': valueHolder.loginUserName ?? 'story__my_story'.tr,
              'vendorLogo': '',
            },
          ).then((_) {
            storyProvider.loadFeed();
          });
        } else {
          _pickAndComposeStory(context);
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
                    child: const ClipOval(
                      child: Icon(
                        Icons.person_rounded,
                        size: 32,
                        color: Color(0xFFED7768),
                      ),
                    ),
                  ),
                ),
                // Small + Add badge on bottom right
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: () => _pickAndComposeStory(context),
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

  Widget _buildVendorStoryItem(
      BuildContext context, VendorUser vendor, bool isLoading, StoryProvider storyProvider) {
    if (isLoading) {
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

    final VendorStoriesGroup? group = storyProvider.storiesByVendor.firstWhere(
      (VendorStoriesGroup g) =>
          (vendor.id != null && g.vendorId == vendor.id) ||
          (vendor.ownerUserId != null && g.vendorUserId == vendor.ownerUserId),
      orElse: () => VendorStoriesGroup(),
    );

    final List<VendorStory> vendorStories = (group != null && group.stories.isNotEmpty)
        ? group.stories
        : (vendor.stories ?? <VendorStory>[]);
    final bool hasStories = vendorStories.isNotEmpty || (vendor.hasActiveStories == true);

    return GestureDetector(
      onTap: () {
        if (hasStories && vendorStories.isNotEmpty) {
          Navigator.pushNamed(
            context,
            RoutePaths.storyViewer,
            arguments: <String, dynamic>{
              'stories': vendorStories,
              'vendorName': vendor.name,
              'vendorLogo': vendor.logo?.imgPath,
            },
          ).then((_) {
            storyProvider.loadFeed();
          });
        } else {
          Navigator.pushNamed(
            context,
            RoutePaths.userVendorDetail,
            arguments: VendorUserIntentHolder(
              vendorId: vendor.id,
              vendorUserId: vendor.ownerUserId,
              vendorUserName: vendor.name,
            ),
          );
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
                // Coral gradient ring for vendors with active stories
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
                            color: Utils.isLightMode(context)
                                ? Colors.grey.shade300
                                : Colors.grey.shade700,
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
                      child: PsNetworkImage(
                        photoKey: '',
                        defaultPhoto: vendor.logo,
                        boxfit: BoxFit.cover,
                        imageAspectRation: PsConst.Aspect_Ratio_1x,
                      ),
                    ),
                  ),
                ),
                // Small verified checkmark badge at bottom-right
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(1.5),
                    decoration: BoxDecoration(
                      color: Utils.isLightMode(context)
                          ? PsColors.backgroundColor
                          : PsColors.achromatic800,
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
                vendor.name == null || vendor.name!.isEmpty
                    ? 'default__user_name'.tr
                    : vendor.name!,
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

  @override
  Widget build(BuildContext context) {
    vendorSearchParameterHolder = VendorSearchParameterHolder().getAllVendor();
    vendorSearchRepository = Provider.of<VendorSearchRepository>(context);
    final PsValueHolder valueHolder =
        Provider.of<PsValueHolder>(context, listen: false);
    final StoryProvider storyProvider = Provider.of<StoryProvider>(context);

    final bool isUserLoggedIn = Utils.checkUserLoginId(valueHolder) != 'nologinuser' &&
        Utils.checkUserLoginId(valueHolder).isNotEmpty;

    return MultiProvider(
      providers: <SingleChildWidget>[
        ChangeNotifierProvider<VendorSearchProvider?>(
            lazy: false,
            create: (BuildContext context) {
              vendorSearchProvider = VendorSearchProvider(
                repo: vendorSearchRepository,
              );
              final VendorSearchParameterHolder vendorSearchParameterHolder =
                  VendorSearchParameterHolder().getAllVendor();
              vendorSearchProvider!.loadDataList(
                  requestPathHolder: RequestPathHolder(
                      loginUserId: Utils.checkUserLoginId(valueHolder),
                      ownerUserId: Utils.checkUserLoginId(valueHolder)),
                  requestBodyHolder: vendorSearchParameterHolder);

              return vendorSearchProvider;
            }),
      ],
      child: SliverToBoxAdapter(child: Consumer<VendorSearchProvider>(
        builder: (BuildContext context, VendorSearchProvider provider,
            Widget? child) {
          final bool isLoading =
              provider.currentStatus == PsStatus.BLOCK_LOADING;
          final List<VendorUser> activeVendors = (provider.vendorList.data ?? <VendorUser>[])
              .where((VendorUser v) => v.status == '2' && (int.tryParse(v.productCount ?? '0') ?? 0) >= 1)
              .toList();
          final int vendorCount = isLoading
              ? valueHolder.loadingShimmerItemCount!
              : activeVendors.length;

          if (!isLoading && activeVendors.isEmpty && !isUserLoggedIn) {
            return const SizedBox();
          }

          final int totalItems = isUserLoggedIn ? vendorCount + 1 : vendorCount;

          return ((provider.currentStatus == PsStatus.BLOCK_LOADING ||
                      activeVendors.isNotEmpty || isUserLoggedIn) &&
                  valueHolder.vendorFeatureSetting == PsConst.ONE)
              ? Column(children: <Widget>[
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
                  // Instagram-Style Stories List with "Ma Story" at index 0
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
                          final int vendorIndex = isUserLoggedIn ? index - 1 : index;
                          if (isLoading) {
                            return _buildVendorStoryItem(
                                context, VendorUser(), true, storyProvider);
                          }
                          final VendorUser vendor = activeVendors[vendorIndex];
                          return _buildVendorStoryItem(
                              context, vendor, false, storyProvider);
                        }),
                  ),
                ])
              : const SizedBox();
        },
      )),
    );
  }
}
