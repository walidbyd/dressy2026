import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../../../../../config/ps_colors.dart';
import '../../../../../../config/ps_config.dart';
import '../../../../../../config/route/route_paths.dart';
import '../../../../../core/vendor/api/common/ps_resource.dart';
import '../../../../../core/vendor/api/common/ps_status.dart';
import '../../../../../core/vendor/constant/ps_constants.dart';
import '../../../../../core/vendor/constant/ps_dimens.dart';
import '../../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../../core/vendor/provider/rating/rating_list_provider.dart';
import '../../../../../core/vendor/provider/story/story_provider.dart';
import '../../../../../core/vendor/provider/user/user_provider.dart';
import '../../../../../core/vendor/provider/vendor_application/vendor_branch_provider.dart';
import '../../../../../core/vendor/provider/vendor_application/vendor_item_provider.dart';
import '../../../../../core/vendor/provider/vendor_application/vendor_user_detail_provider.dart';
import '../../../../../core/vendor/provider/vendor_application/vendor_user_provider.dart';
import '../../../../../core/vendor/repository/product_repository.dart';
import '../../../../../core/vendor/repository/rating_repository.dart';
import '../../../../../core/vendor/repository/user_repository.dart';
import '../../../../../core/vendor/repository/vendor_branch_repository.dart';
import '../../../../../core/vendor/repository/vendor_user_repository.dart';
import '../../../../../core/vendor/utils/utils.dart';
import '../../../../../core/vendor/viewobject/common/ps_value_holder.dart';
import '../../../../../core/vendor/viewobject/holder/rating_list_holder.dart';
import '../../../../../core/vendor/viewobject/holder/request_path_holder.dart';
import '../../../../../core/vendor/viewobject/holder/user_follow_holder.dart';
import '../../../../../core/vendor/viewobject/user.dart';
import '../../../../../core/vendor/viewobject/vendor_story.dart';
import '../../../../../core/vendor/viewobject/vendor_user.dart';
import '../../../../custom_ui/rating/component/list/rating_list_item.dart';
import '../../../../custom_ui/user/user_vendor_detail/component/detail_info/other_user_store_detail_info_widget.dart';
import '../../../../custom_ui/user/user_vendor_detail/component/detail_info/widgets/other_user_vendor_item_card_widget.dart';
import '../../../../custom_ui/user/user_vendor_detail/component/detail_info/widgets/other_user_vendor_item_count.dart';
import '../../../../custom_ui/user/user_vendor_detail/component/detail_info/widgets/other_user_vendor_joined_datetime_widget.dart';
import '../../../../custom_ui/user/user_vendor_detail/component/detail_info/widgets/other_user_vendor_logo_photo.dart';
import '../../../../custom_ui/user/user_vendor_detail/component/vendor_info_list/vendor_profile_view.dart';
import '../../../common/dialog/error_dialog.dart';
import '../../../common/ps_app_bar_widget.dart';
import '../../../common/ps_ui_widget.dart';

class UserVendorDetailView extends StatefulWidget {
  const UserVendorDetailView({
    required this.vendorId,
    required this.vendorUserId,
    required this.vendorUserName,
  });
  final String? vendorId;
  final String? vendorUserId;
  final String? vendorUserName;
  @override
  _UserShoreDetailViewState createState() => _UserShoreDetailViewState();
}

