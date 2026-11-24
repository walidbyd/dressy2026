import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

import '../../../../config/ps_colors.dart';
import '../../../../config/ps_config.dart';
import '../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../core/vendor/utils/utils.dart';

class TrackOrderDialog extends StatefulWidget {
  const TrackOrderDialog({
    Key? key,
    required this.orderId,
    required this.orderCode,
    this.initialTracking = '',
    this.initialStatusId = 1,
    this.initialYalidineStatus = '',
  }) : super(key: key);

  final String orderId;
  final String orderCode;
  final String initialTracking;
  final int initialStatusId;
  final String initialYalidineStatus;

  static Future<void> show(
    BuildContext context, {
    required String orderId,
    required String orderCode,
    String initialTracking = '',
    int initialStatusId = 1,
    String initialYalidineStatus = '',
  }) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => TrackOrderDialog(
        orderId: orderId,
        orderCode: orderCode,
        initialTracking: initialTracking,
        initialStatusId: initialStatusId,
        initialYalidineStatus: initialYalidineStatus,
      ),
    );
  }

  @override
  State<TrackOrderDialog> createState() => _TrackOrderDialogState();
}

class _TrackOrderDialogState extends State<TrackOrderDialog> {
  bool _isLoading = true;
  String? _error;
  String _tracking = '';
  String _yalidineStatus = '';
  int _currentStep = 0;
  bool _isCancelledOrReturned = false;
  String _statusReason = '';
  String _deliveryType = 'home';
  String _destination = '';
  List<Map<String, dynamic>> _histories = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _tracking = widget.initialTracking;
    _yalidineStatus = widget.initialYalidineStatus;
    _currentStep = _inferStepFromLocal(widget.initialStatusId, widget.initialYalidineStatus, widget.initialTracking);
    _isCancelledOrReturned = widget.initialStatusId == 5 || widget.initialStatusId == 6;
    _fetchLiveTracking();
  }

  int _inferStepFromLocal(int statusId, String yalStatus, String tracking) {
    final String lower = yalStatus.toLowerCase();
    if (statusId == 4 || lower.contains('livré') || lower.contains('delivered')) return 5;
    if (statusId == 5 || statusId == 6 || lower.contains('retourn') || lower.contains('annul')) return 5;
    if (lower.contains('sorti') || lower.contains('livraison')) return 4;
    if (lower.contains('expédi') || lower.contains('transit') || lower.contains('centre')) return 3;
    if (statusId == 3 || lower.contains('préparation') || lower.contains('dispatch') || tracking.isNotEmpty) return 2;
    if (statusId == 2) return 1;
    return 0;
  }

  Future<void> _fetchLiveTracking() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final String targetId = widget.orderId.isNotEmpty ? widget.orderId : widget.orderCode;
      final Uri uri = Uri.parse('${PsConfig.ps_app_url}yalidine/tracking/$targetId');
      final http.Response res = await http.get(
        uri,
        headers: <String, String>{
          'Accept': 'application/json',
          'Authorization': PsConfig.ps_bearer_token,
        },
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;
      if (res.statusCode == 200) {
        final dynamic decoded = json.decode(res.body);
        if (decoded is Map<String, dynamic>) {
          final List<dynamic> rawHist = decoded['histories'] as List<dynamic>? ?? <dynamic>[];
          setState(() {
            _tracking = (decoded['tracking'] ?? _tracking).toString();
            _yalidineStatus = (decoded['yalidine_status'] ?? _yalidineStatus).toString();
            _currentStep = int.tryParse((decoded['current_step'] ?? _currentStep).toString()) ?? _currentStep;
            _isCancelledOrReturned = decoded['is_cancelled_or_returned'] == true;
            _statusReason = (decoded['status_reason'] ?? '').toString();
            _deliveryType = (decoded['delivery_type'] ?? 'home').toString();
            final String w = (decoded['to_wilaya_name'] ?? '').toString();
            final String c = (decoded['to_commune_name'] ?? '').toString();
            _destination = <String>[c, w].where((String s) => s.isNotEmpty).join(', ');
            _histories = rawHist.whereType<Map<String, dynamic>>().toList();
            _isLoading = false;
          });
          return;
        }
      }
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _trOr(String key, String fallback) {
    final String v = key.tr;
    return (v.isNotEmpty && v != key) ? v : fallback;
  }

  @override
  Widget build(BuildContext context) {
    final bool isLight = Utils.isLightMode(context);
    final Color cardBg = isLight ? Colors.white : PsColors.achromatic800;
    final Color textColor = isLight ? PsColors.achromatic900 : PsColors.achromatic50;
    final Color mutedColor = isLight ? PsColors.achromatic500 : PsColors.achromatic400;
    final Color brand = PsColors.primary500;

    final List<_TrackStep> steps = <_TrackStep>[
      _TrackStep(
        title: _trOr('order__track_step_pending', 'En attente'),
        subtitle: _trOr('order__track_step_pending_desc', 'Commande enregistrée, en attente du vendeur'),
        icon: Icons.receipt_long_outlined,
      ),
      _TrackStep(
        title: _trOr('order__track_step_accepted', 'Acceptée'),
        subtitle: _trOr('order__track_step_accepted_desc', 'Confirmée par le vendeur'),
        icon: Icons.check_circle_outline,
      ),
      _TrackStep(
        title: _trOr('order__track_step_preparing', 'En préparation'),
        subtitle: _trOr('order__track_step_preparing_desc', 'Colis créé chez Yalidine Express'),
        icon: Icons.inventory_2_outlined,
      ),
      _TrackStep(
        title: _trOr('order__track_step_in_transit', 'Expédié / En transit'),
        subtitle: _trOr('order__track_step_in_transit_desc', 'Colis acheminé vers votre wilaya'),
        icon: Icons.local_shipping_outlined,
      ),
      _TrackStep(
        title: _trOr('order__track_step_out_for_delivery', 'Sorti en livraison'),
        subtitle: _deliveryType == 'stop_desk'
            ? _trOr('order__track_step_stopdesk_desc', 'Disponible au bureau Yalidine')
            : _trOr('order__track_step_out_desc', 'En cours de livraison par le livreur'),
        icon: Icons.delivery_dining_outlined,
      ),
      _TrackStep(
        title: _isCancelledOrReturned
            ? _trOr('order__track_step_returned', 'Retourné / Annulé')
            : _trOr('order__track_step_delivered', 'Livré'),
        subtitle: _isCancelledOrReturned
            ? (_statusReason.isNotEmpty ? _statusReason : _trOr('order__track_step_returned_desc', 'Commande annulée ou retournée'))
            : _trOr('order__track_step_delivered_desc', 'Colis livré avec succès'),
        icon: _isCancelledOrReturned ? Icons.cancel_outlined : Icons.verified_outlined,
      ),
    ];

    final String displayTracking = _tracking.isNotEmpty ? _tracking : '#${widget.orderCode}';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: cardBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
          maxWidth: 440,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Top Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 14),
              decoration: BoxDecoration(
                color: brand.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: brand,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          _trOr('order__track_order_title', 'Suivre ma commande'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        Text(
                          '${_trOr('order_details', 'Commande')} #${widget.orderCode}',
                          style: TextStyle(fontSize: 12.5, color: mutedColor),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh_rounded, color: brand, size: 22),
                    onPressed: _isLoading ? null : _fetchLiveTracking,
                    tooltip: _trOr('custom_dialog__retry', 'Actualiser'),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: mutedColor, size: 22),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Tracking Number Copy Box
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: displayTracking));
                        Fluttertoast.showToast(
                          msg: _trOr('seller__tracking_copied', 'Numéro de suivi copié !'),
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isLight ? PsColors.achromatic50 : PsColors.achromatic900,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: brand.withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    _tracking.isNotEmpty
                                        ? _trOr('order__tracking_number', 'Numéro de suivi Yalidine')
                                        : _trOr('order__reference_number', 'Référence commande'),
                                    style: TextStyle(fontSize: 11, color: mutedColor, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    displayTracking,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                      letterSpacing: 1.0,
                                      color: textColor,
                                    ),
                                  ),
                                  if (_destination.isNotEmpty) ...<Widget>[
                                    const SizedBox(height: 3),
                                    Text(
                                      '📍 $_destination',
                                      style: TextStyle(fontSize: 11.5, color: mutedColor),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: brand.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Icon(Icons.copy_rounded, size: 15, color: brand),
                                  const SizedBox(width: 4),
                                  Text(
                                    _trOr('order__copy', 'Copier'),
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: brand),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_yalidineStatus.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: (_isCancelledOrReturned ? Colors.red : brand).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_trOr('seller__shipment_status', 'Statut Yalidine')} : $_yalidineStatus',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: _isCancelledOrReturned ? Colors.red.shade700 : brand,
                          ),
                        ),
                      ),
                    ],

                    if (_isLoading)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: brand),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _trOr('order__loading_tracking', 'Synchronisation Yalidine en cours...'),
                              style: TextStyle(fontSize: 12, color: mutedColor),
                            ),
                          ],
                        ),
                      ),

                    if (_error != null && _histories.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _trOr('order__tracking_offline', 'Statut local affiché (actualisez pour synchroniser).'),
                          style: TextStyle(fontSize: 11.5, color: mutedColor),
                        ),
                      ),

                    const SizedBox(height: 18),
                    Text(
                      _trOr('order__delivery_timeline', 'Progression de la livraison'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Timeline Schema
                    ...List<Widget>.generate(steps.length, (int idx) {
                      final _TrackStep step = steps[idx];
                      final bool isLast = idx == steps.length - 1;
                      final bool isCompleted = idx < _currentStep || (idx == _currentStep && idx == 5 && !_isCancelledOrReturned);
                      final bool isCurrent = idx == _currentStep;

                      Color dotColor;
                      if (_isCancelledOrReturned && isLast && isCurrent) {
                        dotColor = Colors.red;
                      } else if (isCompleted && idx == 5) {
                        dotColor = Colors.green;
                      } else if (isCompleted || isCurrent) {
                        dotColor = brand;
                      } else {
                        dotColor = isLight ? Colors.grey.shade300 : Colors.grey.shade700;
                      }

                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            SizedBox(
                              width: 34,
                              child: Column(
                                children: <Widget>[
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: (isCompleted || isCurrent) ? dotColor : Colors.transparent,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: dotColor, width: 2),
                                    ),
                                    child: Icon(
                                      isCompleted ? Icons.check_rounded : step.icon,
                                      size: 15,
                                      color: (isCompleted || isCurrent) ? Colors.white : mutedColor,
                                    ),
                                  ),
                                  if (!isLast)
                                    Expanded(
                                      child: Container(
                                        width: 2.5,
                                        margin: const EdgeInsets.symmetric(vertical: 2),
                                        color: idx < _currentStep
                                            ? brand
                                            : (isLight ? Colors.grey.shade300 : Colors.grey.shade700),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(bottom: isLast ? 4 : 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      step.title,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: (isCurrent || isCompleted) ? FontWeight.bold : FontWeight.w500,
                                        color: (isCurrent || isCompleted) ? textColor : mutedColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      step.subtitle,
                                      style: TextStyle(fontSize: 11.5, color: mutedColor),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    // Live Yalidine API Histories
                    if (_histories.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 10),
                      Text(
                        _trOr('order__yalidine_history', 'Historique Yalidine en direct'),
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ..._histories.map((Map<String, dynamic> h) {
                        final String dateStr = (h['date_status'] ?? '').toString();
                        final String statusStr = (h['status'] ?? '').toString();
                        final String center = (h['center_name'] ?? '').toString();
                        final String wilaya = (h['wilaya_name'] ?? '').toString();
                        final String commune = (h['commune_name'] ?? '').toString();
                        final String reason = (h['reason'] ?? '').toString();
                        final String loc = <String>[center, commune, wilaya].where((String s) => s.isNotEmpty).join(' • ');

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isLight ? PsColors.achromatic50 : PsColors.achromatic900,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      statusStr,
                                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: textColor),
                                    ),
                                  ),
                                  if (dateStr.isNotEmpty)
                                    Text(
                                      dateStr,
                                      style: TextStyle(fontSize: 11, color: mutedColor),
                                    ),
                                ],
                              ),
                              if (loc.isNotEmpty) ...<Widget>[
                                const SizedBox(height: 3),
                                Text('📍 $loc', style: TextStyle(fontSize: 11.5, color: mutedColor)),
                              ],
                              if (reason.isNotEmpty) ...<Widget>[
                                const SizedBox(height: 3),
                                Text('ℹ️ $reason', style: TextStyle(fontSize: 11.5, color: Colors.red.shade600)),
                              ],
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackStep {
  const _TrackStep({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
  final String title;
  final String subtitle;
  final IconData icon;
}
