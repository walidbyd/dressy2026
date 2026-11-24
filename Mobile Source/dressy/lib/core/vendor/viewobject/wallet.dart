import 'package:quiver/core.dart';
import 'common/ps_object.dart';

class Wallet extends PsObject<Wallet> {
  Wallet({
    this.balance,
    this.currency,
    this.currencySymbol,
    this.totalEarned,
    this.totalWithdrawn,
    this.pendingWithdraw,
  });

  String? balance;
  String? currency;
  String? currencySymbol;
  String? totalEarned;
  String? totalWithdrawn;
  String? pendingWithdraw;

  @override
  bool operator ==(dynamic other) => other is Wallet && balance == other.balance;

  @override
  int get hashCode => hash2(balance.hashCode, balance.hashCode);

  @override
  String? getPrimaryKey() {
    return balance;
  }

  @override
  Wallet fromMap(dynamic dynamicData) {
    if (dynamicData != null) {
      return Wallet(
        balance: dynamicData['balance']?.toString(),
        currency: dynamicData['currency']?.toString(),
        currencySymbol: dynamicData['currency_symbol']?.toString(),
        totalEarned: dynamicData['total_earned']?.toString(),
        totalWithdrawn: dynamicData['total_withdrawn']?.toString(),
        pendingWithdraw: dynamicData['pending_withdraw']?.toString(),
      );
    }
    return Wallet();
  }

  @override
  Map<String, dynamic>? toMap(dynamic object) {
    if (object != null) {
      final Map<String, dynamic> data = <String, dynamic>{};
      data['balance'] = object.balance;
      data['currency'] = object.currency;
      data['currency_symbol'] = object.currencySymbol;
      data['total_earned'] = object.totalEarned;
      data['total_withdrawn'] = object.totalWithdrawn;
      data['pending_withdraw'] = object.pendingWithdraw;
      return data;
    }
    return null;
  }

  @override
  List<Wallet> fromMapList(List<dynamic> dynamicDataList) {
    final List<Wallet> list = <Wallet>[];
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
