import 'package:quiver/core.dart';

import 'common/ps_object.dart';

class Message extends PsObject<Message?> {
  Message(
      {this.addedDate,
      this.id,
      this.isSold,
      this.isUserBought,
      this.isBlocked,
      this.itemId,
      this.message,
      this.offerStatus,
      this.sendByUserId,
      this.sessionId,
      this.type,
      this.addedDateTimeStamp,
      this.messageType,
      this.orderId,
      this.orderCode,
      this.actionStatus});

  Map<String, String>? addedDate;
  int? addedDateTimeStamp;
  String? id;
  bool? isSold;
  bool? isUserBought;
  bool? isBlocked;
  String? itemId;
  String? message;
  int? offerStatus;
  String? sendByUserId;
  String? sessionId;
  int? type;
  String? messageType;
  String? orderId;
  String? orderCode;
  String? actionStatus;

  @override
  bool operator ==(dynamic other) =>
      other is Message && offerStatus == other.offerStatus;

  @override
  int get hashCode => hash2(offerStatus.hashCode, offerStatus.hashCode);

  @override
  String getPrimaryKey() {
    return offerStatus.toString();
  }

  @override
  List<Message?> fromMapList(List<dynamic> dynamicDataList) {
    final List<Message?> subCategoryList = <Message?>[];

    // if (dynamicDataList != null) {
    for (dynamic dynamicData in dynamicDataList) {
      if (dynamicData != null) {
        subCategoryList.add(fromMap(dynamicData));
      }
    }
    // }
    return subCategoryList;
  }

  @override
  Message? fromMap(dynamic dynamicData) {
    if (dynamicData != null && dynamicData is Map) {
      final dynamic rawAdded = dynamicData['addedDate'];
      final int parsedTimestamp = rawAdded is int
          ? rawAdded
          : (rawAdded is num
              ? rawAdded.toInt()
              : int.tryParse(rawAdded?.toString() ?? '') ??
                  DateTime.now().millisecondsSinceEpoch);
      final dynamic rawOffer = dynamicData['offerStatus'];
      final dynamic rawType = dynamicData['type'];
      return Message(
        //addedDate: dynamicData['added_date'],
        addedDateTimeStamp: parsedTimestamp,
        id: dynamicData['id']?.toString(),
        isSold: dynamicData['isSold'] is bool ? dynamicData['isSold'] as bool : null,
        isUserBought: dynamicData['isUserBought'] is bool
            ? dynamicData['isUserBought'] as bool
            : null,
        isBlocked: dynamicData['is_blocked'] is bool
            ? dynamicData['is_blocked'] as bool
            : null,
        itemId: dynamicData['itemId']?.toString(),
        message: dynamicData['message']?.toString(),
        offerStatus: rawOffer is int
            ? rawOffer
            : int.tryParse(rawOffer?.toString() ?? ''),
        sendByUserId: dynamicData['sendByUserId']?.toString(),
        sessionId: dynamicData['sessionId']?.toString(),
        type: rawType is int ? rawType : int.tryParse(rawType?.toString() ?? ''),
        messageType: (dynamicData['messageType'] ?? dynamicData['message_type'])?.toString(),
        orderId: dynamicData['orderId'] != null ? dynamicData['orderId'].toString() : (dynamicData['order_id'] != null ? dynamicData['order_id'].toString() : null),
        orderCode: dynamicData['orderCode'] != null ? dynamicData['orderCode'].toString() : (dynamicData['order_code'] != null ? dynamicData['order_code'].toString() : null),
        actionStatus: (dynamicData['actionStatus'] ?? dynamicData['action_status'])?.toString(),
      );
    } else {
      return null;
    }
  }

  Map<String, dynamic> toInsertMap(Message object) {
    // if (object != null) {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['addedDate'] = object.addedDate;
    data['id'] = object.id;
    data['isSold'] = object.isSold;
    data['isUserBought'] = object.isUserBought;
    data['is_blocked'] = object.isBlocked;
    data['itemId'] = object.itemId;
    data['message'] = object.message;
    data['offerStatus'] = object.offerStatus;
    data['sendByUserId'] = object.sendByUserId;
    data['sessionId'] = object.sessionId;
    data['type'] = object.type;
    data['messageType'] = object.messageType;
    data['orderId'] = object.orderId;
    data['orderCode'] = object.orderCode;
    data['actionStatus'] = object.actionStatus;
    return data;
    // } else {
    //   return <String, dynamic>{};
    // }
  }

  Map<String, dynamic> toDeleteMap(Message object) {
    // if (object != null) {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['addedDate'] = object.addedDate;
    data['id'] = object.id;
    data['isSold'] = object.isSold;
    data['isUserBought'] = object.isUserBought;
    data['is_blocked'] = object.isBlocked;
    data['itemId'] = object.itemId;
    data['message'] = object.message;
    data['offerStatus'] = object.offerStatus;
    data['sendByUserId'] = object.sendByUserId;
    data['sessionId'] = object.sessionId;
    data['type'] = object.type;
    data['messageType'] = object.messageType;
    data['orderId'] = object.orderId;
    data['orderCode'] = object.orderCode;
    data['actionStatus'] = object.actionStatus;
    return data;
    // } else {
    //   return <String, dynamic>{};
    // }
  }

  Map<String, dynamic> toUpdateMap(Message object) {
    // if (object != null) {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['addedDate'] = object.addedDateTimeStamp;
    data['id'] = object.id;
    data['isSold'] = object.isSold; 
    data['isUserBought'] = object.isUserBought;
    data['is_blocked'] = object.isBlocked;
    data['itemId'] = object.itemId;
    data['message'] = object.message;
    data['offerStatus'] = object.offerStatus;
    data['sendByUserId'] = object.sendByUserId;
    data['sessionId'] = object.sessionId;
    data['type'] = object.type;
    data['messageType'] = object.messageType;
    data['orderId'] = object.orderId;
    data['orderCode'] = object.orderCode;
    data['actionStatus'] = object.actionStatus;
    return data;
    // } else {
    //   return <String, dynamic>{};
    // }
  }

  @override
  List<Map<String, dynamic>?> toMapList(List<Message?> objectList) {
    final List<Map<String, dynamic>?> mapList = <Map<String, dynamic>?>[];
    // if (objectList != null) {
    for (Message? data in objectList) {
      if (data != null) {
        mapList.add(toMap(data));
      }
    }
    // }
    return mapList;
  }

  @override
  Map<String, dynamic>? toMap(Message? object) {
    return null;
  }
}
