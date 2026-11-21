import 'package:quiver/core.dart';
import 'common/ps_object.dart';

class WalletTransaction extends PsObject<WalletTransaction> {
  WalletTransaction({
    this.id,
    this.type,
    this.source,
    this.orderCode,
    this.amount,
    this.grossAmount,
    this.commissionAmount,
    this.balanceAfter,
    this.referenceType,
    this.referenceId,
    this.note,
    this.description,
    this.createdAt,
  });

  String? id;
  String? type;
  String? source;
  String? orderCode;
  String? amount;
  String? grossAmount;
  String? commissionAmount;
  String? balanceAfter;
  String? referenceType;
  String? referenceId;
  String? note;
  String? description;
  String? createdAt;

  @override
  bool operator ==(dynamic other) => other is WalletTransaction && id == other.id;

  @override
  int get hashCode => hash2(id.hashCode, id.hashCode);

  @override
  String? getPrimaryKey() {
    return id;
  }

  @override
  WalletTransaction fromMap(dynamic dynamicData) {
    if (dynamicData != null) {
      return WalletTransaction(
        id: dynamicData['id']?.toString(),
        type: dynamicData['type']?.toString(),
        source: dynamicData['source']?.toString(),
        orderCode: dynamicData['order_code']?.toString(),
        amount: dynamicData['amount']?.toString(),
        grossAmount: dynamicData['gross_amount']?.toString(),
        commissionAmount: dynamicData['commission_amount']?.toString(),
        balanceAfter: dynamicData['balance_after']?.toString(),
        referenceType: dynamicData['reference_type']?.toString(),
        referenceId: dynamicData['reference_id']?.toString(),
        note: dynamicData['note']?.toString(),
        description: dynamicData['description']?.toString(),
        createdAt: dynamicData['created_at']?.toString(),
      );
    }
    return WalletTransaction();
  }

  @override
  Map<String, dynamic>? toMap(dynamic object) {
    if (object != null) {
      final Map<String, dynamic> data = <String, dynamic>{};
      data['id'] = object.id;
      data['type'] = object.type;
      data['source'] = object.source;
      data['order_code'] = object.orderCode;
      data['amount'] = object.amount;
      data['gross_amount'] = object.grossAmount;
      data['commission_amount'] = object.commissionAmount;
      data['balance_after'] = object.balanceAfter;
      data['reference_type'] = object.referenceType;
      data['reference_id'] = object.referenceId;
      data['note'] = object.note;
      data['description'] = object.description;
      data['created_at'] = object.createdAt;
      return data;
    }
    return null;
  }

  @override
  List<WalletTransaction> fromMapList(List<dynamic> dynamicDataList) {
    final List<WalletTransaction> list = <WalletTransaction>[];
    for (dynamic element in dynamicDataList) {
      list.add(fromMap(element));
    }
    return list;
  }

  @override
  List<Map<String, dynamic>?> toMapList(List<dynamic> objectList) {
    final List<Map<String, dynamic>?> list = <Map<String, dynamic>?>[];
    for (dynamic element in objectList) {
      if (element != null) {
        list.add(toMap(element));
      }
    }
    return list;
  }
}
