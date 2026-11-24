import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../../core/vendor/viewobject/common/ps_value_holder.dart';

import '../../../../../core/vendor/api/common/ps_status.dart';
import '../../../../../core/vendor/provider/item_location/item_location_provider.dart';
import '../../../../../core/vendor/utils/ps_animation.dart';
import '../../../../../core/vendor/viewobject/item_location.dart';
import '../../../../custom_ui/location/component/entry_city/entry_city_list_item.dart';

class EntryCityListData extends StatefulWidget {
  const EntryCityListData(
      {required this.animationController, required this.selectedCityName});
  final AnimationController animationController;
  final String selectedCityName;
  @override
  State<StatefulWidget> createState() => _EntryCityListDataState();
}

class _EntryCityListDataState extends State<EntryCityListData> {
  final ScrollController _scrollController = ScrollController();

  late ItemLocationProvider _itemLocationProvider;
  Animation<double>? animation;

  @override
  void dispose() {
    animation = null;
    super.dispose();
  }

  @override
  void initState() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _itemLocationProvider.loadNextDataList();
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final PsValueHolder valueHolder =Provider.of<PsValueHolder>(context, listen: false);
    _itemLocationProvider = Provider.of<ItemLocationProvider>(context);
    final bool isLoading =
        _itemLocationProvider.currentStatus == PsStatus.BLOCK_LOADING;
    final List<ItemLocation> filteredLocations = isLoading
        ? <ItemLocation>[]
        : List<ItemLocation>.generate(
            _itemLocationProvider.dataLength,
            (int index) => _itemLocationProvider.getListIndexOf(index),
          ).where((ItemLocation loc) {
            final String id = loc.id.trim().toLowerCase();
            final String name = (loc.name ?? '').trim().toLowerCase();
            if (id == '0' || id == 'all') {
              return false;
            }
            if (name.contains("route l'alg") ||
                name.contains("toute l'alg") ||
                name == 'all' ||
                name == 'all locations' ||
                name == "l'algérie" ||
                name == 'algeria') {
              return false;
            }
            return true;
          }).toList();
    final int count = isLoading
        ? valueHolder.loadingShimmerItemCount!
        : filteredLocations.length;
    return ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: count,
        itemBuilder: (BuildContext context, int index) {
          final ItemLocation currentLocation =
              isLoading ? ItemLocation() : filteredLocations[index];
          return CustomEntryCityListItem(
            itemLocation: currentLocation,
            animationController: widget.animationController,
            animation: curveAnimation(widget.animationController,
                count: count, index: index),
            isLoading: isLoading,
            isSelected:
                !isLoading && widget.selectedCityName == currentLocation.name,
          );
        });
  }
}
