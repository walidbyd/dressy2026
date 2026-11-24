import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../../core/vendor/constant/ps_constants.dart';
import '../../../../../../../core/vendor/provider/product/item_entry_provider.dart';
import '../../../../../../../core/vendor/viewobject/vendor_list.dart';

class ChooseProfileWidget extends StatelessWidget {
  const ChooseProfileWidget({Key? key, required this.flag}) : super(key: key);

  final String flag;

  @override
  Widget build(BuildContext context) {
    final ItemEntryFieldProvider provider =
        Provider.of<ItemEntryFieldProvider>(context);

    final List<VendorList>? profileList =
        provider.itemEntryField.data?.vendorList?.toList();

    if (profileList != null && profileList.isNotEmpty) {
      if (provider.selectedVendorId == null ||
          provider.selectedVendorId!.isEmpty ||
          provider.selectedVendorId == PsConst.USER_PROFILE ||
          provider.selectedVendorId == PsConst.NO_PROFILE) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final VendorList firstVendor = profileList.first;
          provider.changeSelectedVendorId(firstVendor.id);
          provider.changeSelectedVendorCurrencyIdAndSymbol(
              firstVendor.currencyId, firstVendor.currencySymbol);
          if (firstVendor.id != null && firstVendor.id!.isNotEmpty) {
            provider.replaceVendorProfile(firstVendor.id!);
          }
        });
      }
    }

    return const SizedBox.shrink();
  }
}
