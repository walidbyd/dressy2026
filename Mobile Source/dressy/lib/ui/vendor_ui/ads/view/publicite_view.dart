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
import '../widgets/story_boost_helper.dart';

class PubliciteView extends StatefulWidget {
  const PubliciteView({Key? key}) : super(key: key);

  @override
  State<PubliciteView> createState() => _PubliciteViewState();
}

class _PubliciteViewState extends State<PubliciteView> {
  bool _loading = true;
  bool _isEnabled = true;
  String? _selectedItemId;
  String _selectedTier = 'daily';
  bool _submitting = false;
  double? _walletBalance;
  List<Map<String, dynamic>> _plans = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _items = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final PsValueHolder vh =
          Provider.of<PsValueHolder>(context, listen: false);
      final PsApiService apiService =
          Provider.of<PsApiService>(context, listen: false);
      final AppLocalization lang =
          Provider.of<AppLocalization>(context, listen: false);
      final String userId = Utils.checkUserLoginId(vh);
      final Map<String, String> headers = <String, String>{
        'Accept': 'application/json',
        'Authorization': PsConfig.ps_bearer_token,
        'header-token': vh.headerToken ?? '',
      };

      final List<dynamic> responses = await Future.wait<dynamic>(<Future<dynamic>>[
        http
            .get(Uri.parse('${PsConfig.ps_app_url}ads/config?login_user_id=$userId'),
                headers: headers)
            .timeout(const Duration(seconds: 12)),
        http
            .get(Uri.parse('${PsConfig.ps_app_url}ads/my-items?login_user_id=$userId'),
                headers: headers)
            .timeout(const Duration(seconds: 12)),
        apiService.getWalletBalance(userId, lang.currentLocale.languageCode),
      ]);

      if (!mounted) {
        return;
      }

      final http.Response configRes = responses[0] as http.Response;
      final http.Response itemsRes = responses[1] as http.Response;
      final PsResource<Wallet> walletRes = responses[2] as PsResource<Wallet>;
      _walletBalance =
          double.tryParse((walletRes.data?.balance ?? '0').toString());

      if (configRes.statusCode == 200) {
        final dynamic cDec = json.decode(configRes.body);
        if (cDec is Map<String, dynamic> &&
            cDec['data'] is Map<String, dynamic>) {
          final Map<String, dynamic> d = cDec['data'] as Map<String, dynamic>;
          _isEnabled = d['is_enabled'] == true;
          final List<dynamic> rawPlans =
              (d['item_plans'] as List<dynamic>?) ?? <dynamic>[];
          _plans = rawPlans
              .whereType<Map<String, dynamic>>()
              .where((Map<String, dynamic> p) => p['is_active'] == true)
              .toList();
          if (_plans.isNotEmpty &&
              !_plans.any((Map<String, dynamic> p) =>
                  (p['tier'] ?? '').toString() == _selectedTier)) {
            _selectedTier = (_plans.first['tier'] ?? 'daily').toString();
          }
        }
      }

