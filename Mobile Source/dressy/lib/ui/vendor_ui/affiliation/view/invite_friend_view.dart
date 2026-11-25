import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../config/ps_colors.dart';
import '../../../../config/ps_config.dart';
import '../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../core/vendor/utils/utils.dart';
import '../../../../core/vendor/viewobject/common/ps_value_holder.dart';

class InviteFriendView extends StatefulWidget {
  const InviteFriendView({Key? key}) : super(key: key);

  @override
  State<InviteFriendView> createState() => _InviteFriendViewState();
}

class _InviteFriendViewState extends State<InviteFriendView> {
  bool _loading = true;
  String? _error;
  String _code = '';
  bool _isActive = true;
  double _issuerPct = 10.0;
  double _receiverPct = 10.0;
  double _totalEarned = 0.0;
  int _totalReferrals = 0;
  List<Map<String, dynamic>> _referrals = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final PsValueHolder vh =
          Provider.of<PsValueHolder>(context, listen: false);
      final String userId = Utils.checkUserLoginId(vh);
      final Uri uri = Uri.parse(
        '${PsConfig.ps_app_url}affiliation/my?login_user_id=$userId',
      );
      final http.Response res = await http.get(
        uri,
        headers: <String, String>{
          'Accept': 'application/json',
          'Authorization': PsConfig.ps_bearer_token,
          'header-token': vh.headerToken ?? '',
        },
      ).timeout(const Duration(seconds: 15));

      if (!mounted) {
        return;
      }

      if (res.statusCode == 200) {
        final dynamic decoded = json.decode(res.body);
        if (decoded is Map<String, dynamic> &&
            decoded['data'] is Map<String, dynamic>) {
          final Map<String, dynamic> d =
              decoded['data'] as Map<String, dynamic>;
          final List<dynamic> rawRefs =
              (d['referrals'] as List<dynamic>?) ?? <dynamic>[];
          setState(() {
            _code = (d['code'] ?? '').toString();
            _isActive = d['is_active'] != false;
            _issuerPct =
                double.tryParse((d['issuer_percentage'] ?? '10').toString()) ??
                    10.0;
            _receiverPct = double.tryParse(
                    (d['receiver_percentage'] ?? '10').toString()) ??
                10.0;
            _totalEarned =
                double.tryParse((d['total_earned_dzd'] ?? '0').toString()) ??
                    0.0;
            _totalReferrals =
                int.tryParse((d['total_referrals'] ?? '0').toString()) ?? 0;
            _referrals = rawRefs.whereType<Map<String, dynamic>>().toList();
            _loading = false;
          });
          return;
        }
      }
      setState(() {
        _loading = false;
        _error = 'affiliation__load_error'.tr;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'affiliation__load_error'.tr;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLight = Utils.isLightMode(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('affiliation__menu_title'.tr),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: <Widget>[
                      const SizedBox(height: 60),
                      Icon(Icons.error_outline,
                          size: 48, color: Colors.red.shade400),
                      const SizedBox(height: 12),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      Center(
                        child: ElevatedButton(
                          onPressed: _loadData,
                          child: Text('coupon__retry'.tr),
                        ),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: <Widget>[
                      // Hero Card with Personal Code
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: <Color>[
                              Color(0xFF1F1635),
                              Color(0xFF4A2545)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          children: <Widget>[
                            const Icon(Icons.card_giftcard,
                                color: Color(0xFFFFD166), size: 40),
                            const SizedBox(height: 10),
                            Text(
                              'affiliation__hero_title'.tr,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${'affiliation__explain_prefix'.tr} ${_receiverPct.toStringAsFixed(0)}% • ${'affiliation__explain_suffix'.tr} ${_issuerPct.toStringAsFixed(0)}%',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: const Color(0xFFFFD166)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    _code,
                                    style: const TextStyle(
                                      color: Color(0xFFFFD166),
                                      fontFamily: 'monospace',
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!_isActive) ...<Widget>[
                              const SizedBox(height: 8),
                              Text(
                                'affiliation__code_inactive'.tr,
                                style: const TextStyle(
                                    color: Colors.redAccent, fontSize: 12),
                              ),
                            ],
                            const SizedBox(height: 14),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _code.isEmpty
                                        ? null
                                        : () {
                                            Clipboard.setData(
                                                ClipboardData(text: _code));
                                            Fluttertoast.showToast(
                                                msg: 'coupon__copied'.tr);
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFFD166),
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                    ),
                                    icon: const Icon(Icons.copy, size: 18),
                                    label: Text('coupon__copy'.tr),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _code.isEmpty
                                        ? null
                                        : () {
                                            SharePlus.instance.share(
                                              ShareParams(
                                                text:
                                                    '${'affiliation__share_text'.tr} $_code (-${_receiverPct.toStringAsFixed(0)}%)',
                                              ),
                                            );
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: PsColors.primary500,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                    ),
                                    icon: const Icon(Icons.share, size: 18),
                                    label: Text('affiliation__share_btn'.tr),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Concept rules card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isLight
                              ? Colors.grey.shade50
                              : PsColors.achromatic800,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isLight
                                ? Colors.grey.shade200
                                : PsColors.achromatic700,
                          ),
                        ),
                        child: Text(
                          'affiliation__rules_summary'.tr,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Stats Row
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: _StatTile(
                              label: 'affiliation__total_invites'.tr,
                              value: '$_totalReferrals',
                              isLight: isLight,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatTile(
                              label: 'affiliation__total_earned'.tr,
                              value: '${_totalEarned.toStringAsFixed(0)} DA',
                              isLight: isLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // History
                      Text(
                        'affiliation__history_title'.tr,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (_referrals.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'affiliation__no_referrals'.tr,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        )
                      else
                        ..._referrals.map((Map<String, dynamic> r) {
                          final bool credited = r['is_credited'] == true;
                          final String amt =
                              (r['issuer_commission_amount'] ?? 0).toString();
                          final String pct =
                              (r['issuer_commission_percent'] ?? 10).toString();
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: credited
                                    ? Colors.green.withValues(alpha: 0.15)
                                    : Colors.amber.withValues(alpha: 0.15),
                                child: Icon(
                                  credited
                                      ? Icons.check_circle
                                      : Icons.hourglass_top,
                                  color: credited ? Colors.green : Colors.amber,
                                ),
                              ),
                              title: Text(
                                (r['receiver_name'] ?? '').toString(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                '#${r['order_code'] ?? ''} • ${credited ? 'affiliation__status_credited'.tr : 'affiliation__status_pending'.tr}',
                              ),
                              trailing: Text(
                                credited ? '+$amt DA' : '$pct%',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: credited
                                      ? Colors.green
                                      : Colors.amber.shade800,
                                ),
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.isLight,
  });

  final String label;
  final String value;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : PsColors.achromatic800,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLight ? Colors.grey.shade200 : PsColors.achromatic700,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
