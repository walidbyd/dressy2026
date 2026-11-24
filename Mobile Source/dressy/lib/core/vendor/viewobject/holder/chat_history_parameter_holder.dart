
import '../common/ps_holder.dart';

class ChatHistoryParameterHolder extends PsHolder<dynamic> {
  ChatHistoryParameterHolder() {
    userId = '';
    returnType = '';
  }

  String? userId;
  String? returnType;

  ChatHistoryParameterHolder getSellerHistoryList() {
    userId = '';
    returnType = 'unified';

    return this;
  }

  ChatHistoryParameterHolder getBuyerHistoryList() {
    userId = '';
    returnType = 'unified';

    return this;
  }

  ChatHistoryParameterHolder getUnifiedHistoryList() {
    userId = '';
    returnType = 'unified';

    return this;
  }

  ChatHistoryParameterHolder resetParameterHolder() {
    userId = '';
    returnType = 'unified';

    return this;
  }

  @override
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = <String, dynamic>{};
    map['user_id'] = userId;
    map['return_type'] = returnType;
    return map;
  }

  @override
  dynamic fromMap(dynamic dynamicData) {
    userId = '';
    returnType = 'unified';

    return this;
  }

  @override
  String getParamKey() {
    return userId ?? '';
  }
}
