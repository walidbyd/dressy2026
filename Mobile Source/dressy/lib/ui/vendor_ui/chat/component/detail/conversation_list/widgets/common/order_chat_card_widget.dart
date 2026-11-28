import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../../../../../../config/ps_config.dart';
import '../../../../../../../../config/route/route_paths.dart';
import '../../../../../../../../core/vendor/api/common/ps_resource.dart';
import '../../../../../../../../core/vendor/api/common/ps_status.dart';
import '../../../../../../../../core/vendor/api/ps_api_service.dart';
import '../../../../../../../../core/vendor/constant/ps_constants.dart';
import '../../../../../../../../core/vendor/constant/ps_dimens.dart';
import '../../../../../../../../core/vendor/provider/chat/get_chat_history_provider.dart';
import '../../../../../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../../../../../core/vendor/provider/product/product_provider.dart';
import '../../../../../../../../core/vendor/utils/utils.dart';
import '../../../../../../../../core/vendor/viewobject/api_status.dart';
import '../../../../../../../../core/vendor/viewobject/common/ps_value_holder.dart';
import '../../../../../../../../core/vendor/viewobject/message.dart';

class OrderChatCardWidget extends StatefulWidget {
  const OrderChatCardWidget({
    Key? key,
    required this.messageObj,
    required this.updateDataToFireBase,
    this.buyerUserId,
    this.sellerUserId,
    this.chatFlag,
  }) : super(key: key);

  final Message messageObj;
  final Function updateDataToFireBase;
  final String? buyerUserId;
  final String? sellerUserId;
  final String? chatFlag;

  @override
  State<OrderChatCardWidget> createState() => _OrderChatCardWidgetState();
}

class _OrderChatCardWidgetState extends State<OrderChatCardWidget> {
  bool _isLoading = false;
  List<Map<String, dynamic>>? _yalidineAgencies;
  String? _loadedWilayaId;
  String? _wilayaName;
  bool _loadingAgencies = false;

