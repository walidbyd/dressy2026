import 'package:quiver/core.dart';
import 'common/ps_object.dart';

class TaggedItem {
  TaggedItem({
    this.id,
    this.title,
    this.price,
    this.originalPrice,
    this.currencySymbol,
    this.photo,
  });

  String? id;
  String? title;
  String? price;
  String? originalPrice;
  String? currencySymbol;
  String? photo;

  TaggedItem fromMap(dynamic dynamicData) {
    if (dynamicData != null) {
      return TaggedItem(
        id: dynamicData['id']?.toString(),
        title: dynamicData['title']?.toString(),
        price: dynamicData['price']?.toString(),
        originalPrice: dynamicData['original_price']?.toString(),
        currencySymbol: dynamicData['currency_symbol']?.toString() ?? 'DZD',
        photo: dynamicData['photo']?.toString(),
      );
    }
    return TaggedItem();
  }

  Map<String, dynamic> toMap(TaggedItem object) {
    return <String, dynamic>{
      'id': object.id,
      'title': object.title,
      'price': object.price,
      'original_price': object.originalPrice,
      'currency_symbol': object.currencySymbol,
      'photo': object.photo,
    };
  }
}

class VendorStory extends PsObject<VendorStory> {
  VendorStory({
    this.id,
    this.userId,
    this.vendorId,
    this.vendorName,
    this.vendorLogo,
    this.userName,
    this.userPhoto,
    this.mediaType,
    this.mediaUrl,
    this.thumbnailUrl,
    this.caption,
    this.itemId,
    this.item,
    this.filterPreset,
    this.viewsCount,
    this.duration,
    this.createdAt,
    this.expiresAt,
    this.remainingHours,
    this.timeAgo,
    this.isOwner = false,
  });

  String? id;
  String? userId;
  String? vendorId;
  String? vendorName;
  String? vendorLogo;
  String? userName;
  String? userPhoto;
  String? mediaType;
  String? mediaUrl;
  String? thumbnailUrl;
  String? caption;
  String? itemId;
  TaggedItem? item;
  String? filterPreset;
  int? viewsCount;
  int? duration;
  String? createdAt;
  String? expiresAt;
  int? remainingHours;
  String? timeAgo;
  bool isOwner;

  @override
  bool operator ==(dynamic other) => other is VendorStory && id == other.id;

  @override
  int get hashCode => hash2(id.hashCode, id.hashCode);

  @override
  String getPrimaryKey() => id ?? '';

  @override
  VendorStory fromMap(dynamic dynamicData) {
    if (dynamicData != null) {
      return VendorStory(
        id: dynamicData['id']?.toString(),
        userId: dynamicData['user_id']?.toString(),
        vendorId: dynamicData['vendor_id']?.toString(),
        vendorName: dynamicData['vendor_name']?.toString(),
        vendorLogo: dynamicData['vendor_logo']?.toString(),
        userName: dynamicData['user_name']?.toString(),
        userPhoto: dynamicData['user_photo']?.toString(),
        mediaType: dynamicData['media_type']?.toString() ?? 'image',
        mediaUrl: dynamicData['media_url']?.toString(),
        thumbnailUrl: dynamicData['thumbnail_url']?.toString(),
        caption: dynamicData['caption']?.toString(),
        itemId: dynamicData['item_id']?.toString(),
        item: dynamicData['item'] != null
            ? TaggedItem().fromMap(dynamicData['item'])
            : null,
        filterPreset: dynamicData['filter_preset']?.toString() ?? 'original',
        viewsCount: int.tryParse(dynamicData['views_count']?.toString() ?? '0') ?? 0,
        duration: int.tryParse(dynamicData['duration']?.toString() ?? '5') ?? 5,
        createdAt: dynamicData['created_at']?.toString(),
        expiresAt: dynamicData['expires_at']?.toString(),
        remainingHours: int.tryParse(dynamicData['remaining_hours']?.toString() ?? '24') ?? 24,
        timeAgo: dynamicData['time_ago']?.toString(),
        isOwner: dynamicData['is_owner'] == true || dynamicData['is_owner'] == '1',
      );
    }
    return VendorStory();
  }

  @override
  Map<String, dynamic>? toMap(VendorStory object) {
    return <String, dynamic>{
      'id': object.id,
      'user_id': object.userId,
      'vendor_id': object.vendorId,
      'vendor_name': object.vendorName,
      'vendor_logo': object.vendorLogo,
      'user_name': object.userName,
      'user_photo': object.userPhoto,
      'media_type': object.mediaType,
      'media_url': object.mediaUrl,
      'thumbnail_url': object.thumbnailUrl,
      'caption': object.caption,
      'item_id': object.itemId,
      'item': object.item != null ? TaggedItem().toMap(object.item!) : null,
      'filter_preset': object.filterPreset,
      'views_count': object.viewsCount,
      'duration': object.duration,
      'created_at': object.createdAt,
      'expires_at': object.expiresAt,
      'remaining_hours': object.remainingHours,
      'time_ago': object.timeAgo,
      'is_owner': object.isOwner,
    };
  }

  @override
  List<VendorStory> fromMapList(List<dynamic> dynamicDataList) {
    final List<VendorStory> list = <VendorStory>[];
    for (final dynamic dynamicData in dynamicDataList) {
      if (dynamicData != null) {
        list.add(fromMap(dynamicData));
      }
    }
    return list;
  }

  @override
  List<Map<String, dynamic>?> toMapList(List<VendorStory> objectList) {
    final List<Map<String, dynamic>?> list = <Map<String, dynamic>?>[];
    for (final VendorStory data in objectList) {
      list.add(toMap(data));
    }
    return list;
  }
}

class VendorStoriesGroup {
  VendorStoriesGroup({
    this.groupKey,
    this.vendorId,
    this.vendorUserId,
    this.vendorName,
    this.vendorLogo,
    this.isMine = false,
    this.hasUnseen = true,
    this.stories = const <VendorStory>[],
  });

  factory VendorStoriesGroup.fromMap(dynamic dynamicData) {
    if (dynamicData != null) {
      final List<dynamic>? rawStories = dynamicData['stories'] as List<dynamic>?;
      final List<VendorStory> parsedStories = rawStories != null
          ? VendorStory().fromMapList(rawStories)
          : <VendorStory>[];

      return VendorStoriesGroup(
        groupKey: dynamicData['group_key']?.toString(),
        vendorId: dynamicData['vendor_id']?.toString(),
        vendorUserId: dynamicData['vendor_user_id']?.toString(),
        vendorName: dynamicData['vendor_name']?.toString(),
        vendorLogo: dynamicData['vendor_logo']?.toString(),
        isMine: dynamicData['is_mine'] == true || dynamicData['is_mine'] == '1',
        hasUnseen: dynamicData['has_unseen'] == true || dynamicData['has_unseen'] == '1',
        stories: parsedStories,
      );
    }
    return VendorStoriesGroup();
  }

  String? groupKey;
  String? vendorId;
  String? vendorUserId;
  String? vendorName;
  String? vendorLogo;
  bool isMine;
  bool hasUnseen;
  List<VendorStory> stories;
}