class _UserShoreDetailViewState extends State<UserVendorDetailView>
    with TickerProviderStateMixin {
  late AnimationController animationController;
  late TabController tabController;

  ScrollController scrollController = ScrollController();

  @override
  void initState() {
    animationController =
        AnimationController(duration: PsConfig.animation_duration, vsync: this);
    tabController = TabController(length: 3, vsync: this);

    scrollController.addListener(() {
      if (scrollController.position.pixels ==
          scrollController.position.maxScrollExtent) {
        vendorItemProvider?.loadNextDataList();
      }
    });
    super.initState();
  }

  bool _storyFeedLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_storyFeedLoaded) {
      _storyFeedLoaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          try {
            Provider.of<StoryProvider>(context, listen: false).loadFeed();
          } catch (_) {}
        }
      });
    }
  }

  @override
  void dispose() {
    animationController.dispose();
    tabController.dispose();
    super.dispose();
  }

  Future<void> _pickAndComposeStory() async {
    final ImagePicker picker = ImagePicker();

    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext bContext) {
        return SafeArea(
          child: Wrap(
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
                        'vendorId': widget.vendorId,
                      },
                    ).then((_) {
                      if (mounted) {
                        Provider.of<StoryProvider>(context, listen: false).loadFeed();
                        vendorUserDetailProvider?.loadData(
                          requestPathHolder: RequestPathHolder(
                            loginUserId: Utils.checkUserLoginId(psValueHolder),
                            vendorId: widget.vendorId,
                            ownerUserId: Utils.checkUserLoginId(psValueHolder),
                          ),
                        );
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
                        'vendorId': widget.vendorId,
                      },
                    ).then((_) {
                      if (mounted) {
                        Provider.of<StoryProvider>(context, listen: false).loadFeed();
                        vendorUserDetailProvider?.loadData(
                          requestPathHolder: RequestPathHolder(
                            loginUserId: Utils.checkUserLoginId(psValueHolder),
                            vendorId: widget.vendorId,
                            ownerUserId: Utils.checkUserLoginId(psValueHolder),
                          ),
                        );
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
                        'vendorId': widget.vendorId,
                      },
                    ).then((_) {
                      if (mounted) {
                        Provider.of<StoryProvider>(context, listen: false).loadFeed();
                        vendorUserDetailProvider?.loadData(
                          requestPathHolder: RequestPathHolder(
                            loginUserId: Utils.checkUserLoginId(psValueHolder),
                            vendorId: widget.vendorId,
                            ownerUserId: Utils.checkUserLoginId(psValueHolder),
                          ),
                        );
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
        storyProvider.loadFeed();
        vendorUserDetailProvider?.loadData(
          requestPathHolder: RequestPathHolder(
            loginUserId: Utils.checkUserLoginId(psValueHolder),
            vendorId: widget.vendorId,
            ownerUserId: Utils.checkUserLoginId(psValueHolder),
          ),
        );
      }
    }
  }

  Widget _buildVendorStoriesSection({
    required BuildContext context,
    required StoryProvider storyProvider,
    required VendorUser? vendor,
    required List<VendorStory> activeStories,
    required bool isOwner,
  }) {
    final String vendorName = vendor?.name ?? widget.vendorUserName ?? 'Dressy Vendeur';
    final String? vendorLogo = vendor?.logo?.imgPath;

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
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
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFED7768).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${activeStories.length}',
                        style: const TextStyle(
                          color: Color(0xFFED7768),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (isOwner)
                  InkWell(
                    onTap: _pickAndComposeStory,
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
              itemCount: isOwner ? activeStories.length + 1 : activeStories.length,
              itemBuilder: (BuildContext context, int index) {
                if (isOwner && index == 0) {
                  return GestureDetector(
                    onTap: _pickAndComposeStory,
                    child: Container(
                      width: 72,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFED7768).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFED7768).withValues(alpha: 0.5),
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

                final int storyIndex = isOwner ? index - 1 : index;
                final VendorStory story = activeStories[storyIndex];

                return GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      RoutePaths.storyViewer,
                      arguments: <String, dynamic>{
                        'stories': activeStories,
                        'initialIndex': storyIndex,
                        'vendorName': vendorName,
                        'vendorLogo': vendorLogo,
                      },
                    ).then((_) {
                      if (mounted) {
                        storyProvider.loadFeed();
                        vendorUserDetailProvider?.loadData(
                          requestPathHolder: RequestPathHolder(
                            loginUserId: Utils.checkUserLoginId(psValueHolder),
                            vendorId: widget.vendorId,
                            ownerUserId: Utils.checkUserLoginId(psValueHolder),
                          ),
                        );
                      }
                    });
                  },
                  child: Container(
                    width: 72,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFED7768).withValues(alpha: 0.8),
                        width: 1.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: <Widget>[
                          CachedNetworkImage(
                            imageUrl: story.thumbnailUrl ?? story.mediaUrl ?? '',
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
                              child: const Icon(Icons.image, color: Colors.grey),
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
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
                          if (isOwner)
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () => _confirmDeleteStory(context, storyProvider, story),
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
        ],
      ),
    );
  }

  PsValueHolder? psValueHolder;
  late AppLocalization langProvider;
  VendorUserProvider? vendorUserProvider;
  VendorUserRepository? vendorUserRepository;
  ProductRepository? productRepository;
  VendorBranchProvider? vendorBranchProvider;
  VendorBranchRepository? vendorBranchRepository;
  VendorUserDetailProvider? vendorUserDetailProvider;
  VendorItemProvider? vendorItemProvider;
  UserRepository? userRepository;
  UserProvider? userProvider;

  Future<void> _handleFollow(
      VendorUser vendorUser, UserProvider uProvider) async {
    if (await Utils.checkInternetConnectivity()) {
      Utils.navigateOnUserVerificationView(context, () async {
        final String? loginUserId = Utils.checkUserLoginId(psValueHolder);
        if (loginUserId == null || loginUserId.isEmpty) {
          return;
        }

        final bool currentlyFollowed = vendorUser.isFollowed == '1';
        setState(() {
          vendorUser.isFollowed = currentlyFollowed ? '0' : '1';
          final int count = int.tryParse(vendorUser.followerCount ?? '0') ?? 0;
          vendorUser.followerCount = (currentlyFollowed
                  ? (count > 0 ? count - 1 : 0)
                  : (count + 1))
              .toString();
        });

        final UserFollowHolder holder = UserFollowHolder(
            userId: loginUserId, followedUserId: vendorUser.ownerUserId);

        final PsResource<User> res = await uProvider.postUserFollow(
            holder.toMap(),
            loginUserId,
            langProvider.currentLocale.languageCode);

        if (res.data != null && mounted) {
          setState(() {
            vendorUser.isFollowed = res.data!.isFollowed;
            if (res.data!.followerCount != null) {
              vendorUser.followerCount = res.data!.followerCount;
            }
          });
          vendorUserDetailProvider?.vendorUserDetail.data?.isFollowed = res.data!.isFollowed;
          if (res.data!.followerCount != null) {
            vendorUserDetailProvider?.vendorUserDetail.data?.followerCount = res.data!.followerCount;
          }
        }
      });
    } else {
      showDialog<dynamic>(
          context: context,
          builder: (BuildContext context) {
            return ErrorDialog(
              message: 'error_dialog__no_internet'.tr,
            );
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    vendorBranchRepository = Provider.of<VendorBranchRepository>(context);
    vendorUserRepository = Provider.of<VendorUserRepository>(context);
    productRepository = Provider.of<ProductRepository>(context);
    langProvider = Provider.of<AppLocalization>(context);
    psValueHolder = Provider.of<PsValueHolder>(context);
    userRepository = Provider.of<UserRepository>(context);

    Future<bool> _requestPop() {
      animationController.reverse().then<dynamic>(
        (void data) {
          if (!mounted) {
            return Future<bool>.value(false);
          }
          Navigator.pop(context, true);
          return Future<bool>.value(true);
        },
      );
      return Future<bool>.value(false);
    }

    return MultiProvider(
        providers: <SingleChildWidget>[
          ChangeNotifierProvider<VendorUserDetailProvider?>(
              lazy: false,
              create: (BuildContext context) {
                vendorUserDetailProvider = VendorUserDetailProvider(
                    repo: vendorUserRepository, psValueHolder: psValueHolder);
                vendorUserDetailProvider?.loadData(
                    requestPathHolder: RequestPathHolder(
                  loginUserId: Utils.checkUserLoginId(psValueHolder),
                  vendorId: widget.vendorId,
                  ownerUserId: Utils.checkUserLoginId(psValueHolder),
                ));
                return vendorUserDetailProvider;
              }),
          ChangeNotifierProvider<VendorItemProvider?>(
              lazy: false,
              create: (BuildContext context) {
                vendorItemProvider = VendorItemProvider(
                  context: context,
                );
                vendorItemProvider?.getVendorItemParameterHolder.vendorId =
                    widget.vendorId;
                vendorItemProvider?.loadDataList(
                    requestPathHolder: RequestPathHolder(
                        loginUserId: Utils.checkUserLoginId(psValueHolder),
                        languageCode: langProvider.currentLocale.languageCode),
                    requestBodyHolder:
                        vendorItemProvider?.getVendorItemParameterHolder);
                return vendorItemProvider;
              }),
          ChangeNotifierProvider<VendorBranchProvider>(
              lazy: false,
              create: (BuildContext context) {
                final VendorBranchProvider vendorUserProvider =
                    VendorBranchProvider(
                  repo: vendorBranchRepository,
                );
                vendorUserProvider.vendorBranchParameterHolder.vendorId =
                    widget.vendorId;
                vendorUserProvider.loadDataList(
                    requestBodyHolder:
                        vendorUserProvider.vendorBranchParameterHolder,
                    requestPathHolder: RequestPathHolder(
                        loginUserId: Utils.checkUserLoginId(psValueHolder),
                        languageCode: langProvider.currentLocale.languageCode));
                return vendorUserProvider;
              }),
          ChangeNotifierProvider<UserProvider>(
              lazy: false,
              create: (BuildContext context) {
                userProvider = UserProvider(
                  repo: userRepository,
                  psValueHolder: psValueHolder,
                );
                return userProvider!;
              }),
        ],
        child: Consumer4<VendorUserDetailProvider, VendorBranchProvider,
                VendorItemProvider, UserProvider>(
            builder: (BuildContext context,
                VendorUserDetailProvider vendorUserDetailProvider,
                VendorBranchProvider vendorBranchProvider,
                VendorItemProvider vendorItemProvider,
                UserProvider userProvider,
                Widget? child) {
          final VendorUser? vendor =
              vendorUserDetailProvider.vendorUserDetail.data;
          final String loginUserId =
              Utils.checkUserLoginId(psValueHolder);
          final bool isOwner = vendor != null &&
              vendor.ownerUserId != null &&
              loginUserId.isNotEmpty &&
              loginUserId != 'nologinuser' &&
              vendor.ownerUserId == loginUserId;

          final StoryProvider storyProvider =
              Provider.of<StoryProvider>(context);

          final List<VendorStory> activeStories = <VendorStory>[];
          if (isOwner && storyProvider.myStories.isNotEmpty) {
            activeStories.addAll(storyProvider.myStories);
          } else if (vendor?.stories != null && vendor!.stories!.isNotEmpty) {
            activeStories.addAll(vendor.stories!);
          } else {
            for (final VendorStoriesGroup g in storyProvider.storiesByVendor) {
              if ((widget.vendorId != null && widget.vendorId!.isNotEmpty && g.vendorId == widget.vendorId) ||
                  (vendor?.ownerUserId != null && vendor!.ownerUserId!.isNotEmpty && (g.userId == vendor.ownerUserId || g.vendorId == vendor.ownerUserId))) {
                activeStories.addAll(g.stories);
                break;
              }
            }
          }

          final bool showStoriesSection = isOwner || activeStories.isNotEmpty;
          final double baseExpandedHeight =
              MediaQuery.of(context).size.height / 2.05;
          final double expandedHeight =
              showStoriesSection ? (baseExpandedHeight + 150.0) : baseExpandedHeight;

          return PopScope(
              canPop: true,
              onPopInvokedWithResult: (bool didPop, Object? dynamic) async {
                if (didPop) {
                  return;
                }
                _requestPop();
              },
              child: DefaultTabController(
                length: 3,
                child: Scaffold(
                  appBar: PsAppbarWidget(
                    appBarTitle: widget.vendorUserName ?? '',
                  ),
                  body: NestedScrollView(
                    controller: scrollController,
                    headerSliverBuilder:
                        (BuildContext context, bool innerBoxIsScrolled) {
                      return <Widget>[
                        SliverAppBar(
                          automaticallyImplyLeading: false,
                          floating: true,
                          pinned: false,
                          expandedHeight: expandedHeight,
                          flexibleSpace: FlexibleSpaceBar(
                              background: Column(
                            children: <Widget>[
                              Container(
                                height:
                                    MediaQuery.of(context).size.height / 2.5,
                                child: Stack(
                                  children: <Widget>[
                                    if (vendorUserDetailProvider.hasData)
                                      CustomOtherUserVendorDetailWidget(
                                        animationController:
                                            animationController,
                                      )
                                    else
                                      const SizedBox(),
                                    Positioned(
                                      right: PsDimens.space16,
                                      left: PsDimens.space16,
                                      bottom: 0,
                                      child: Card(
                                        elevation: PsDimens.space2,
                                        color: Utils.isLightMode(context)
                                            ? PsColors.achromatic50
                                            : PsColors.achromatic800,
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                PsDimens.space8)),
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: PsDimens.space8,
                                              horizontal: PsDimens.space12),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: <Widget>[
                                              // Vendor Name + Icon + Star Rating Badge
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: <Widget>[
                                                  Flexible(
                                                    child: Text(
                                                      vendor?.name ?? '',
                                                      textAlign:
                                                          TextAlign.start,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleLarge
                                                          ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontSize: 16),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: PsDimens
                                                                .space4),
                                                    child: Image.asset(
                                                      'assets/images/storefont.png',
                                                      width: PsDimens.space16,
                                                      height: PsDimens.space16,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                  // Star Rating Badge (tappable -> ratingList)
                                                  InkWell(
                                                    onTap: () async {
                                                      if (vendor?.ownerUserId !=
                                                              null &&
                                                          vendor!.ownerUserId!
                                                              .isNotEmpty) {
                                                        await Navigator.pushNamed(
                                                          context,
                                                          RoutePaths.ratingList,
                                                          arguments:
                                                              vendor.ownerUserId,
                                                        );
                                                        if (mounted) {
                                                          vendorUserDetailProvider.loadData(
                                                            requestPathHolder: RequestPathHolder(
                                                              loginUserId: Utils.checkUserLoginId(psValueHolder),
                                                              vendorId: widget.vendorId,
                                                              ownerUserId: Utils.checkUserLoginId(psValueHolder),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    },
                                                    child: Container(
                                                      margin:
                                                          const EdgeInsets.only(
                                                              left: PsDimens
                                                                  .space6),
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal:
                                                              PsDimens.space6,
                                                          vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: Colors.amber
                                                            .withValues(alpha: 0.15),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        border: Border.all(
                                                          color: Colors
                                                              .amber.shade400,
                                                          width: 0.8,
                                                        ),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: <Widget>[
                                                          const Icon(
                                                            Icons.star,
                                                            color: Colors.amber,
                                                            size: 14,
                                                          ),
                                                          const SizedBox(
                                                              width: 2),
                                                          Text(
                                                            '${(vendor?.overallRating == null || vendor?.overallRating == '' || vendor?.overallRating == '0') ? '0.0' : vendor!.overallRating} (${vendor?.ratingCount ?? '0'})',
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 11,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  Colors.amber,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(
                                                  height: PsDimens.space6),
                                              // Stats Row: Products, Followers, Following, Joined Date
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceEvenly,
                                                children: <Widget>[
                                                  CustomOtherUserVendorItemCount(),
                                                  // Followers Count (Tappable)
                                                  InkWell(
                                                    onTap: () {
                                                      if (vendor?.ownerUserId !=
                                                              null &&
                                                          vendor!.ownerUserId!
                                                              .isNotEmpty) {
                                                        Navigator.pushNamed(
                                                          context,
                                                          RoutePaths
                                                              .detailfollowerUserList,
                                                          arguments: vendor
                                                              .ownerUserId,
                                                        );
                                                      }
                                                    },
                                                    child: Column(
                                                      children: <Widget>[
                                                        Text(
                                                          vendor?.followerCount ??
                                                              '0',
                                                          textAlign:
                                                              TextAlign.start,
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .titleLarge
                                                                  ?.copyWith(
                                                                      fontSize:
                                                                          12,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600),
                                                          maxLines: 1,
                                                        ),
                                                        Text(
                                                          'profile__follower'
                                                              .tr,
                                                          textAlign:
                                                              TextAlign.start,
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodyLarge
                                                                  ?.copyWith(
                                                                      fontSize:
                                                                          12,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w400),
                                                          maxLines: 1,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  // Following Count (Tappable)
                                                  InkWell(
                                                    onTap: () {
                                                      if (vendor?.ownerUserId !=
                                                              null &&
                                                          vendor!.ownerUserId!
                                                              .isNotEmpty) {
                                                        Navigator.pushNamed(
                                                          context,
                                                          RoutePaths
                                                              .detailfollowingUserList,
                                                          arguments: vendor
                                                              .ownerUserId,
                                                        );
                                                      }
                                                    },
                                                    child: Column(
                                                      children: <Widget>[
                                                        Text(
                                                          vendor?.followingCount ??
                                                              '0',
                                                          textAlign:
                                                              TextAlign.start,
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .titleLarge
                                                                  ?.copyWith(
                                                                      fontSize:
                                                                          12,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600),
                                                          maxLines: 1,
                                                        ),
                                                        Text(
                                                          'profile__following'
                                                              .tr,
                                                          textAlign:
                                                              TextAlign.start,
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodyLarge
                                                                  ?.copyWith(
                                                                      fontSize:
                                                                          12,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w400),
                                                          maxLines: 1,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  CustomOtherUserVendorJoinDateTimeWidget(),
                                                ],
                                              ),
                                              // Follow / Unfollow Button (if not owner)
                                              if (!isOwner && vendor != null)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: PsDimens.space6),
                                                  child: SizedBox(
                                                    height: 28,
                                                    child: ElevatedButton(
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor: vendor
                                                                    .isFollowed ==
                                                                '1'
                                                            ? PsColors
                                                                .achromatic200
                                                            : PsColors
                                                                .primary500,
                                                        elevation: 0,
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal:
                                                                    PsDimens
                                                                        .space16),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(14),
                                                        ),
                                                      ),
                                                      onPressed: () =>
                                                          _handleFollow(
                                                              vendor,
                                                              userProvider),
                                                      child: Text(
                                                        vendor.isFollowed == '1'
                                                            ? 'user_detail__unfollow'
                                                                .tr
                                                            : 'profile__follow'
                                                                .tr,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: vendor
                                                                      .isFollowed ==
                                                                  '1'
                                                              ? PsColors
                                                                  .text800
                                                              : Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      alignment: Alignment.center,
                                      child: Stack(children: <Widget>[
                                        CustomOtherUserVendorLogoPhoto(),
                                        Positioned(
                                          right: -1,
                                          bottom: -1,
                                          child: Icon(
                                            Icons.verified_user,
                                            color: PsColors.info500,
                                            size: PsDimens.space16,
                                          ),
                                        ),
                                      ]),
                                    ),
                                  ],
                                ),
                              ),
                              if (showStoriesSection)
                                _buildVendorStoriesSection(
                                  context: context,
                                  storyProvider: storyProvider,
                                  vendor: vendor,
                                  activeStories: activeStories,
                                  isOwner: isOwner,
                                ),
                              TabBar(
                                labelColor: PsColors.primary500,
                                indicatorColor: PsColors.primary500,
                                indicatorSize: TabBarIndicatorSize.tab,
                                tabs: <Widget>[
                                  Tab(
                                    text: 'vendor_home'.tr,
                                  ),
                                  Tab(
                                    text: 'vendor_profile'.tr,
                                  ),
                                  Tab(
                                    text: 'vendor_reviews'.tr,
                                  ),
                                ],
                              ),
                            ],
                          )),
                        ),
                      ];
                    },
                    body: TabBarView(children: <Widget>[
                      CustomOtherUserVendorItemCardWidget(
                        isLoading: vendorItemProvider.currentStatus ==
                            PsStatus.BLOCK_LOADING,
                      ),
                      CustomVendorProfileView(),
                      VendorReviewsTabWidget(
                        ownerUserId: vendor?.ownerUserId ?? '',
                      ),
                    ]),
                  ),
                ),
              ));
        }));
  }
}

class VendorReviewsTabWidget extends StatefulWidget {
  const VendorReviewsTabWidget({Key? key, required this.ownerUserId})
      : super(key: key);
  final String ownerUserId;

  @override
  _VendorReviewsTabWidgetState createState() => _VendorReviewsTabWidgetState();
}

class _VendorReviewsTabWidgetState extends State<VendorReviewsTabWidget> {
  RatingRepository? ratingRepo;
  RatingListProvider? ratingListProvider;
  PsValueHolder? psValueHolder;
  late AppLocalization langProvider;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        ratingListProvider?.loadNextDataList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ratingRepo = Provider.of<RatingRepository>(context);
    psValueHolder = Provider.of<PsValueHolder>(context);
    langProvider = Provider.of<AppLocalization>(context);

    if (widget.ownerUserId.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(PsDimens.space24),
          child: Text(
            'rating_list__no_rating'.tr,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    return ChangeNotifierProvider<RatingListProvider?>(
      lazy: false,
      create: (BuildContext context) {
        ratingListProvider = RatingListProvider(repo: ratingRepo);
        final RatingListHolder holder = RatingListHolder(
          userId: widget.ownerUserId,
          type: PsConst.RATING_TYPE_USER,
        );
        ratingListProvider?.loadDataList(
          requestBodyHolder: holder,
          requestPathHolder: RequestPathHolder(
            loginUserId: Utils.checkUserLoginId(psValueHolder),
            headerToken: psValueHolder?.headerToken ?? '',
            languageCode: langProvider.currentLocale.languageCode,
          ),
        );
        return ratingListProvider;
      },
      child: Consumer<RatingListProvider>(
        builder: (BuildContext context, RatingListProvider provider,
            Widget? child) {
          if (provider.currentStatus == PsStatus.BLOCK_LOADING ||
              provider.currentStatus == PsStatus.PROGRESS_LOADING) {
            return Center(child: PSProgressIndicator(provider.currentStatus));
          }

          if (!provider.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.rate_review_outlined,
                    size: 64,
                    color: PsColors.achromatic300,
                  ),
                  const SizedBox(height: PsDimens.space12),
                  Text(
                    'rating_list__no_rating'.tr,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: PsColors.achromatic500),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await provider.loadDataList(reset: true);
            },
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(
                  horizontal: PsDimens.space8, vertical: PsDimens.space12),
              itemCount: provider.dataLength,
              itemBuilder: (BuildContext context, int index) {
                return CustomRatingListItem(
                  rating: provider.getListIndexOf(index),
                  itemUserId: widget.ownerUserId,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