      if (itemsRes.statusCode == 200) {
        final dynamic iDec = json.decode(itemsRes.body);
        if (iDec is Map<String, dynamic> && iDec['items'] is List<dynamic>) {
          _items = (iDec['items'] as List<dynamic>)
              .whereType<Map<String, dynamic>>()
              .toList();
          if (_items.isNotEmpty && _selectedItemId == null) {
            _selectedItemId = _items.first['id']?.toString();
          }
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _submitBoost() async {
    if (_selectedItemId == null || _submitting) {
      return;
    }
    setState(() => _submitting = true);
    try {
      final PsValueHolder vh =
          Provider.of<PsValueHolder>(context, listen: false);
      final String userId = Utils.checkUserLoginId(vh);

      final http.Response res = await http
          .post(
            Uri.parse('${PsConfig.ps_app_url}ads/boost-item'),
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': PsConfig.ps_bearer_token,
              'header-token': vh.headerToken ?? '',
            },
            body: json.encode(<String, dynamic>{
              'item_id': int.tryParse(_selectedItemId!) ?? _selectedItemId,
              'tier': _selectedTier,
              'login_user_id': userId,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) {
        return;
      }

      final dynamic decoded = json.decode(res.body);
      if (res.statusCode == 200 &&
          decoded is Map<String, dynamic> &&
          decoded['success'] == true) {
        Fluttertoast.showToast(
          msg: decoded['message']?.toString() ?? 'ads__boost_success'.tr,
        );
        await _loadData();
      } else if (decoded is Map<String, dynamic> &&
          decoded['insufficient_balance'] == true) {
        await StoryBoostHelper.showInsufficientBalanceDialog(
          context,
          balance: double.tryParse(
                  (decoded['wallet_balance'] ?? 0).toString()) ??
              0.0,
          requiredAmount: double.tryParse(
                  (decoded['required_amount'] ?? 0).toString()) ??
              0.0,
        );
      } else {
        Fluttertoast.showToast(
          msg: (decoded is Map<String, dynamic>
                  ? decoded['message']?.toString()
                  : null) ??
              'ads__boost_error'.tr,
        );
      }
    } catch (_) {
      Fluttertoast.showToast(msg: 'ads__boost_error'.tr);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLight = Utils.isLightMode(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('ads__menu_title'.tr),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !_isEnabled
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('ads__disabled_msg'.tr,
                        textAlign: TextAlign.center),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: <Widget>[
                      // Header banner
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: <Color>[
                              Color(0xFF1F1635),
                              Color(0xFF4A2545)
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'ads__center_title'.tr,
                              style: const TextStyle(
                                color: Color(0xFFFFD166),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'ads__center_subtitle'.tr,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
                            if (_walletBalance != null) ...<Widget>[
                              const SizedBox(height: 12),
                              InkWell(
                                onTap: () => Navigator.pushNamed(
                                        context, RoutePaths.wallet)
                                    .then((_) => _loadData()),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      const Icon(
                                        Icons.account_balance_wallet_outlined,
                                        color: Color(0xFFFFD166),
                                        size: 15,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${'ads__current_balance'.tr}: ${_walletBalance!.toStringAsFixed(0)} DA',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Step 1: Select Item
                      Text(
                        'ads__select_item'.tr,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (_items.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text('ads__no_items'.tr),
                        )
                      else
                        DropdownButtonFormField<String>(
                          initialValue: _selectedItemId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                          items: _items.map((Map<String, dynamic> it) {
                            final bool boosted = it['is_boosted'] == true;
                            final String label =
                                '${it['title']} (${it['price']} ${it['currency']})${boosted ? ' • Sponsorisé' : ''}';
                            return DropdownMenuItem<String>(
                              value: it['id']?.toString(),
                              child: Text(label,
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (String? v) =>
                              setState(() => _selectedItemId = v),
                        ),
                      const SizedBox(height: 18),

                      // Step 2: Select Plan
                      Text(
                        'ads__select_plan'.tr,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ..._plans.map((Map<String, dynamic> p) {
                        final String tier = (p['tier'] ?? '').toString();
                        final bool selected = tier == _selectedTier;
                        final double price = double.tryParse(
                                (p['price_dzd'] ?? '0').toString()) ??
                            0.0;
                        return InkWell(
                          onTap: () => setState(() => _selectedTier = tier),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: selected
                                  ? PsColors.primary500.withValues(alpha: 0.08)
                                  : (isLight
                                      ? Colors.white
                                      : PsColors.achromatic800),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected
                                    ? PsColors.primary500
                                    : Colors.grey.shade300,
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: <Widget>[
                                Icon(
                                  selected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  color: selected
                                      ? PsColors.primary500
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        (p['title'] ?? '').toString(),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15),
                                      ),
                                      if ((p['description'] ?? '')
                                          .toString()
                                          .isNotEmpty) ...<Widget>[
                                        const SizedBox(height: 3),
                                        Text(
                                          (p['description'] ?? '').toString(),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${price.toStringAsFixed(0)} DA',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: PsColors.primary600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed:
                              (_items.isEmpty || _plans.isEmpty || _submitting)
                                  ? null
                                  : _submitBoost,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PsColors.primary500,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: _submitting
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
                    ],
                  ),
                ),
    );
  }
}
