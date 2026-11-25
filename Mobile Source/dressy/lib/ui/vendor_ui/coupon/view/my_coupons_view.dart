import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../../config/ps_colors.dart';
import '../../../../config/ps_config.dart';
import '../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../core/vendor/utils/utils.dart';
import '../../../../core/vendor/viewobject/common/ps_value_holder.dart';

class MyCouponsView extends StatefulWidget {
  const MyCouponsView({Key? key}) : super(key: key);

  @override
  State<MyCouponsView> createState() => _MyCouponsViewState();
}

class _MyCouponsViewState extends State<MyCouponsView> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _coupons = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCoupons();
    });
  }

  Future<void> _loadCoupons() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final PsValueHolder valueHolder =
          Provider.of<PsValueHolder>(context, listen: false);
      final String userId = Utils.checkUserLoginId(valueHolder);
      final Uri uri = Uri.parse(
        '${PsConfig.ps_app_url}coupons/my?login_user_id=$userId',
      );
      final http.Response res = await http
          .get(
            uri,
            headers: <String, String>{
              'Accept': 'application/json',
              'Authorization': PsConfig.ps_bearer_token,
              'header-token': valueHolder.headerToken ?? '',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) {
        return;
      }

      if (res.statusCode == 200) {
        final dynamic decoded = json.decode(res.body);
        final List<dynamic> raw = (decoded is Map<String, dynamic> &&
                decoded['coupons'] is List<dynamic>)
            ? decoded['coupons'] as List<dynamic>
            : <dynamic>[];
        setState(() {
          _coupons = raw.whereType<Map<String, dynamic>>().toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'coupon__load_error'.tr;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'coupon__load_error'.tr;
        });
      }
    }
  }

  String _formatValidity(Map<String, dynamic> c) {
    final int? remaining =
        int.tryParse(c['remaining_seconds']?.toString() ?? '');
    if (remaining == null) {
      return 'coupon__no_expiry'.tr;
    }
    if (remaining <= 0) {
      return 'coupon__expired'.tr;
    }
    final int hours = remaining ~/ 3600;
    final int days = hours ~/ 24;
    final int remHours = hours % 24;
    final int mins = (remaining % 3600) ~/ 60;
    if (days > 0) {
      return '${days}j ${remHours}h';
    }
    return '${hours}h ${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    final bool isLight = Utils.isLightMode(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'coupon__my_coupons'.tr,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isLight ? PsColors.achromatic900 : PsColors.achromatic50,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isLight ? PsColors.achromatic900 : PsColors.achromatic50,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadCoupons,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(_errorMessage!),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadCoupons,
                          child: Text('coupon__retry'.tr),
                        ),
                      ],
                    ),
                  )
                : _coupons.isEmpty
                    ? ListView(
                        children: <Widget>[
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.55,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Icon(
                                    Icons.local_offer_outlined,
                                    size: 56,
                                    color: PsColors.achromatic400,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'coupon__empty'.tr,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _coupons.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (BuildContext context, int index) {
                          final Map<String, dynamic> c = _coupons[index];
                          final String code = (c['code'] ?? '').toString();
                          final String type =
                              (c['discount_type'] ?? 'percentage').toString();
                          final double value = double.tryParse(
                                  c['discount_value']?.toString() ?? '0') ??
                              0;
                          final String discountLabel = type == 'percentage'
                              ? '-${value.toStringAsFixed(0)}%'
                              : '-${value.toStringAsFixed(0)} DA';
                          final double? minOrder = double.tryParse(
                              c['min_order_amount']?.toString() ?? '');
                          final bool isRoulette =
                              (c['source'] ?? '') == 'roulette';

                          return Container(
                            decoration: BoxDecoration(
                              color: isLight
                                  ? Colors.white
                                  : PsColors.achromatic800,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isRoulette
                                    ? const Color(0xFFED7768)
                                        .withValues(alpha: 0.5)
                                    : (isLight
                                        ? const Color(0xFFE5E7EB)
                                        : PsColors.achromatic600),
                              ),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: <Widget>[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: <Color>[
                                        Color(0xFFED7768),
                                        Color(0xFFF4A261),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    discountLabel,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        code,
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      if (minOrder != null && minOrder > 0)
                                        Text(
                                          '${'coupon__min_order'.tr}: ${minOrder.toStringAsFixed(0)} DA',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      Text(
                                        '${'coupon__valid_for'.tr}: ${_formatValidity(c)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isRoulette
                                              ? const Color(0xFFED7768)
                                              : PsColors.text500,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Clipboard.setData(
                                        ClipboardData(text: code));
                                    Fluttertoast.showToast(
                                      msg: 'coupon__copied'.tr,
                                      toastLength: Toast.LENGTH_SHORT,
                                      gravity: ToastGravity.BOTTOM,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFED7768),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  icon: const Icon(Icons.copy, size: 15),
                                  label: Text(
                                    'coupon__copy'.tr,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
