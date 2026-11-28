import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../../../../../../config/ps_colors.dart';
import '../../../../../../../../config/ps_config.dart';
import '../../../../../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../../../../../core/vendor/provider/product/product_provider.dart';
import '../../../../../../../../core/vendor/utils/ps_progress_dialog.dart';
import '../../../../../../../../core/vendor/utils/utils.dart';
import '../../../../../../../../core/vendor/viewobject/common/ps_value_holder.dart';
import '../../../../../../../../core/vendor/viewobject/product.dart';
import '../../../../../common/dialog/error_dialog.dart';
import '../../../../../common/dialog/success_dialog.dart';
import '../../../../../../custom_ui/item/detail/component/sticky_bottom/owner_action/widgets/delete_widget.dart';

class OwnerActionButtonsWidget extends StatelessWidget {
  Future<void> _republishItem(BuildContext context, Product product) async {
    final PsValueHolder valueHolder =
        Provider.of<PsValueHolder>(context, listen: false);
    final String userId = Utils.checkUserLoginId(valueHolder);
    if (userId.isEmpty || userId == 'nologinuser') {
      return;
    }

    await PsProgressDialog.showDialog(context);
    try {
      final Uri uri = Uri.parse(
        '${PsConfig.ps_app_url}product/republish?login_user_id=$userId',
      );
      final http.Response res = await http
          .post(
            uri,
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': PsConfig.ps_bearer_token,
              'header-token': valueHolder.headerToken ?? '',
            },
            body: json.encode(<String, dynamic>{
              'item_id': product.id,
              'login_user_id': userId,
            }),
          )
          .timeout(const Duration(seconds: 20));

      await PsProgressDialog.dismissDialog();
      if (!context.mounted) {
        return;
      }

      if (res.statusCode >= 200 && res.statusCode < 300) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext ctx) => SuccessDialog(
            message: 'item_detail__sell_again_pending_approval'.tr,
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context, true);
              }
            },
          ),
        );
      } else {
        String errMsg = 'item_detail__sell_again_error'.tr;
        try {
          final dynamic decoded = json.decode(res.body);
          if (decoded is Map<String, dynamic> && decoded['message'] != null) {
            errMsg = decoded['message'].toString();
          }
        } catch (_) {}
        showDialog<void>(
          context: context,
          builder: (BuildContext ctx) => ErrorDialog(message: errMsg),
        );
      }
    } catch (_) {
      await PsProgressDialog.dismissDialog();
      if (context.mounted) {
        showDialog<void>(
          context: context,
          builder: (BuildContext ctx) => ErrorDialog(
            message: 'item_detail__sell_again_error'.tr,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ItemDetailProvider provider = Provider.of<ItemDetailProvider>(context);
    final Product product = provider.product;

    if (!product.isSoldOutItem) {
      return CustomDeleteItemWidget();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: PsColors.primary500,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => _republishItem(context, product),
            icon: const Icon(Icons.replay_rounded, size: 20),
            label: Text(
              'item_detail__sell_again'.tr,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        CustomDeleteItemWidget(),
      ],
    );
  }
}
