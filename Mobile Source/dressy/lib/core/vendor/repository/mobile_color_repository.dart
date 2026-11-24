import 'dart:async';

import 'package:sembast/sembast.dart';

import '../api/common/ps_resource.dart';
import '../api/common/ps_status.dart';
import '../api/ps_api_service.dart';
import '../db/common/ps_data_source_manager.dart';
import '../db/mobile_color_dao.dart';
import '../viewobject/common/ps_holder.dart';
import '../viewobject/holder/request_path_holder.dart';
import '../viewobject/mobile_color.dart';
import 'Common/ps_repository.dart';

class MobileColorRepository extends PsRepository {
  MobileColorRepository({
    required PsApiService psApiService,
    required MobileColorDao mobileColorDao,
  }) {
    _psApiService = psApiService;
    _mobileColorDao = mobileColorDao;

  }

  late PsApiService _psApiService;
  late MobileColorDao _mobileColorDao;

  @override
  Future<void> loadData({
    required StreamController<PsResource<dynamic>> streamController,
    PsHolder<dynamic>? requestBodyHolder,
    RequestPathHolder? requestPathHolder,
    required DataConfiguration dataConfig,
  }) async {

    

    await startResourceSinkingForOne(
      dao: _mobileColorDao,
      streamController: streamController,
      dataConfig: dataConfig,
      serverRequestCallback: () async => await _psApiService
          .getMobileColor(requestPathHolder?.loginUserId ?? 'nologinuser'),
    );
  }

  Future<dynamic> loadColorFromDB(
      StreamController<PsResource<dynamic>> colorsListStream,
      PsStatus status) async {
      final Finder f = Finder(filter: _mobileColorDao.getFilter(MobileColor()));
      colorsListStream.sink.add(await _mobileColorDao.getOne(status: status, finder: f));
  }
}
