import 'dart:io';
import 'package:flutter/material.dart';
import '../../api/common/ps_resource.dart';
import '../../api/common/ps_status.dart';
import '../../repository/story_repository.dart';
import '../../viewobject/common/ps_value_holder.dart';
import '../../viewobject/vendor_story.dart';

class StoryProvider extends ChangeNotifier {
  StoryProvider({
    required this.repo,
    required this.psValueHolder,
  });

  final StoryRepository repo;
  final PsValueHolder? psValueHolder;

  bool isLoading = false;
  List<VendorStory> myStories = <VendorStory>[];
  List<VendorStoriesGroup> storiesByVendor = <VendorStoriesGroup>[];
  int totalActive = 0;

  bool get hasMyActiveStories => myStories.isNotEmpty;
  int get myActiveStoriesCount => myStories.length;

  Future<void> loadFeed() async {
    final String loginUserId = psValueHolder?.loginUserId ?? '';
    final String headerToken = psValueHolder?.headerToken ?? '';

    isLoading = true;
    notifyListeners();

    final PsResource<StoryFeedResult> resource =
        await repo.getStoriesFeed(loginUserId, headerToken);

    isLoading = false;
    if (resource.status == PsStatus.SUCCESS && resource.data != null) {
      myStories = resource.data!.myStories;
      storiesByVendor = resource.data!.storiesByVendor;
      totalActive = resource.data!.totalActive;
    }
    notifyListeners();
  }

  Future<PsResource<VendorStory>> uploadStory({
    required File mediaFile,
    required String mediaType,
    String? caption,
    String? itemId,
    String? filterPreset,
    int? duration,
    File? thumbnailFile,
  }) async {
    final String loginUserId = psValueHolder?.loginUserId ?? '';
    final String headerToken = psValueHolder?.headerToken ?? '';

    isLoading = true;
    notifyListeners();

    final PsResource<VendorStory> resource = await repo.uploadStory(
      mediaFile: mediaFile,
      mediaType: mediaType,
      loginUserId: loginUserId,
      headerToken: headerToken,
      caption: caption,
      itemId: itemId,
      filterPreset: filterPreset,
      duration: duration,
      thumbnailFile: thumbnailFile,
    );

    isLoading = false;
    if (resource.status == PsStatus.SUCCESS && resource.data != null) {
      myStories.add(resource.data!);
      notifyListeners();
    } else {
      notifyListeners();
    }
    return resource;
  }

  Future<bool> deleteStory(String storyId) async {
    final String loginUserId = psValueHolder?.loginUserId ?? '';
    final String headerToken = psValueHolder?.headerToken ?? '';

    final bool success = await repo.deleteStory(storyId, loginUserId, headerToken);
    if (success) {
      myStories.removeWhere((VendorStory s) => s.id == storyId);
      for (final VendorStoriesGroup g in storiesByVendor) {
        g.stories.removeWhere((VendorStory s) => s.id == storyId);
      }
      storiesByVendor.removeWhere((VendorStoriesGroup g) => g.stories.isEmpty);
      notifyListeners();
    }
    return success;
  }

  Future<void> recordView(String storyId) async {
    final String loginUserId = psValueHolder?.loginUserId ?? '';
    final String headerToken = psValueHolder?.headerToken ?? '';
    await repo.recordView(storyId, loginUserId, headerToken);
  }
}
