import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../../config/ps_config.dart';
import '../api/common/ps_resource.dart';
import '../api/common/ps_status.dart';
import '../api/ps_url.dart';
import '../viewobject/common/ps_value_holder.dart';
import '../viewobject/product.dart';
import '../viewobject/vendor_story.dart';

class StoryFeedResult {
  StoryFeedResult({
    this.myStories = const <VendorStory>[],
    this.storiesByVendor = const <VendorStoriesGroup>[],
    this.totalActive = 0,
  });

  final List<VendorStory> myStories;
  final List<VendorStoriesGroup> storiesByVendor;
  final int totalActive;
}

class StoryRepository {
  StoryRepository({required this.psValueHolder});

  final PsValueHolder? psValueHolder;

  Map<String, String> _buildHeaders(String loginUserId, [String? headerToken]) {
    final Map<String, String> headers = <String, String>{
      'Authorization': PsConfig.ps_bearer_token,
      'Accept': 'application/json',
      'login_user_id': loginUserId,
    };
    if (headerToken != null && headerToken.isNotEmpty) {
      headers['headerToken'] = headerToken;
    }
    return headers;
  }

  Future<PsResource<StoryFeedResult>> getStoriesFeed(
      String loginUserId, String headerToken) async {
    try {
      final String url =
          '${PsConfig.ps_app_url}${PsUrl.ps_stories_feed_url}login_user_id=$loginUserId';

      final http.Response response = await http.get(
        Uri.parse(url),
        headers: _buildHeaders(loginUserId, headerToken),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded != null && decoded['status'] == 'success' && decoded['data'] != null) {
          final dynamic data = decoded['data'];

          final List<dynamic>? rawMyStories = data['my_stories'] as List<dynamic>?;
          final List<VendorStory> myStories = rawMyStories != null
              ? VendorStory().fromMapList(rawMyStories)
              : <VendorStory>[];

          final List<dynamic>? rawVendors = data['stories_by_vendor'] as List<dynamic>?;
          final List<VendorStoriesGroup> storiesByVendor = <VendorStoriesGroup>[];
          if (rawVendors != null) {
            for (final dynamic v in rawVendors) {
              storiesByVendor.add(VendorStoriesGroup.fromMap(v));
            }
          }

          final int totalActive = int.tryParse(data['total_active']?.toString() ?? '0') ?? 0;

          return PsResource<StoryFeedResult>(
            PsStatus.SUCCESS,
            '',
            StoryFeedResult(
              myStories: myStories,
              storiesByVendor: storiesByVendor,
              totalActive: totalActive,
            ),
          );
        }
      }
      return PsResource<StoryFeedResult>(PsStatus.ERROR, 'Failed to load stories feed', null);
    } catch (e) {
      return PsResource<StoryFeedResult>(PsStatus.ERROR, e.toString(), null);
    }
  }

  Future<PsResource<List<Product>>> getMyItems(
      String loginUserId, String headerToken) async {
    try {
      final String url =
          '${PsConfig.ps_app_url}${PsUrl.ps_stories_my_items_url}?login_user_id=$loginUserId';

      final http.Response response = await http.get(
        Uri.parse(url),
        headers: _buildHeaders(loginUserId, headerToken),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        List<dynamic>? list;
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map && decoded['data'] is List) {
          list = decoded['data'] as List<dynamic>;
        }
        if (list != null) {
          final List<Product> items = Product().fromMapList(list);
          return PsResource<List<Product>>(PsStatus.SUCCESS, '', items);
        }
      }
      return PsResource<List<Product>>(
          PsStatus.ERROR, 'Failed to load items (${response.statusCode})', null);
    } catch (e) {
      return PsResource<List<Product>>(PsStatus.ERROR, e.toString(), null);
    }
  }

  Future<PsResource<VendorStory>> uploadStory({
    required File mediaFile,
    required String mediaType,
    required String loginUserId,
    required String headerToken,
    String? caption,
    String? itemId,
    String? filterPreset,
    int? duration,
    File? thumbnailFile,
  }) async {
    try {
      const String url = '${PsConfig.ps_app_url}${PsUrl.ps_stories_upload_url}';
      final http.MultipartRequest request =
          http.MultipartRequest('POST', Uri.parse(url));

      request.headers.addAll(_buildHeaders(loginUserId, headerToken));
      request.fields['login_user_id'] = loginUserId;
      request.fields['media_type'] = mediaType;
      request.fields['filter_preset'] = filterPreset ?? 'original';
      request.fields['duration'] = (duration ?? (mediaType == 'video' ? 15 : 5)).toString();

      if (caption != null && caption.isNotEmpty) {
        request.fields['caption'] = caption;
      }
      if (itemId != null && itemId.isNotEmpty) {
        request.fields['item_id'] = itemId;
      }

      request.files.add(
        await http.MultipartFile.fromPath('media_file', mediaFile.path),
      );

      if (thumbnailFile != null && thumbnailFile.existsSync()) {
        request.files.add(
          await http.MultipartFile.fromPath('thumbnail_file', thumbnailFile.path),
        );
      }

      final http.StreamedResponse streamedResponse =
          await request.send().timeout(const Duration(seconds: 45));
      final http.Response response = await http.Response.fromStream(streamedResponse);

      try {
        final dynamic decoded = jsonDecode(response.body);
        if (response.statusCode == 200 || response.statusCode == 201) {
          if (decoded != null && decoded['status'] == 'success' && decoded['data'] != null) {
            final VendorStory story = VendorStory().fromMap(decoded['data']);
            return PsResource<VendorStory>(PsStatus.SUCCESS, '', story);
          }
        }
        final String errorMsg = decoded?['message']?.toString() ??
            'Erreur de publication (${response.statusCode})';
        return PsResource<VendorStory>(PsStatus.ERROR, errorMsg, null);
      } catch (_) {
        return PsResource<VendorStory>(
          PsStatus.ERROR,
          'Erreur serveur (${response.statusCode}): ${response.body.isNotEmpty ? response.body : 'Réponse vide'}',
          null,
        );
      }
    } catch (e) {
      return PsResource<VendorStory>(PsStatus.ERROR, e.toString(), null);
    }
  }

  Future<bool> deleteStory(
      String storyId, String loginUserId, String headerToken) async {
    try {
      final String url =
          '${PsConfig.ps_app_url}${PsUrl.ps_stories_base_url}$storyId?login_user_id=$loginUserId';

      final http.Response response = await http.delete(
        Uri.parse(url),
        headers: _buildHeaders(loginUserId, headerToken),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        return decoded != null && decoded['status'] == 'success';
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> recordView(
      String storyId, String loginUserId, String headerToken) async {
    try {
      final String url =
          '${PsConfig.ps_app_url}${PsUrl.ps_stories_base_url}$storyId/view?login_user_id=$loginUserId';

      await http.post(
        Uri.parse(url),
        headers: _buildHeaders(loginUserId, headerToken),
      ).timeout(const Duration(seconds: 10));
    } catch (_) {}
  }
}
