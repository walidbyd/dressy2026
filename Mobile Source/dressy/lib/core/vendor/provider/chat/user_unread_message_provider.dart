import '../../api/common/ps_resource.dart';
import '../../api/common/ps_status.dart';
import '../../constant/ps_constants.dart';
import '../../db/common/ps_data_source_manager.dart';
import '../../repository/user_unread_message_repository.dart';
import '../../viewobject/common/ps_holder.dart';
import '../../viewobject/holder/request_path_holder.dart';
import '../../viewobject/holder/user_unread_message_parameter_holder.dart';
import '../../viewobject/user_unread_message.dart';
import '../common/ps_provider.dart';

class UserUnreadMessageProvider extends PsProvider<UserUnreadMessage> {
  UserUnreadMessageProvider({
    required UserUnreadMessageRepository? repo,
    int limit = 0,
  }) : super(repo, limit, subscriptionType: PsConst.SINGLE_OBJECT_SUBSCRIPTION);
  PsResource<UserUnreadMessage> get userUnreadMessage => super.data;

  late UserUnreadMessageParameterHolder userUnreadMessageHolder;
  int totalUnreadCount = 0;
  bool isShowMessageDialog = false;

  DateTime? _lastFetchTime;
  bool _hasAuthError = false;

  @override
  Future<void> loadData({
    PsHolder<dynamic>? requestBodyHolder,
    RequestPathHolder? requestPathHolder,
    DataConfiguration? dataConfig,
  }) async {
    final String? bodyUserId = (requestBodyHolder is UserUnreadMessageParameterHolder)
        ? requestBodyHolder.userId
        : null;
    final String pathUserId = requestPathHolder?.loginUserId ?? '';
    final String effectiveUserId = (pathUserId.isNotEmpty && pathUserId != 'nologinuser')
        ? pathUserId
        : (bodyUserId ?? '');

    if (effectiveUserId.isEmpty || effectiveUserId == 'nologinuser') {
      return;
    }

    if (_hasAuthError) {
      return;
    }

    final DateTime now = DateTime.now();
    if (_lastFetchTime != null && now.difference(_lastFetchTime!).inSeconds < 5 && isLoading) {
      return;
    }
    _lastFetchTime = now;

    await super.loadData(
      requestBodyHolder: requestBodyHolder,
      requestPathHolder: requestPathHolder,
      dataConfig: dataConfig,
    );

    if (data.status == PsStatus.ERROR) {
      final String code = data.errorCode;
      final String msg = data.message.toLowerCase();
      if (code == '401' || code == '403' || msg.contains('permission') || msg.contains('unauthorized')) {
        _hasAuthError = true;
      }
    }
  }

  void resetAuthError() {
    _hasAuthError = false;
  }
}
