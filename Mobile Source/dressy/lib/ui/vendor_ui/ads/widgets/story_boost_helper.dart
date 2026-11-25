import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../../config/ps_colors.dart';
import '../../../../config/ps_config.dart';
import '../../../../config/route/route_paths.dart';
import '../../../../core/vendor/api/common/ps_resource.dart';
import '../../../../core/vendor/api/ps_api_service.dart';
import '../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../core/vendor/utils/utils.dart';
import '../../../../core/vendor/viewobject/common/ps_value_holder.dart';
import '../../../../core/vendor/viewobject/wallet.dart';

class StoryBoostHelper {
  static Future<Map<String, dynamic>?> fetchAdsConfig(
      BuildContext context) async {
    try {
      final PsValueHolder vh =
          Provider.of<PsValueHolder>(context, listen: false);
      final String userId = Utils.checkUserLoginId(vh);
      final Uri uri =
          Uri.parse('${PsConfig.ps_app_url}ads/config?login_user_id=$userId');
      final http.Response res = await http.get(
        uri,
        headers: <String, String>{
          'Accept': 'application/json',
          'Authorization': PsConfig.ps_bearer_token,
          'header-token': vh.headerToken ?? '',
        },
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final dynamic decoded = json.decode(res.body);
        if (decoded is Map<String, dynamic> &&
            decoded['data'] is Map<String, dynamic>) {
          return decoded['data'] as Map<String, dynamic>;
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<double?> fetchWalletBalance(BuildContext context) async {
    try {
      final PsApiService apiService =
          Provider.of<PsApiService>(context, listen: false);
      final PsValueHolder vh =
          Provider.of<PsValueHolder>(context, listen: false);
      final AppLocalization lang =
          Provider.of<AppLocalization>(context, listen: false);
      final String userId = Utils.checkUserLoginId(vh);
      final PsResource<Wallet> res = await apiService.getWalletBalance(
        userId,
        lang.currentLocale.languageCode,
      );
      return double.tryParse((res.data?.balance ?? '0').toString());
    } catch (_) {
      return null;
    }
  }

  static Future<bool> showBoostSheet(
    BuildContext context, {
    required String storyId,
    bool isAfterPublish = false,
  }) async {
    final List<dynamic> loaded = await Future.wait<dynamic>(<Future<dynamic>>[
      fetchAdsConfig(context),
      fetchWalletBalance(context),
    ]);
    if (!context.mounted) {
      return false;
    }
    final Map<String, dynamic>? config = loaded[0] as Map<String, dynamic>?;
    final double? walletBalance = loaded[1] as double?;
    if (config == null) {
      if (!isAfterPublish) {
        Fluttertoast.showToast(msg: 'ads__boost_error'.tr);
      }
      return false;
    }

    final bool isEnabled = config['is_enabled'] == true;
    final Map<String, dynamic>? storyBoost =
        config['story_boost'] as Map<String, dynamic>?;
    if (!isEnabled || storyBoost == null || storyBoost['enabled'] != true) {
      if (!isAfterPublish) {
        Fluttertoast.showToast(msg: 'ads__disabled_msg'.tr);
      }
      return false;
    }

    final double price =
        double.tryParse((storyBoost['price_dzd'] ?? '300').toString()) ?? 300.0;
    final String title =
        (storyBoost['title'] ?? 'Boost Story 24h').toString();
    final String description =
        (storyBoost['description'] ?? '').toString();

    bool boosted = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetCtx) {
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFED7768).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.rocket_launch_rounded,
                      color: Color(0xFFED7768),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isAfterPublish ? 'ads__story_published_boost_title'.tr : title,
                    textAlign: TextAlign.center,
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                  ),
                  const SizedBox(height: 8),
                  if (description.isNotEmpty)
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      style: Theme.of(ctx).textTheme.bodySmall,
                    ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: PsColors.primary50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${price.toStringAsFixed(0)} DA • 24h',
                      style: TextStyle(
                        color: PsColors.primary700,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (walletBalance != null) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(
                      '${'ads__current_balance'.tr}: ${walletBalance.toStringAsFixed(0)} DA',
                      style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              setSheetState(() => isSubmitting = true);
                              final PsValueHolder vh =
                                  Provider.of<PsValueHolder>(ctx,
                                      listen: false);
                              final String userId =
                                  Utils.checkUserLoginId(vh);
                              try {
                                final http.Response res = await http
                                    .post(
                                      Uri.parse(
                                          '${PsConfig.ps_app_url}ads/boost-story'),
                                      headers: <String, String>{
                                        'Content-Type': 'application/json',
                                        'Accept': 'application/json',
                                        'Authorization':
                                            PsConfig.ps_bearer_token,
                                        'header-token': vh.headerToken ?? '',
                                      },
                                      body: json.encode(<String, dynamic>{
                                        'story_id': int.tryParse(storyId) ??
                                            storyId,
                                        'login_user_id': userId,
                                      }),
                                    )
                                    .timeout(const Duration(seconds: 15));

                                final dynamic decoded = json.decode(res.body);
                                if (res.statusCode == 200 &&
                                    decoded is Map<String, dynamic> &&
                                    decoded['success'] == true) {
                                  boosted = true;
                                  if (ctx.mounted) {
                                    Navigator.pop(ctx);
                                  }
                                  Fluttertoast.showToast(
                                    msg: decoded['message']?.toString() ??
                                        'ads__boost_success'.tr,
                                  );
                                } else if (decoded is Map<String, dynamic> &&
                                    decoded['insufficient_balance'] == true) {
                                  setSheetState(() => isSubmitting = false);
                                  if (ctx.mounted) {
                                    await showInsufficientBalanceDialog(
                                      ctx,
                                      balance: double.tryParse(
                                              (decoded['wallet_balance'] ?? 0)
                                                  .toString()) ??
                                          0.0,
                                      requiredAmount: double.tryParse(
                                              (decoded['required_amount'] ??
                                                      price)
                                                  .toString()) ??
                                          price,
                                    );
                                  }
                                } else {
                                  setSheetState(() => isSubmitting = false);
                                  Fluttertoast.showToast(
                                    msg: (decoded is Map<String, dynamic>
                                            ? decoded['message']?.toString()
                                            : null) ??
                                        'ads__boost_error'.tr,
                                  );
                                }
                              } catch (_) {
                                setSheetState(() => isSubmitting = false);
                                Fluttertoast.showToast(msg: 'ads__boost_error'.tr);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFED7768),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.bolt),
                      label: Text('ads__boost_with_wallet'.tr),
                    ),
                  ),
                  if (isAfterPublish) ...<Widget>[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('ads__skip_for_now'.tr),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );

    return boosted;
  }

  static Future<void> showInsufficientBalanceDialog(
    BuildContext context, {
    required double balance,
    required double requiredAmount,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dCtx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('ads__insufficient_balance_title'.tr),
          content: Text(
            '${'ads__current_balance'.tr}: ${balance.toStringAsFixed(0)} DA\n'
            '${'ads__required_amount'.tr}: ${requiredAmount.toStringAsFixed(0)} DA\n\n'
            '${'ads__topup_prompt'.tr}',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: Text('dialog__cancel'.tr),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dCtx);
                Navigator.pushNamed(context, RoutePaths.wallet);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: PsColors.primary500,
                foregroundColor: Colors.white,
              ),
              child: Text('ads__go_topup_btn'.tr),
            ),
          ],
        );
      },
    );
  }
}