  Future<void> _loadWilayaAgenciesIfNeeded(String wilayaId) async {
    final String cleanWilaya = wilayaId.trim().isNotEmpty ? wilayaId.trim() : '16';
    if (_loadedWilayaId == cleanWilaya || _loadingAgencies) {
      return;
    }
    _loadedWilayaId = cleanWilaya;
    _loadingAgencies = true;
    try {
      final http.Response res = await http
          .get(Uri.parse('${PsConfig.ps_app_url}yalidine/centers/$cleanWilaya'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200 && mounted) {
        final dynamic decoded = json.decode(res.body);
        if (decoded is Map<String, dynamic>) {
          final List<dynamic> raw =
              (decoded['all_wilaya_centers'] as List<dynamic>?) ??
                  (decoded['centers'] as List<dynamic>?) ??
                  <dynamic>[];
          setState(() {
            _wilayaName = decoded['wilaya_name_fr']?.toString() ??
                decoded['wilaya_name']?.toString();
            _yalidineAgencies =
                raw.whereType<Map<String, dynamic>>().take(6).toList();
          });
        }
      }
    } catch (_) {} finally {
      _loadingAgencies = false;
    }
  }

  Future<void> _handleSellerAction(
      BuildContext context, String action, {String? reason}) async {
    final PsValueHolder psValueHolder =
        Provider.of<PsValueHolder>(context, listen: false);
    final AppLocalization lang =
        Provider.of<AppLocalization>(context, listen: false);

    final String orderId = widget.messageObj.orderId ?? '';
    if (orderId.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final PsApiService apiService = PsApiService();
    final Map<String, dynamic> requestBody = <String, dynamic>{
      'order_id': orderId,
      'action': action,
    };
    if (reason != null && reason.isNotEmpty) {
      requestBody['reason'] = reason;
      requestBody['cancel_reason'] = reason;
    }

    final PsResource<ApiStatus> res = await apiService.postSellerOrderAction(
      requestBody,
      psValueHolder.loginUserId ?? '',
      lang.currentLocale.languageCode,
      headerToken: psValueHolder.headerToken,
    );

    setState(() {
      _isLoading = false;
    });

    if (res.status == PsStatus.SUCCESS) {
      final String newStatus = action == 'confirm' ? 'accepted' : 'cancelled';
      setState(() {
        widget.messageObj.actionStatus = newStatus;
      });

      // Update Firebase RTDB so other party & local list see update immediately
      try {
        final String? sId = widget.messageObj.sessionId;
        final String? msgId = widget.messageObj.id;
        if (sId != null && sId.isNotEmpty && msgId != null && msgId.isNotEmpty) {
          FirebaseDatabase.instance
              .ref()
              .child('Message')
              .child(sId)
              .child(msgId)
              .update(<String, dynamic>{'actionStatus': newStatus});
        }
      } catch (e) {
        // Firebase RTDB fallback
      }

      final String successMsg = action == 'confirm'
          ? 'Commande confirmée avec succès !'
          : 'Commande annulée.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMsg),
          backgroundColor:
              action == 'confirm' ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
        ),
      );
    } else {
      final String errMsg = res.message.isNotEmpty ? res.message : 'Une erreur est survenue.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errMsg),
          backgroundColor: const Color(0xFFC62828),
        ),
      );
    }
  }

  void _showCancelDialog(BuildContext context) {
    final TextEditingController reasonController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: <Widget>[
              Icon(Icons.cancel_outlined, color: Color(0xFFC62828)),
              SizedBox(width: 8),
              Text('Annuler la commande',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Veuillez indiquer le motif de l\'annulation pour le client :',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Ex: Rupture de stock, article non disponible...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Fermer', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC62828),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                final String reason = reasonController.text.trim();
                Navigator.pop(ctx);
                _handleSellerAction(
                  context,
                  'cancel',
                  reason: reason.isNotEmpty ? reason : 'Annulée par le vendeur',
                );
              },
              child: const Text('Confirmer l\'annulation',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _navigateToOrderDetail(
      BuildContext context, String orderId, bool isSeller) {
    if (orderId.isEmpty) {
      return;
    }
    if (isSeller) {
      Navigator.pushNamed(
        context,
        RoutePaths.sellerOrderDetail,
        arguments: <String, dynamic>{'orderId': orderId},
      );
    } else {
      Navigator.pushNamed(
        context,
        RoutePaths.orderDetail,
        arguments: <String, dynamic>{'orderId': orderId},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final PsValueHolder psValueHolder =
        Provider.of<PsValueHolder>(context, listen: false);
    final GetChatHistoryProvider chatHistoryProvider =
        Provider.of<GetChatHistoryProvider>(context);

    final String loginUserId = psValueHolder.loginUserId ?? '';
    final String historySellerId =
        chatHistoryProvider.chatHistory.data?.sellerUserId ?? '';
    final ItemDetailProvider? itemDetailProvider =
        Provider.of<ItemDetailProvider?>(context, listen: false);
    final String itemSellerId = itemDetailProvider?.product.addedUserId ??
        itemDetailProvider?.product.user?.userId ?? '';

    final bool isSeller = (widget.chatFlag == PsConst.CHAT_FROM_SELLER) ||
        (loginUserId.isNotEmpty &&
         (loginUserId == historySellerId ||
          loginUserId == itemSellerId ||
          (widget.sellerUserId != null && widget.sellerUserId!.isNotEmpty && loginUserId == widget.sellerUserId)));
    final bool isBuyer = (widget.chatFlag == PsConst.CHAT_FROM_BUYER) ||
        (widget.buyerUserId != null && widget.buyerUserId!.isNotEmpty && loginUserId == widget.buyerUserId);

    final String messageType = widget.messageObj.messageType ?? '';
    final String actionStatus = widget.messageObj.actionStatus ?? 'none';
    final String orderCode = widget.messageObj.orderCode ?? '';
    final String orderId = widget.messageObj.orderId ?? '';

    final bool isConfirmationRequest =
        messageType == 'order_confirmation_request' ||
            (widget.messageObj.message?.contains('Nouvelle commande #') ?? false) ||
            (widget.messageObj.message?.contains('confirmer la disponibilité') ?? false);

    // Rule: Initial confirmation request goes ONLY to the seller. The buyer must never see it.
    if (isConfirmationRequest && (!isSeller || isBuyer)) {
      return const SizedBox.shrink();
    }

    final String dateStr = Utils.convertTimeStampToDate(
      widget.messageObj.addedDateTimeStamp,
    );

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: PsDimens.space16,
        vertical: PsDimens.space8,
      ),
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (actionStatus == 'accepted' || actionStatus == 'delivered')
                  ? const Color(0xFFC8E6C9)
                  : actionStatus == 'cancelled'
                      ? const Color(0xFFFFCDD2)
                      : const Color(0xFFE8E0D5),
              width: 1.2,
            ),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(PsDimens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Header
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5C1A2B).withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_mall_outlined,
                      color: Color(0xFF5C1A2B),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          isConfirmationRequest
                              ? 'Nouvelle commande reçue'
                              : 'Mise à jour commande',
                          style: const TextStyle(
                            fontFamily: 'PlayfairDisplay',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Color(0xFF2D2424),
                          ),
                        ),
                        if (dateStr.isNotEmpty)
                          Text(
                            dateStr,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF9E9E9E),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (orderCode.isNotEmpty)
                    InkWell(
                      onTap: () =>
                          _navigateToOrderDetail(context, orderId, isSeller),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF7F2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF5C1A2B).withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              '#$orderCode',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF5C1A2B),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 10,
                              color: Color(0xFF5C1A2B),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Message Body
              Text(
                widget.messageObj.message ?? '',
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Color(0xFF4A4440),
                ),
              ),

              const SizedBox(height: 14),

              // Interactive Action Section
              if (isConfirmationRequest && isSeller)
                if (actionStatus == 'pending') ...<Widget>[
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF5C1A2B),
                        ),
                      ),
                    )
                  else
                    Row(
                      children: <Widget>[
                        // Confirm Button
                        Expanded(
                          flex: 3,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () =>
                                _handleSellerAction(context, 'confirm'),
                            icon: const Icon(
                              Icons.check_circle_outline_rounded,
                              size: 18,
                            ),
                            label: const Text(
                              'Je confirme',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Cancel Button
                        Expanded(
                          flex: 2,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFC62828),
                              side: const BorderSide(
                                color: Color(0xFFC62828),
                                width: 1,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () => _showCancelDialog(context),
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 18,
                            ),
                            label: const Text(
                              'J\'annule',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ] else if (actionStatus == 'accepted') ...<Widget>[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(Icons.check_circle,
                            color: Color(0xFF2E7D32), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Commande acceptée ✅',
                          style: TextStyle(
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Builder(builder: (BuildContext ctx) {
                    final String wilayaId =
                        itemDetailProvider?.product.itemLocationId ?? '16';
                    if (_loadedWilayaId != wilayaId) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _loadWilayaAgenciesIfNeeded(wilayaId);
                      });
                    }
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBF2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              const Icon(Icons.local_shipping_outlined,
                                  color: Color(0xFFB45309), size: 18),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'order_chat__deposit_title'.tr,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: Color(0xFF92400E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Copyable Reference Number Badge
                          if (orderCode.isNotEmpty)
                            InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: orderCode));
                                Fluttertoast.showToast(
                                  msg: 'Référence #$orderCode copiée',
                                  toastLength: Toast.LENGTH_SHORT,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: const Color(0xFFF59E0B)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Text(
                                      'Réf : #$orderCode',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12.5,
                                        color: Color(0xFF92400E),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.copy_rounded,
                                        size: 14, color: Color(0xFFB45309)),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            'order_chat__deposit_step_1'.tr,
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.35,
                              color: Color(0xFF78350F),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'order_chat__deposit_step_2'
                                .tr
                                .replaceAll('{code}', orderCode),
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.35,
                              color: Color(0xFF78350F),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'order_chat__deposit_step_3'.tr,
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.35,
                              color: Color(0xFF78350F),
                            ),
                          ),
                          if (_yalidineAgencies != null &&
                              _yalidineAgencies!.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 8),
                            Text(
                              '${'order_chat__yalidine_agencies_title'.tr}${_wilayaName != null ? ' ($_wilayaName)' : ''}:',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF92400E),
                              ),
                            ),
                            const SizedBox(height: 4),
                            ..._yalidineAgencies!.map((Map<String, dynamic> ag) {
                              final String agName =
                                  (ag['name'] ?? '').toString();
                              final String agCommune =
                                  (ag['commune_name'] ?? '').toString();
                              final String agAddr =
                                  (ag['address'] ?? '').toString();
                              final String details = <String>[
                                if (agCommune.isNotEmpty) agCommune,
                                if (agAddr.isNotEmpty) agAddr,
                              ].join(' • ');
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    const Icon(Icons.location_on_outlined,
                                        size: 13, color: Color(0xFFB45309)),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        details.isNotEmpty
                                            ? '$agName ($details)'
                                            : agName,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF78350F),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF5C1A2B),
                            side: const BorderSide(color: Color(0xFF5C1A2B)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () =>
                              _navigateToOrderDetail(context, orderId, true),
                          icon: const Icon(Icons.local_shipping_outlined,
                              size: 16),
                          label: Text(
                            'order_chat__track_order'.tr,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5C1A2B),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () =>
                              _navigateToOrderDetail(context, orderId, true),
                          icon: const Icon(Icons.print_outlined, size: 16),
                          label: Text(
                            'order_chat__print_bordereau'.tr,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (actionStatus == 'delivering') ...<Widget>[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _navigateToOrderDetail(context, orderId, true),
                      icon: const Icon(Icons.local_shipping_outlined, size: 17),
                      label: Text('order_chat__track_order'.tr),
                    ),
                  ),
                ] else if (actionStatus == 'delivered') ...<Widget>[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(Icons.done_all,
                            color: Color(0xFF10B981), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Livré et payé ✨',
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (actionStatus == 'cancelled') ...<Widget>[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(Icons.cancel,
                            color: Color(0xFFC62828), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Commande annulée ❌',
                          style: TextStyle(
                            color: Color(0xFFC62828),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              if (!isSeller && orderId.isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5C1A2B),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () =>
                        _navigateToOrderDetail(context, orderId, false),
                    icon: const Icon(Icons.local_shipping_outlined, size: 17),
                    label: Text('order_chat__track_order'.tr),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
