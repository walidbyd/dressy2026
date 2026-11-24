import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/ps_colors.dart';
import '../../../../config/route/route_paths.dart';
import '../../../../core/vendor/api/common/ps_resource.dart';
import '../../../../core/vendor/api/common/ps_status.dart';
import '../../../../core/vendor/api/ps_api_service.dart';
import '../../../../core/vendor/constant/ps_constants.dart';
import '../../../../core/vendor/constant/ps_dimens.dart';
import '../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../core/vendor/utils/utils.dart';
import '../../../../core/vendor/viewobject/api_status.dart';
import '../../../../core/vendor/viewobject/common/ps_value_holder.dart';
import '../../../../core/vendor/viewobject/holder/intent_holder/chat_history_intent_holder.dart';
import '../../../../core/vendor/viewobject/item_info.dart';
import '../../../../core/vendor/viewobject/order_summary.dart';
import '../../../../core/vendor/viewobject/order_summary_detail.dart';
import '../../../custom_ui/order_detail/component/order_detail_custom_divder.dart';
import '../../../custom_ui/order_detail/component/order_detail_list/order_detail_list.dart';
import '../../../custom_ui/order_detail/component/order_detail_summary.dart';
import '../../common/dialog/error_dialog.dart';
import '../../common/dialog/success_dialog.dart';
import '../../common/ps_button_widget_with_round_corner.dart';
import '../../order_detail/component/user_info/widgets/order_id_date_widget.dart';
import '../../order_detail/component/user_info/widgets/user_info_widget.dart';

class SellerOrderDetailView extends StatefulWidget {
  const SellerOrderDetailView({
    Key? key,
    required this.orderId,
  }) : super(key: key);

  final String orderId;

  @override
  State<SellerOrderDetailView> createState() => _SellerOrderDetailViewState();
}

class _SellerOrderDetailViewState extends State<SellerOrderDetailView> {
  bool _isLoading = true;
  bool _isActionLoading = false;
  OrderSummaryDetail? _orderDetail;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrderDetail();
    });
  }

  Future<void> _loadOrderDetail() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    final PsApiService apiService =
        Provider.of<PsApiService>(context, listen: false);
    final PsValueHolder valueHolder =
        Provider.of<PsValueHolder>(context, listen: false);
    final AppLocalization langProvider =
        Provider.of<AppLocalization>(context, listen: false);

    final String loginUserId = Utils.checkUserLoginId(valueHolder);
    final String languageCode = langProvider.currentLocale.languageCode;

    final PsResource<OrderSummaryModel> res =
        await apiService.getSellerOrderDetail(
      widget.orderId,
      loginUserId,
      languageCode,
    );

    if (mounted) {
      setState(() {
        _orderDetail = res.data?.orderSummaryDetail;
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptOrder() async {
    if (_isActionLoading) return;
    setState(() {
      _isActionLoading = true;
    });

    final PsApiService apiService =
        Provider.of<PsApiService>(context, listen: false);
    final PsValueHolder valueHolder =
        Provider.of<PsValueHolder>(context, listen: false);
    final AppLocalization langProvider =
        Provider.of<AppLocalization>(context, listen: false);

    final String loginUserId = Utils.checkUserLoginId(valueHolder);
    final String languageCode = langProvider.currentLocale.languageCode;

    final PsResource<ApiStatus> res = await apiService.postAcceptOrder(
      <dynamic, dynamic>{'order_id': widget.orderId},
      loginUserId,
      languageCode,
    );

    if (mounted) {
      setState(() {
        _isActionLoading = false;
      });

      if (res.status == PsStatus.SUCCESS) {
        await showDialog<dynamic>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: <Widget>[
                  Icon(Icons.local_shipping_outlined, color: PsColors.primary500, size: 28),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Commande Acceptée !',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Votre commande a été acceptée avec succès. Voici la marche à suivre pour l\'expédition :',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    _buildInstructionStep(
                      context,
                      '1',
                      'Imprimez le bordereau Yalidine',
                      'Cliquez sur le bouton "Imprimer le bordereau Yalidine" ci-dessous pour télécharger et imprimer le PDF.',
                    ),
                    const SizedBox(height: 8),
                    _buildInstructionStep(
                      context,
                      '2',
                      'Emballez l\'article soigneusement',
                      'Placez l\'article dans un emballage propre et scellé, puis collez fermement le bordereau dessus.',
                    ),
                    const SizedBox(height: 8),
                    _buildInstructionStep(
                      context,
                      '3',
                      'Déposez le colis',
                      'Remettez le colis à l\'agence Yalidine la plus proche ou au livreur.',
                    ),
                    const SizedBox(height: 8),
                    _buildInstructionStep(
                      context,
                      '4',
                      'Crédit automatique à la livraison',
                      'Dès que le colis est livré à l\'acheteur, votre portefeuille Dressy sera crédité automatiquement !',
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PsColors.primary500,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Compris',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
        _loadOrderDetail();
      } else {
        await showDialog<dynamic>(
          context: context,
          builder: (BuildContext context) {
            return ErrorDialog(
              message: res.message,
            );
          },
        );
      }
    }
  }

  Future<void> _dispatchOrder() async {
    if (_isActionLoading) return;
    setState(() {
      _isActionLoading = true;
    });

    final PsApiService apiService =
        Provider.of<PsApiService>(context, listen: false);
    final PsValueHolder valueHolder =
        Provider.of<PsValueHolder>(context, listen: false);
    final AppLocalization langProvider =
        Provider.of<AppLocalization>(context, listen: false);

    final String loginUserId = Utils.checkUserLoginId(valueHolder);
    final String languageCode = langProvider.currentLocale.languageCode;

    final PsResource<ApiStatus> res = await apiService.postSendToDeliveryOrder(
      <dynamic, dynamic>{'order_id': widget.orderId},
      loginUserId,
      languageCode,
    );

    if (mounted) {
      setState(() {
        _isActionLoading = false;
      });

      if (res.status == PsStatus.SUCCESS) {
        await showDialog<dynamic>(
          context: context,
          builder: (BuildContext context) {
            return SuccessDialog(
              message: res.data?.message ?? 'seller__order_dispatched_success'.tr,
            );
          },
        );
        _loadOrderDetail();
      } else {
        await showDialog<dynamic>(
          context: context,
          builder: (BuildContext context) {
            return ErrorDialog(
              message: res.message,
            );
          },
        );
      }
    }
  }

  Future<void> _showCancelDialog() async {
    final TextEditingController reasonController = TextEditingController();
    String selectedPreset = '';
    final List<String> presets = <String>[
      'seller__cancel_reason_out_of_stock'.tr,
      'seller__cancel_reason_damaged'.tr,
      'seller__cancel_reason_buyer_request'.tr,
      'seller__cancel_reason_pricing_error'.tr,
    ];

    await showDialog<dynamic>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return AlertDialog(
              title: Text('seller__cancel_order_title'.tr),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'seller__cancel_order_desc'.tr,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: PsDimens.space12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: presets.map((String preset) {
                        final bool isSelected = selectedPreset == preset;
                        return ChoiceChip(
                          label: Text(preset, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : null)),
                          selected: isSelected,
                          selectedColor: PsColors.primary500,
                          onSelected: (bool selected) {
                            setModalState(() {
                              selectedPreset = selected ? preset : '';
                              if (selected) {
                                reasonController.text = preset;
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: PsDimens.space12),
                    TextField(
                      controller: reasonController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'seller__cancel_reason_hint'.tr,
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('dialog__cancel'.tr),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    final String reason = reasonController.text.trim();
                    if (reason.isEmpty) {
                      Fluttertoast.showToast(msg: 'seller__cancel_reason_required'.tr);
                      return;
                    }
                    Navigator.of(context).pop();
                    _cancelOrder(reason);
                  },
                  child: Text('seller__confirm_cancel'.tr, style: const TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _cancelOrder(String reason) async {
    if (_isActionLoading) return;
    setState(() {
      _isActionLoading = true;
    });

    final PsApiService apiService =
        Provider.of<PsApiService>(context, listen: false);
    final PsValueHolder valueHolder =
        Provider.of<PsValueHolder>(context, listen: false);
    final AppLocalization langProvider =
        Provider.of<AppLocalization>(context, listen: false);

    final String loginUserId = Utils.checkUserLoginId(valueHolder);
    final String languageCode = langProvider.currentLocale.languageCode;

    final PsResource<ApiStatus> res = await apiService.postCancelOrder(
      <dynamic, dynamic>{
        'order_id': widget.orderId,
        'cancel_reason': reason,
      },
      loginUserId,
      languageCode,
    );

    if (mounted) {
      setState(() {
        _isActionLoading = false;
      });

      if (res.status == PsStatus.SUCCESS) {
        await showDialog<dynamic>(
          context: context,
          builder: (BuildContext context) {
            return SuccessDialog(
              message: res.data?.message ?? 'seller__order_cancelled_success'.tr,
            );
          },
        );
        _loadOrderDetail();
      } else {
        await showDialog<dynamic>(
          context: context,
          builder: (BuildContext context) {
            return ErrorDialog(
              message: res.message,
            );
          },
        );
      }
    }
  }

  Widget _buildActionButtons() {
    if (_orderDetail == null) return const SizedBox();

    final String status = (_orderDetail?.orderStatus ?? '').toLowerCase();
    final String statusId = _orderDetail?.orderStatusId ?? '';

    final bool isPending = statusId == '1' || status == 'pending';
    final bool isAccepted =
        statusId == '2' || status == 'approved' || status == 'accepted';

    if (!isPending && !isAccepted) {
      return const SizedBox();
    }

    if (_isActionLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: PsDimens.space16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: PsDimens.space16,
        vertical: PsDimens.space16,
      ),
      child: Column(
        children: <Widget>[
          if (isPending) ...<Widget>[
            PSButtonWidgetRoundCorner(
              titleText: 'seller__accept_order'.tr,
              colorData: PsColors.primary500,
              hasShadow: true,
              width: double.infinity,
              height: 48,
              onPressed: _acceptOrder,
            ),
            const SizedBox(height: PsDimens.space12),
          ],
          PSButtonWidgetRoundCorner(
            titleText: 'seller__sent_to_delivery'.tr,
            colorData: Colors.indigo,
            hasShadow: true,
            width: double.infinity,
            height: 48,
            onPressed: _dispatchOrder,
          ),
          const SizedBox(height: PsDimens.space12),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              minimumSize: const Size(double.infinity, 46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(PsDimens.space8),
              ),
            ),
            onPressed: _showCancelDialog,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'seller__cancel_order'.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(
      BuildContext context, String stepNum, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: PsColors.primary500.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            stepNum,
            style: TextStyle(
              color: PsColors.primary500,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusReasonWidget() {
    final String reason = _orderDetail?.statusReason ?? '';
    final String statusId = _orderDetail?.orderStatusId ?? '';
    final String status = (_orderDetail?.orderStatus ?? '').toLowerCase();

    final bool isCancelledOrReturned = statusId == '5' ||
        statusId == '6' ||
        status == 'cancelled' ||
        status == 'returned';

    if (reason.isEmpty && !isCancelledOrReturned) {
      return const SizedBox();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: PsDimens.space16),
      padding: const EdgeInsets.all(PsDimens.space12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: const BorderRadius.all(Radius.circular(PsDimens.space8)),
        border: Border.all(
          color: Colors.red.shade300,
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.info_outline, color: Colors.red, size: 20),
          const SizedBox(width: PsDimens.space8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  statusId == '6' || status == 'returned'
                      ? 'order__status_returned'.tr
                      : 'order__status_cancelled'.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                    fontSize: 14,
                  ),
                ),
                if (reason.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    '${'order__reason'.tr}: $reason',
                    style: TextStyle(
                      color: Colors.red.shade900,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYalidineTrackingWidget() {
    final String tracking = _orderDetail?.yalidineTracking ?? '';
    final String deliveryType = _orderDetail?.deliveryType ?? 'home';
    final bool isStopDesk = deliveryType == 'stop_desk';

    if (tracking.isEmpty) {
      return const SizedBox();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: PsDimens.space16),
      padding: const EdgeInsets.all(PsDimens.space14),
      decoration: BoxDecoration(
        color: Utils.isLightMode(context)
            ? PsColors.achromatic50
            : PsColors.achromatic800,
        borderRadius: const BorderRadius.all(Radius.circular(PsDimens.space10)),
        border: Border.all(
          color: PsColors.primary500.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    Icons.local_shipping_outlined,
                    color: PsColors.primary500,
                    size: 20,
                  ),
                  const SizedBox(width: PsDimens.space8),
                  Text(
                    'seller__yalidine_tracking'.tr.isNotEmpty && 'seller__yalidine_tracking'.tr != 'seller__yalidine_tracking'
                        ? 'seller__yalidine_tracking'.tr
                        : 'Bordereau Yalidine Express',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: PsColors.primary500,
                        ),
                  ),
                ],
              ),
              // Delivery Mode Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isStopDesk
                      ? Colors.amber.withOpacity(0.15)
                      : Colors.blue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isStopDesk ? 'Stop Desk (Point Relais)' : 'Livraison à Domicile',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isStopDesk ? Colors.amber[900] : Colors.blue[900],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: PsDimens.space10),
          Row(
            children: <Widget>[
              Expanded(
                child: SelectableText(
                  tracking,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        letterSpacing: 1.2,
                        fontFamily: 'monospace',
                      ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 20),
                tooltip: 'seller__copy_tracking'.tr,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: tracking));
                  Fluttertoast.showToast(
                    msg: 'seller__tracking_copied'.tr.isNotEmpty && 'seller__tracking_copied'.tr != 'seller__tracking_copied'
                        ? 'seller__tracking_copied'.tr
                        : 'Numéro de suivi copié !',
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                  );
                },
              ),
            ],
          ),
          if ((_orderDetail?.yalidineStatus ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: PsDimens.space4),
              child: Text(
                '${'seller__shipment_status'.tr}: ${_orderDetail?.yalidineStatus}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Utils.isLightMode(context)
                          ? PsColors.text800.withOpacity(0.7)
                          : PsColors.text50.withOpacity(0.7),
                    ),
              ),
            ),
          const SizedBox(height: PsDimens.space12),
          // Prominent Print Shipping Label (PDF) Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: PsColors.burgundy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(PsDimens.space8),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.print_outlined, size: 19),
              label: const Text(
                'Imprimer le bordereau Yalidine (PDF)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              onPressed: () async {
                final String url = (_orderDetail?.yalidineLabelUrl?.isNotEmpty == true)
                    ? _orderDetail!.yalidineLabelUrl!
                    : 'https://api.yalidine.app/v1/parcels/print/?tracking=$tracking';
                final Uri uri = Uri.parse(url);
                try {
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    Fluttertoast.showToast(msg: 'Impossible d\'ouvrir le lien d\'impression.');
                  }
                } catch (e) {
                  Fluttertoast.showToast(msg: 'Erreur: $e');
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarIconBrightness: Utils.getBrightnessForAppBar(context),
        ),
        title: Text(
          'seller__order_detail'.tr,
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                color: Utils.isLightMode(context)
                    ? PsColors.achromatic900
                    : PsColors.achromatic50,
                fontWeight: FontWeight.w500,
                fontSize: PsDimens.space18,
              ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orderDetail == null
              ? Center(
                  child: Text(
                    'seller__order_not_found'.tr,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: <Widget>[
                    OrderIdAndDateWidget(
                      date: _orderDetail?.paymentDate,
                      id: _orderDetail?.orderCode,
                    ),

                    // Order Status Badge
                    Builder(
                      builder: (BuildContext context) {
                        final bool isDeliveredPaid =
                            _orderDetail?.isDeliveredAndPaid == '1' ||
                            (_orderDetail?.orderStatusId == '4') ||
                            (_orderDetail?.orderStatus ?? '')
                                .toLowerCase()
                                .contains('livré et payé') ||
                            (_orderDetail?.orderStatus ?? '')
                                .toLowerCase()
                                .contains('delivered & paid') ||
                            (_orderDetail?.orderStatus ?? '')
                                .contains('تم التوصيل والدفع');

                        if (isDeliveredPaid) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: PsDimens.space12),
                            alignment: Alignment.center,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: PsDimens.space16,
                                  vertical: PsDimens.space6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                border: Border.all(
                                  color: const Color(0xFF10B981),
                                  width: 1.5,
                                ),
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(PsDimens.space8)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  const Icon(Icons.done_all,
                                      size: 18, color: Color(0xFF10B981)),
                                  const SizedBox(width: 6),
                                  Text(
                                    _orderDetail?.deliveredAndPaidLabel ??
                                        (_orderDetail?.orderStatus ?? 'Livré et payé'),
                                    style: const TextStyle(
                                      color: Color(0xFF10B981),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: PsDimens.space12),
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: PsDimens.space12,
                                vertical: PsDimens.space4),
                            decoration: BoxDecoration(
                              color: Utils.codeToColor(
                                _orderDetail?.orderStatusColor?.toString() ?? '',
                                PsColors.primary500,
                              ).withValues(alpha: 0.15),
                              border: Border.all(
                                color: Utils.codeToColor(
                                  _orderDetail?.orderStatusColor?.toString() ?? '',
                                  PsColors.primary500,
                                ),
                              ),
                              borderRadius: const BorderRadius.all(
                                  Radius.circular(PsDimens.space8)),
                            ),
                            child: Text(
                              _orderDetail?.orderStatus ?? '',
                              style: TextStyle(
                                color: Utils.codeToColor(
                                  _orderDetail?.orderStatusColor?.toString() ?? '',
                                  PsColors.primary500,
                                ),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // Wallet Credited Badge
                    if (_orderDetail?.isWalletCredited == '1' ||
                        (_orderDetail?.walletCreditedAt ?? '').isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: PsDimens.space12),
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: PsDimens.space12,
                              vertical: PsDimens.space4),
                          decoration: BoxDecoration(
                            color: PsColors.success50,
                            border: Border.all(color: PsColors.success500),
                            borderRadius: const BorderRadius.all(
                                Radius.circular(PsDimens.space8)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(Icons.check_circle,
                                  color: PsColors.success500, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'seller__credited_to_wallet'.tr,
                                style: TextStyle(
                                  color: PsColors.success500,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Status Reason Banner (if cancelled or returned)
                    _buildStatusReasonWidget(),

                    // Yalidine Tracking Info (when dispatched)
                    _buildYalidineTrackingWidget(),

                    // Buyer Customer Name
                    UserInfoWidget(
                      title: 'seller__customer_name'.tr,
                      values:
                          '${_orderDetail?.shippingFirstName ?? ''} ${_orderDetail?.shippingLastName ?? ''}',
                    ),
                    const CustomOrderDetailCustomDivider(),

                    // Buyer Email
                    UserInfoWidget(
                      title: 'edit_profile__email'.tr,
                      values: _orderDetail?.shippingEmail ?? '',
                    ),
                    const CustomOrderDetailCustomDivider(),

                    // Payment Method & Status
                    UserInfoWidget(
                      isPayment: true,
                      title: 'check_out_payment_method'.tr,
                      values: _orderDetail?.paymentMethod ?? 'Cash on Delivery',
                      paid: _orderDetail?.paymentStatus ?? 'Unpaid',
                    ),
                    const CustomOrderDetailCustomDivider(),

                    // Shipping Address & Phone
                    UserInfoWidget(
                      title: 'transaction_detail__shipping_address'.tr,
                      values:
                          '${_orderDetail?.shippingFirstName ?? ''} ${_orderDetail?.shippingLastName ?? ''}, ${_orderDetail?.shippingPhoneNo ?? ''}, ${_orderDetail?.shippingAddress ?? ''}, ${_orderDetail?.shippingCity ?? ''}, ${_orderDetail?.shippingState ?? ''}, ${_orderDetail?.shippingCountry ?? ''}',
                    ),
                    const CustomOrderDetailCustomDivider(),

                    const SizedBox(height: PsDimens.space16),

                    // Ordered Items List
                    CustomOrderDetailList(
                      title: 'seller__order_items'.tr,
                      itemInfoList:
                          _orderDetail?.itemInfo ?? <ItemInfo>[],
                    ),

                    const CustomOrderDetailCustomDivider(),
                    const SizedBox(height: PsDimens.space8),

                    // Sub Total
                    CustomOrderDetailSummary(
                      title: 'basket_list__sub_total'.tr,
                      value: _orderDetail?.subTotal ?? '\$0.00',
                    ),

                    // Discount
                    if ((_orderDetail?.totalDiscount ?? '').isNotEmpty &&
                        _orderDetail?.totalDiscount != '\$0.00' &&
                        _orderDetail?.totalDiscount != '0')
                      CustomOrderDetailSummary(
                        title: 'dashboard__is_discount'.tr,
                        value: _orderDetail?.totalDiscount ?? '\$0.00',
                        isDiscount: true,
                      ),

                    // Delivery Charges
                    CustomOrderDetailSummary(
                      title: 'delivery_charges'.tr,
                      value: _orderDetail?.deliveryFee ?? '\$0.00',
                    ),

                    const CustomOrderDetailCustomDivider(),
                    const SizedBox(height: PsDimens.space6),

                    // Total
                    Padding(
                      padding: const EdgeInsets.only(bottom: PsDimens.space6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            'transaction_detail__total'.tr,
                            style: TextStyle(
                              color: Utils.isLightMode(context)
                                  ? PsColors.achromatic900
                                  : PsColors.achromatic50,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _orderDetail?.total ?? '\$0.00',
                            style: TextStyle(
                              color: Utils.isLightMode(context)
                                  ? PsColors.achromatic900
                                  : PsColors.achromatic50,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: PsDimens.space12),

                    // Chat with Buyer button
                    _buildChatWithBuyerButton(),

                    // Action buttons (Accept / Dispatch)
                    _buildActionButtons(),

                    const SizedBox(height: PsDimens.space24),
                  ],
                ),
    );
  }

  Widget _buildChatWithBuyerButton() {
    if (_orderDetail == null) {
      return const SizedBox();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: PsDimens.space16,
        vertical: PsDimens.space8,
      ),
      child: SizedBox(
        height: 48,
        child: PSButtonWidgetWithIconRoundCorner(
          icon: Icons.chat_outlined,
          iconColor: Colors.white,
          colorData: PsColors.burgundy,
          width: double.infinity,
          titleText: 'order__chat_with_buyer'.tr.isNotEmpty &&
                  'order__chat_with_buyer'.tr != 'order__chat_with_buyer'
              ? 'order__chat_with_buyer'.tr
              : 'Contacter l\'acheteur',
          onPressed: () {
          final String itemId = (_orderDetail?.itemInfo?.isNotEmpty == true)
              ? (_orderDetail!.itemInfo!.first.itemId ?? '')
              : '';
          final String buyerId =
              _orderDetail?.buyerUserId ?? _orderDetail?.userId ?? '';
          final PsValueHolder valueHolder =
              Provider.of<PsValueHolder>(context, listen: false);
          final String loginUserId = Utils.checkUserLoginId(valueHolder);

          Navigator.pushNamed(
            context,
            RoutePaths.chatView,
            arguments: ChatHistoryIntentHolder(
              chatFlag: PsConst.CHAT_FROM_SELLER,
              itemId: itemId,
              buyerUserId: buyerId,
              sellerUserId: loginUserId,
              userName:
                  '${_orderDetail?.shippingFirstName ?? ''} ${_orderDetail?.shippingLastName ?? ''}'
                      .trim(),
            ),
          );
        },
      ),
    ));
  }
}
