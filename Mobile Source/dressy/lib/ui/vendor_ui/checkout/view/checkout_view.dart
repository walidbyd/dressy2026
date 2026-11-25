import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../../../../core/vendor/constant/ps_dimens.dart';
import '../../../../../core/vendor/api/common/ps_resource.dart';
import '../../../../../core/vendor/api/ps_api_service.dart';
import '../../../../../core/vendor/viewobject/wallet.dart';
import '../../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../../core/vendor/provider/user/user_provider.dart';
import '../../../../../core/vendor/provider/vendor_info/vendor_info_provider.dart';
import '../../../../../core/vendor/provider/vendor_item_bought/vendor_item_bought_provider.dart';
import '../../../../../core/vendor/provider/vendor_paypal_token/vendor_paypal_token_provider.dart';
import '../../../../../core/vendor/repository/order_id_repository.dart';
import '../../../../../core/vendor/repository/product_repository.dart';
import '../../../../../core/vendor/repository/user_repository.dart';
import '../../../../../core/vendor/repository/vendor_info_repository.dart';
import '../../../../../core/vendor/repository/vendor_item_bought_repository.dart';
import '../../../../../core/vendor/repository/vendor_paypal_token_repository.dart';
import '../../../../../core/vendor/repository/vendor_user_repository.dart';
import '../../../../../core/vendor/viewobject/common/ps_value_holder.dart';
import '../../../../../core/vendor/viewobject/holder/request_path_holder.dart';
import '../../../../config/ps_colors.dart';
import '../../../../config/ps_config.dart';
import '../../../../core/vendor/constant/ps_constants.dart';
import '../../../../core/vendor/db/common/ps_data_source_manager.dart';
import '../../../../core/vendor/provider/add_to_cart/add_to_cart_provider.dart';
import '../../../../core/vendor/provider/default_billing_and_shipping/default_shipping_billing_provider.dart';
import '../../../../core/vendor/provider/order_id/get_orderId_provider.dart';
import '../../../../core/vendor/provider/product/product_provider.dart';
import '../../../../core/vendor/provider/vendor_application/vendor_user_detail_provider.dart';
import '../../../../core/vendor/utils/utils.dart';
import '../../../../core/vendor/viewobject/shopping_cart_item.dart';
import '../../../custom_ui/checkout/component/payment/widgets/payment_role_widget.dart';
import '../../../custom_ui/checkout/component/payment/widgets/place_order_button_widget.dart';
import '../../../custom_ui/checkout/item_vertical_list/checkout_avaliable_vertical_list_view.dart';
import '../../../custom_ui/checkout/item_vertical_list/checkout_sold_out_vertical_list_view.dart';
import '../../../custom_ui/checkout/item_vertical_list/widgets/empty_avaliable_shopping_cart.dart';
import '../component/order_summary/order_summary_widget.dart';

String _cleanWilayaName(String name) {
  final RegExp prefixRegex = RegExp(r'^\d+\s*[-–—:]*\s*');
  return name.replaceFirst(prefixRegex, '').trim();
}

class _WilayaOption {
  const _WilayaOption({
    required this.code,
    required this.nameFr,
    required this.nameAr,
  });

  final int code;
  final String nameFr;
  final String nameAr;

  String get cleanNameFr => _cleanWilayaName(nameFr);

  String get displayLabel {
    final String padded = code.toString().padLeft(2, '0');
    final String clean = cleanNameFr;
    return nameAr.isNotEmpty ? '$padded - $clean ($nameAr)' : '$padded - $clean';
  }
}

class _CommuneOption {
  const _CommuneOption({
    required this.id,
    required this.nameFr,
    required this.nameAr,
    required this.wilayaCode,
  });

  final int id;
  final String nameFr;
  final String nameAr;
  final int wilayaCode;

  String get displayLabel => nameAr.isNotEmpty ? '$nameFr ($nameAr)' : nameFr;
}

class _StopDeskOption {
  const _StopDeskOption({
    required this.id,
    required this.name,
    required this.communeName,
    required this.address,
    this.isStopdesk = true,
  });

  final String id;
  final String name;
  final String communeName;
  final String address;
  final bool isStopdesk;
}

class CheckoutView extends StatefulWidget {
  const CheckoutView(
      {Key? key,
      required this.vendorId,
      required this.checkoutItemList,
      this.isSingleItemCheckout = false})
      : super(key: key);

  final List<ShoppingCartItem> checkoutItemList;
  final bool isSingleItemCheckout;
  final String vendorId;

  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView>
    with SingleTickerProviderStateMixin {
  /// Repositories
  OrderIdRepository? orderIdRepository;
  VendorPaypalTokenRepository? vendorPaypalTokenRepository;
  VendorItemBoughtRepository? vendorItemBoughtRepository;
  ProductRepository? productRepository;
  VendorUserRepository? vendorUserDetailRepository;
  VendorInfoRepository? vendorInfoRepository;
  UserRepository? userRepository;

  /// Providers
  VendorPayPalTokenProvider? vendorPayPalTokenProvider;
  VendorItemBoughtProvider? vendorItemBoughtProvider;
  ItemDetailProvider? itemDetailProvider;
  VendorUserDetailProvider? vendorUserDetailProvider;
  late AddToCartProvider addToCartProvider;
  GetOrderIdProvider? getOrderIdProvider;
  DefaultBillingAndShippingProvider? defaultBillingAndShippingProvider;
  VendorInfoProvider? vendorInfoProvider;
  UserProvider? userProvider;

  PsValueHolder? psValueHolder;
  AnimationController? animationController;

  // Recipient form controllers (address-free: Name & Phone only)
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _prefilledName = false;
  bool _prefilledPhone = false;

  // DZBuild dzship Wilaya, Commune & Yalidine quote state
  List<_WilayaOption> _wilayas = _fallbackWilayas;
  List<_CommuneOption> _communes = <_CommuneOption>[];
  List<_StopDeskOption> _stopDesks = <_StopDeskOption>[];
  List<_StopDeskOption> _communeStopDesks = <_StopDeskOption>[];
  bool _fallbackToWilaya = false;
  String? _stopDeskError;
  List<_StopDeskOption> get _allWilayaStopDesks => _stopDesks;

  int _selectedWilayaCode = 16;
  String _selectedWilayaNameFr = 'Alger';
  String _selectedWilayaNameAr = 'الجزائر';
  String _selectedCommuneName = '';
  String _selectedCommuneNameAr = '';

  bool _isStopDesk = true; // Default to Stop-Desk (affordable & fast)
  String? _selectedStopDeskId;
  String _selectedStopDeskName = '';
  String _selectedStopDeskCommune = '';
  String _selectedStopDeskAddress = '';
  bool _isLoadingStopDesks = false;

  int _fromWilayaCode = 16;
  String _fromWilayaName = 'Alger';
  double _stopDeskFeeDzd = 0.0;
  double _homeFeeDzd = 0.0;
  bool _hasLiveQuote = false;
  String? _quoteError;
  int _estimatedDays = 2;

  bool _isLoadingWilayas = false;
  bool _isLoadingCommunes = false;
  bool _isLoadingQuote = false;
  int _quoteRequestSeq = 0;

  // Wallet payment state
  double _walletBalance = 0.0;
  bool _useWallet = false;
  bool _isLoadingWallet = false;

  // Coupon state
  final TextEditingController _couponController = TextEditingController();
  String? _appliedCouponCode;
  double _couponDiscountDzd = 0.0;
  bool _isValidatingCoupon = false;
  String? _couponMessage;
  bool _couponIsValid = false;

  // Affiliation / Referral state
  final TextEditingController _affiliationController = TextEditingController();
  String? _appliedAffiliationCode;
  double _affiliationDiscountDzd = 0.0;
  bool _isValidatingAffiliation = false;
  String? _affiliationMessage;
  bool _affiliationIsValid = false;

  Future<void> _applyCouponCode(double subtotal) async {
    final String code = _couponController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        _couponIsValid = false;
        _couponMessage = 'coupon__enter_code'.tr;
      });
      return;
    }
    setState(() {
      _isValidatingCoupon = true;
      _couponMessage = null;
    });
    try {
      final String userId = Utils.checkUserLoginId(psValueHolder);
      final Uri uri =
          Uri.parse('${PsConfig.ps_app_url}coupons/validate');
      final http.Response res = await http
          .post(
            uri,
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': PsConfig.ps_bearer_token,
              'header-token': psValueHolder?.headerToken ?? '',
            },
            body: json.encode(<String, dynamic>{
              'code': code,
              'subtotal': subtotal,
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
          decoded['valid'] == true) {
        final double discount = double.tryParse(
                decoded['discount_amount']?.toString() ?? '0') ??
            0.0;
        setState(() {
          _isValidatingCoupon = false;
          _couponIsValid = true;
          _appliedCouponCode = code;
          _couponDiscountDzd = discount;
          _couponMessage = decoded['message']?.toString() ?? 'coupon__applied'.tr;
        });
      } else {
        setState(() {
          _isValidatingCoupon = false;
          _couponIsValid = false;
          _appliedCouponCode = null;
          _couponDiscountDzd = 0.0;
          _couponMessage = (decoded is Map<String, dynamic>
                  ? decoded['message']?.toString()
                  : null) ??
              'coupon__invalid'.tr;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isValidatingCoupon = false;
          _couponIsValid = false;
          _appliedCouponCode = null;
          _couponDiscountDzd = 0.0;
          _couponMessage = 'coupon__invalid'.tr;
        });
      }
    }
  }

  void _removeCoupon() {
    setState(() {
      _couponController.clear();
      _appliedCouponCode = null;
      _couponDiscountDzd = 0.0;
      _couponIsValid = false;
      _couponMessage = null;
    });
  }

  Future<void> _applyAffiliationCode(double subtotal) async {
    final String code = _affiliationController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        _affiliationIsValid = false;
        _affiliationMessage = 'affiliation__enter_code'.tr;
      });
      return;
    }
    setState(() {
      _isValidatingAffiliation = true;
      _affiliationMessage = null;
    });
    try {
      final String userId = Utils.checkUserLoginId(psValueHolder);
      final Uri uri =
          Uri.parse('${PsConfig.ps_app_url}affiliation/validate');
      final http.Response res = await http
          .post(
            uri,
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': PsConfig.ps_bearer_token,
              'header-token': psValueHolder?.headerToken ?? '',
            },
            body: json.encode(<String, dynamic>{
              'code': code,
              'subtotal': subtotal,
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
          decoded['valid'] == true) {
        final double discount =
            double.tryParse(decoded['discount_amount']?.toString() ?? '0') ??
                0.0;
        setState(() {
          _isValidatingAffiliation = false;
          _affiliationIsValid = true;
          _appliedAffiliationCode = code;
          _affiliationDiscountDzd = discount;
          _affiliationMessage =
              decoded['message']?.toString() ?? 'coupon__applied'.tr;
        });
      } else {
        setState(() {
          _isValidatingAffiliation = false;
          _affiliationIsValid = false;
          _appliedAffiliationCode = null;
          _affiliationDiscountDzd = 0.0;
          _affiliationMessage = (decoded is Map<String, dynamic>
                  ? decoded['message']?.toString()
                  : null) ??
              'affiliation__invalid'.tr;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isValidatingAffiliation = false;
          _affiliationIsValid = false;
          _appliedAffiliationCode = null;
          _affiliationDiscountDzd = 0.0;
          _affiliationMessage = 'affiliation__invalid'.tr;
        });
      }
    }
  }

  void _removeAffiliation() {
    setState(() {
      _affiliationController.clear();
      _appliedAffiliationCode = null;
      _affiliationDiscountDzd = 0.0;
      _affiliationIsValid = false;
      _affiliationMessage = null;
    });
  }

  static const List<_WilayaOption> _fallbackWilayas = <_WilayaOption>[
    _WilayaOption(code: 1, nameFr: 'Adrar', nameAr: 'أدرار'),
    _WilayaOption(code: 2, nameFr: 'Chlef', nameAr: 'الشلف'),
    _WilayaOption(code: 3, nameFr: 'Laghouat', nameAr: 'الأغواط'),
    _WilayaOption(code: 4, nameFr: 'Oum El Bouaghi', nameAr: 'أم البواقي'),
    _WilayaOption(code: 5, nameFr: 'Batna', nameAr: 'باتنة'),
    _WilayaOption(code: 6, nameFr: 'Béjaïa', nameAr: 'بجاية'),
    _WilayaOption(code: 7, nameFr: 'Biskra', nameAr: 'بسكرة'),
    _WilayaOption(code: 8, nameFr: 'Béchar', nameAr: 'بشار'),
    _WilayaOption(code: 9, nameFr: 'Blida', nameAr: 'البليدة'),
    _WilayaOption(code: 10, nameFr: 'Bouira', nameAr: 'البويرة'),
    _WilayaOption(code: 11, nameFr: 'Tamanrasset', nameAr: 'تمنراست'),
    _WilayaOption(code: 12, nameFr: 'Tébessa', nameAr: 'تبسة'),
    _WilayaOption(code: 13, nameFr: 'Tlemcen', nameAr: 'تلمسان'),
    _WilayaOption(code: 14, nameFr: 'Tiaret', nameAr: 'تيارت'),
    _WilayaOption(code: 15, nameFr: 'Tizi Ouzou', nameAr: 'تيزي وزو'),
    _WilayaOption(code: 16, nameFr: 'Alger', nameAr: 'الجزائر'),
    _WilayaOption(code: 17, nameFr: 'Djelfa', nameAr: 'الجلفة'),
    _WilayaOption(code: 18, nameFr: 'Jijel', nameAr: 'جيجل'),
    _WilayaOption(code: 19, nameFr: 'Sétif', nameAr: 'سطيف'),
    _WilayaOption(code: 20, nameFr: 'Saïda', nameAr: 'سعيدة'),
    _WilayaOption(code: 21, nameFr: 'Skikda', nameAr: 'سكيكدة'),
    _WilayaOption(code: 22, nameFr: 'Sidi Bel Abbès', nameAr: 'سيدي بلعباس'),
    _WilayaOption(code: 23, nameFr: 'Annaba', nameAr: 'عنابة'),
    _WilayaOption(code: 24, nameFr: 'Guelma', nameAr: 'قالمة'),
    _WilayaOption(code: 25, nameFr: 'Constantine', nameAr: 'قسنطينة'),
    _WilayaOption(code: 26, nameFr: 'Médéa', nameAr: 'المدية'),
    _WilayaOption(code: 27, nameFr: 'Mostaganem', nameAr: 'مستغانم'),
    _WilayaOption(code: 28, nameFr: "M'Sila", nameAr: 'المسيلة'),
    _WilayaOption(code: 29, nameFr: 'Mascara', nameAr: 'معسكر'),
    _WilayaOption(code: 30, nameFr: 'Ouargla', nameAr: 'ورقلة'),
    _WilayaOption(code: 31, nameFr: 'Oran', nameAr: 'وهران'),
    _WilayaOption(code: 32, nameFr: 'El Bayadh', nameAr: 'البيض'),
    _WilayaOption(code: 33, nameFr: 'Illizi', nameAr: 'إليزي'),
    _WilayaOption(code: 34, nameFr: 'Bordj Bou Arréridj', nameAr: 'برج بوعريريج'),
    _WilayaOption(code: 35, nameFr: 'Boumerdès', nameAr: 'بومرداس'),
    _WilayaOption(code: 36, nameFr: 'El Tarf', nameAr: 'الطارف'),
    _WilayaOption(code: 37, nameFr: 'Tindouf', nameAr: 'تندوف'),
    _WilayaOption(code: 38, nameFr: 'Tissemsilt', nameAr: 'تيسمسيلت'),
    _WilayaOption(code: 39, nameFr: 'El Oued', nameAr: 'الوادي'),
    _WilayaOption(code: 40, nameFr: 'Khenchela', nameAr: 'خنشلة'),
    _WilayaOption(code: 41, nameFr: 'Souk Ahras', nameAr: 'سوق أهراس'),
    _WilayaOption(code: 42, nameFr: 'Tipaza', nameAr: 'تيبازة'),
    _WilayaOption(code: 43, nameFr: 'Mila', nameAr: 'ميلة'),
    _WilayaOption(code: 44, nameFr: 'Aïn Defla', nameAr: 'عين الدفلى'),
    _WilayaOption(code: 45, nameFr: 'Naâma', nameAr: 'النعامة'),
    _WilayaOption(code: 46, nameFr: 'Aïn Témouchent', nameAr: 'عين تموشنت'),
    _WilayaOption(code: 47, nameFr: 'Ghardaïa', nameAr: 'غرداية'),
    _WilayaOption(code: 48, nameFr: 'Relizane', nameAr: 'غليزان'),
    _WilayaOption(code: 49, nameFr: 'Timimoun', nameAr: 'تيميمون'),
    _WilayaOption(code: 50, nameFr: 'Bordj Badji Mokhtar', nameAr: 'برج باجي مختار'),
    _WilayaOption(code: 51, nameFr: 'Ouled Djellal', nameAr: 'أولاد جلال'),
    _WilayaOption(code: 52, nameFr: 'Béni Abbès', nameAr: 'بني عباس'),
    _WilayaOption(code: 53, nameFr: 'In Salah', nameAr: 'عين صالح'),
    _WilayaOption(code: 54, nameFr: 'In Guezzam', nameAr: 'عين قزام'),
    _WilayaOption(code: 55, nameFr: 'Touggourt', nameAr: 'تقرت'),
    _WilayaOption(code: 56, nameFr: 'Djanet', nameAr: 'جانت'),
    _WilayaOption(code: 57, nameFr: "El M'Ghair", nameAr: 'المغير'),
    _WilayaOption(code: 58, nameFr: 'El Meniaa', nameAr: 'المنيعة'),
  ];

  @override
  void initState() {
    animationController =
        AnimationController(duration: PsConfig.animation_duration, vsync: this);
    super.initState();
    _nameController.addListener(_onFormChanged);
    _phoneController.addListener(_onFormChanged);
    _loadWilayasAndInitialData();
  }

  void _onFormChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFormChanged);
    _phoneController.removeListener(_onFormChanged);
    _nameController.dispose();
    _phoneController.dispose();
    animationController?.dispose();
    super.dispose();
  }

  String? get _primaryItemId {
    if (widget.checkoutItemList.isNotEmpty) {
      return widget.checkoutItemList.first.itemId;
    }
    return null;
  }

  Future<void> _loadWilayasAndInitialData() async {
    _fetchWalletBalance();
    await _fetchWilayas();
    await _onWilayaSelected(_selectedWilayaCode);
  }

  Future<void> _fetchWalletBalance() async {
    if (!mounted) {
      return;
    }
    final PsValueHolder? valueHolder = psValueHolder ??
        Provider.of<PsValueHolder>(context, listen: false);
    final String loginUserId = Utils.checkUserLoginId(valueHolder);
    if (loginUserId.isEmpty) {
      return;
    }
    setState(() {
      _isLoadingWallet = true;
    });
    try {
      final AppLocalization? langProvider =
          Provider.of<AppLocalization>(context, listen: false);
      final String languageCode =
          langProvider?.currentLocale.languageCode ?? 'fr';
      final PsApiService apiService =
          Provider.of<PsApiService>(context, listen: false);
      final PsResource<Wallet> res =
          await apiService.getWalletBalance(loginUserId, languageCode);
      if (mounted && res.data != null) {
        final double bal = double.tryParse(res.data?.balance ?? '0') ?? 0.0;
        setState(() {
          _walletBalance = bal;
          _isLoadingWallet = false;
        });
      } else if (mounted) {
        setState(() {
          _isLoadingWallet = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingWallet = false;
        });
      }
    }
  }

  Future<void> _fetchWilayas() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoadingWilayas = true;
    });
    try {
      final Uri uri = Uri.parse('${PsConfig.ps_app_url}shipping/wilayas');
      final http.Response response = await http.get(
        uri,
        headers: <String, String>{
          'Accept': 'application/json',
          'Authorization': PsConfig.ps_bearer_token,
        },
      ).timeout(const Duration(seconds: 15));

      if (!mounted) {
        return;
      }

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);
        final List<dynamic> list = decoded is Map<String, dynamic>
            ? (decoded['wilayas'] as List<dynamic>? ?? <dynamic>[])
            : (decoded is List<dynamic> ? decoded : <dynamic>[]);

        final List<_WilayaOption> parsed = <_WilayaOption>[];
        for (final dynamic item in list) {
          if (item is Map<String, dynamic>) {
            final int? code = int.tryParse(item['code']?.toString() ?? item['id']?.toString() ?? '');
            final String nameFr =
                _cleanWilayaName((item['name_fr'] ?? item['name'] ?? item['nameFr'] ?? '').toString());
            final String nameAr =
                (item['name_ar'] ?? item['nameAr'] ?? '').toString().trim();
            if (code != null && code >= 1 && nameFr.isNotEmpty) {
              parsed.add(_WilayaOption(
                  code: code, nameFr: nameFr, nameAr: nameAr));
            }
          }
        }
        if (parsed.isNotEmpty) {
          parsed.sort((_WilayaOption a, _WilayaOption b) =>
              a.code.compareTo(b.code));
          setState(() {
            _wilayas = parsed;
            final _WilayaOption current = _wilayas.firstWhere(
              (_WilayaOption w) => w.code == _selectedWilayaCode,
              orElse: () => _wilayas.first,
            );
            _selectedWilayaNameFr = _cleanWilayaName(current.nameFr);
            _selectedWilayaNameAr = current.nameAr;
          });
        }
      }
    } catch (_) {
      // Keep fallback wilayas seamlessly
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingWilayas = false;
        });
      }
    }
  }

  Future<void> _onWilayaSelected(int wilayaCode) async {
    final _WilayaOption chosen = _wilayas.firstWhere(
      (_WilayaOption w) => w.code == wilayaCode,
      orElse: () => _WilayaOption(
          code: wilayaCode, nameFr: 'Wilaya $wilayaCode', nameAr: ''),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedWilayaCode = chosen.code;
      _selectedWilayaNameFr = _cleanWilayaName(chosen.nameFr);
      _selectedWilayaNameAr = chosen.nameAr;
      _communes = <_CommuneOption>[];
      _selectedCommuneName = '';
      _selectedCommuneNameAr = '';
      _stopDesks = <_StopDeskOption>[];
      _communeStopDesks = <_StopDeskOption>[];
      _fallbackToWilaya = false;
      _stopDeskError = null;
      _selectedStopDeskId = null;
      _selectedStopDeskName = '';
      _selectedStopDeskCommune = '';
      _selectedStopDeskAddress = '';
      _isLoadingCommunes = true;
      _isLoadingStopDesks = true;
    });

    await Future.wait(<Future<void>>[
      _fetchCommunes(chosen.code),
      _fetchStopDesks(chosen.code),
    ]);
    await _fetchYalidineQuote();
  }

  List<_StopDeskOption> _parseStopDeskList(List<dynamic> rawList) {
    final List<_StopDeskOption> parsed = <_StopDeskOption>[];
    for (final dynamic item in rawList) {
      if (item is Map<String, dynamic>) {
        final String id =
            (item['center_id'] ?? item['id'] ?? '').toString().trim();
        final String name =
            (item['name'] ?? item['center_name'] ?? '').toString().trim();
        final String cName = (item['commune_name'] ??
                item['communeName'] ??
                item['commune'] ??
                _selectedWilayaNameFr)
            .toString()
            .trim();
        final String addr = (item['address'] ?? cName).toString().trim();
        final bool isStopdesk = item['is_stopdesk'] == null ||
            item['is_stopdesk'] == true ||
            item['is_stopdesk'].toString() == '1' ||
            item['is_stopdesk'].toString().toLowerCase() == 'true';

        if (id.isNotEmpty && name.isNotEmpty) {
          parsed.add(_StopDeskOption(
            id: id,
            name: name,
            communeName: cName,
            address: addr,
            isStopdesk: isStopdesk,
          ));
        }
      }
    }
    return parsed;
  }

  void _applyStopDesks(List<_StopDeskOption> parsed) {
    if (!mounted || parsed.isEmpty) {
      return;
    }

    _StopDeskOption? candidate;
    if (_selectedStopDeskId != null && _selectedStopDeskId!.isNotEmpty) {
      for (final _StopDeskOption d in parsed) {
        if (d.id == _selectedStopDeskId) {
          candidate = d;
          break;
        }
      }
    }

    if (candidate == null && _selectedCommuneName.isNotEmpty) {
      final String cleanCommune = _selectedCommuneName.toLowerCase().trim();
      for (final _StopDeskOption d in parsed) {
        final String dCommune = d.communeName.toLowerCase().trim();
        final String dName = d.name.toLowerCase().trim();
        if (dCommune == cleanCommune ||
            dCommune.contains(cleanCommune) ||
            cleanCommune.contains(dCommune) ||
            dName.contains(cleanCommune)) {
          candidate = d;
          break;
        }
      }
    }

    candidate ??= parsed.first;

    setState(() {
      _selectedStopDeskId = candidate!.id;
      _selectedStopDeskName = candidate.name;
      _selectedStopDeskCommune = candidate.communeName;
      _selectedStopDeskAddress = candidate.address;
    });
  }

  Future<void> _fetchStopDesks(int wilayaCode,
      {int? communeId, String? communeName, bool refresh = false}) async {
    setState(() {
      _isLoadingStopDesks = true;
    });

    try {
      final List<String> queryParts = <String>[];
      if (refresh) {
        queryParts.add('refresh=1');
      }
      if (communeId != null && communeId > 0) {
        queryParts.add('commune_id=$communeId');
      }
      final String effectiveCommune =
          (communeName ?? _selectedCommuneName).trim();
      if (effectiveCommune.isNotEmpty) {
        queryParts.add('commune_name=${Uri.encodeComponent(effectiveCommune)}');
      }

      final String queryString =
          queryParts.isNotEmpty ? '?${queryParts.join('&')}' : '';
      final Uri uri = Uri.parse(
          '${PsConfig.ps_app_url}yalidine/centers/$wilayaCode$queryString');
      final http.Response response = await http.get(
        uri,
        headers: <String, String>{
          'Accept': 'application/json',
          'Authorization': PsConfig.ps_bearer_token,
        },
      ).timeout(const Duration(seconds: 15));

      if (!mounted || _selectedWilayaCode != wilayaCode) {
        return;
      }

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          final bool isFallback = decoded['fallback_to_wilaya'] == true;
          final List<dynamic> rawMatching =
              decoded['centers'] as List<dynamic>? ??
                  decoded['desks'] as List<dynamic>? ??
                  <dynamic>[];
          final List<dynamic> rawAll =
              decoded['all_wilaya_centers'] as List<dynamic>? ?? rawMatching;

          final List<_StopDeskOption> parsedMatching =
              _parseStopDeskList(rawMatching);
          final List<_StopDeskOption> parsedAll =
              _parseStopDeskList(rawAll);

          if (parsedAll.isNotEmpty || parsedMatching.isNotEmpty) {
            final List<_StopDeskOption> allList =
                parsedAll.isNotEmpty ? parsedAll : parsedMatching;
            final List<_StopDeskOption> commList =
                isFallback ? <_StopDeskOption>[] : parsedMatching;

            setState(() {
              _stopDesks = allList;
              _communeStopDesks = commList;
              _fallbackToWilaya = isFallback;
              _stopDeskError = null;
            });

            _applyStopDesks(commList.isNotEmpty ? commList : allList);
            return;
          } else {
            final String apiMsg = (decoded['message'] ?? decoded['error'] ?? '').toString();
            setState(() {
              _stopDesks = <_StopDeskOption>[];
              _communeStopDesks = <_StopDeskOption>[];
              _stopDeskError = apiMsg.isNotEmpty ? apiMsg : null;
            });
          }
        }
      } else {
        try {
          final dynamic decoded = json.decode(response.body);
          if (decoded is Map<String, dynamic>) {
            final String apiMsg = (decoded['message'] ?? decoded['error'] ?? '').toString();
            if (apiMsg.isNotEmpty) {
              setState(() {
                _stopDesks = <_StopDeskOption>[];
                _communeStopDesks = <_StopDeskOption>[];
                _stopDeskError = apiMsg;
              });
            }
          }
        } catch (_) {
          setState(() {
            _stopDesks = <_StopDeskOption>[];
            _communeStopDesks = <_StopDeskOption>[];
            _stopDeskError = 'Erreur HTTP ${response.statusCode}';
          });
        }
      }
    } catch (e) {
      if (mounted && _selectedWilayaCode == wilayaCode) {
        setState(() {
          _stopDesks = <_StopDeskOption>[];
          _communeStopDesks = <_StopDeskOption>[];
          _stopDeskError = e.toString();
        });
      }
    } finally {
      if (mounted && _selectedWilayaCode == wilayaCode) {
        setState(() {
          _isLoadingStopDesks = false;
        });
      }
    }
  }

  Future<void> _fetchCommunes(int wilayaCode) async {
    try {
      final Uri uri = Uri.parse(
          '${PsConfig.ps_app_url}shipping/communes?wilaya=$wilayaCode');
      final http.Response response = await http.get(
        uri,
        headers: <String, String>{
          'Accept': 'application/json',
          'Authorization': PsConfig.ps_bearer_token,
        },
      ).timeout(const Duration(seconds: 15));

      if (!mounted || _selectedWilayaCode != wilayaCode) {
        return;
      }

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);
        final List<dynamic> list = decoded is Map<String, dynamic>
            ? (decoded['communes'] as List<dynamic>? ?? <dynamic>[])
            : (decoded is List<dynamic> ? decoded : <dynamic>[]);

        final List<_CommuneOption> parsed = <_CommuneOption>[];
        int fallbackId = wilayaCode * 1000 + 1;
        for (final dynamic item in list) {
          if (item is Map<String, dynamic>) {
            final String nameFr =
                (item['name_fr'] ?? item['name'] ?? item['nameFr'] ?? '').toString().trim();
            final String nameAr =
                (item['name_ar'] ?? item['nameAr'] ?? '').toString().trim();
            if (nameFr.isNotEmpty) {
              parsed.add(_CommuneOption(
                id: int.tryParse(item['id']?.toString() ?? '') ?? fallbackId++,
                nameFr: nameFr,
                nameAr: nameAr,
                wilayaCode: wilayaCode,
              ));
            }
          }
        }

        // Also parse stop desk centers if returned
        final List<dynamic> rawCenters = decoded is Map<String, dynamic>
            ? (decoded['centers'] as List<dynamic>? ?? <dynamic>[])
            : <dynamic>[];
        final List<_StopDeskOption> parsedDesks = <_StopDeskOption>[];
        for (final dynamic c in rawCenters) {
          if (c is Map<String, dynamic>) {
            final String id = (c['center_id'] ?? c['id'] ?? '').toString().trim();
            final String name = (c['name'] ?? '').toString().trim();
            final String cName = (c['commune_name'] ?? c['commune'] ?? _selectedWilayaNameFr).toString().trim();
            final String addr = (c['address'] ?? cName).toString().trim();
            if (id.isNotEmpty && name.isNotEmpty) {
              parsedDesks.add(_StopDeskOption(
                id: id,
                name: name,
                communeName: cName,
                address: addr,
              ));
            }
          }
        }

        if (parsed.isNotEmpty) {
          parsed.sort((_CommuneOption a, _CommuneOption b) =>
              a.nameFr.compareTo(b.nameFr));
          setState(() {
            _communes = parsed;
            _selectedCommuneName = parsed.first.nameFr;
            _selectedCommuneNameAr = parsed.first.nameAr;
          });
          _fetchStopDesks(wilayaCode,
              communeId: parsed.first.id, communeName: parsed.first.nameFr);
          if (parsedDesks.isNotEmpty && _stopDesks.isEmpty) {
            _applyStopDesks(parsedDesks);
          }
          return;
        }
      }
    } catch (_) {
      // Fallback below
    } finally {
      if (mounted && _selectedWilayaCode == wilayaCode) {
        setState(() {
          _isLoadingCommunes = false;
        });
      }
    }

    if (mounted && _selectedWilayaCode == wilayaCode && _communes.isEmpty) {
      final _CommuneOption fallback = _CommuneOption(
        id: wilayaCode * 1000 + 1,
        nameFr: _selectedWilayaNameFr,
        nameAr: _selectedWilayaNameAr,
        wilayaCode: wilayaCode,
      );
      setState(() {
        _communes = <_CommuneOption>[fallback];
        _selectedCommuneName = fallback.nameFr;
        _selectedCommuneNameAr = fallback.nameAr;
      });
    }
  }

  Future<void> _fetchYalidineQuote() async {
    if (!mounted) {
      return;
    }
    final int reqSeq = ++_quoteRequestSeq;
    setState(() {
      _isLoadingQuote = true;
    });

    try {
      final Uri uri =
          Uri.parse('${PsConfig.ps_app_url}shipping/yalidine-quote');
      final Map<String, dynamic> payload = <String, dynamic>{
        'to_wilaya_code': _selectedWilayaCode,
        if (_selectedCommuneName.isNotEmpty)
          'to_commune_name': _selectedCommuneName,
        if (_primaryItemId != null && _primaryItemId!.isNotEmpty)
          'item_id': int.tryParse(_primaryItemId!) ?? _primaryItemId,
        if (widget.vendorId.isNotEmpty)
          'vendor_id': int.tryParse(widget.vendorId) ?? widget.vendorId,
      };

      final http.Response response = await http
          .post(
            uri,
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': PsConfig.ps_bearer_token,
            },
            body: json.encode(payload),
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted || reqSeq != _quoteRequestSeq) {
        return;
      }

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic> && decoded['status'] != 'error') {
          final Map<String, dynamic>? stopDeskMap =
              decoded['stop_desk'] as Map<String, dynamic>?;
          final Map<String, dynamic>? homeMap =
              decoded['home_delivery'] as Map<String, dynamic>?;

          final double? deskPrice = double.tryParse(
              (stopDeskMap?['price_dzd'] ?? decoded['desk_fee'] ?? '')
                  .toString());
          final double? homePrice = double.tryParse(
              (homeMap?['price_dzd'] ?? decoded['home_fee'] ?? '').toString());

          if (deskPrice == null ||
              deskPrice <= 0 ||
              homePrice == null ||
              homePrice <= 0) {
            setState(() {
              _hasLiveQuote = false;
              _quoteError = decoded['message']?.toString() ??
                  'Tarif Yalidine indisponible';
            });
            return;
          }

          final int fromW = int.tryParse(
                  decoded['from_wilaya_code']?.toString() ?? '') ??
              16;
          final String fromWName =
              (decoded['from_wilaya_name'] ?? 'Alger').toString();
          final int estDays = int.tryParse(
                  (stopDeskMap?['estimated_days'] ??
                          homeMap?['estimated_days'] ??
                          '2')
                      .toString()) ??
              2;

          final List<dynamic> rawDesks =
              (stopDeskMap?['desks'] as List<dynamic>?) ?? <dynamic>[];
          final List<_StopDeskOption> parsedDesks = <_StopDeskOption>[];
          for (final dynamic d in rawDesks) {
            if (d is Map<String, dynamic>) {
              final String id = (d['id'] ?? '').toString().trim();
              final String name = (d['name'] ?? '').toString().trim();
              final String cName =
                  (d['communeName'] ?? d['commune_name'] ?? _selectedWilayaNameFr)
                      .toString()
                      .trim();
              final String addr = (d['address'] ?? cName).toString().trim();
              if (id.isNotEmpty && name.isNotEmpty) {
                parsedDesks.add(_StopDeskOption(
                  id: id,
                  name: name,
                  communeName: cName,
                  address: addr,
                ));
              }
            }
          }

          setState(() {
            _fromWilayaCode = fromW;
            _fromWilayaName = fromWName;
            _stopDeskFeeDzd = deskPrice;
            _homeFeeDzd = homePrice;
            _hasLiveQuote = true;
            _quoteError = null;
            _estimatedDays = estDays;
          });

          if (parsedDesks.isNotEmpty &&
              (_stopDesks.isEmpty || parsedDesks.length >= _stopDesks.length)) {
            _applyStopDesks(parsedDesks);
          }
          return;
        }
      }
      if (mounted && reqSeq == _quoteRequestSeq) {
        setState(() {
          _hasLiveQuote = false;
          _quoteError = 'Impossible de récupérer le tarif Yalidine en direct.';
        });
      }
    } catch (_) {
      if (mounted && reqSeq == _quoteRequestSeq) {
        setState(() {
          _hasLiveQuote = false;
          _quoteError = 'Erreur réseau lors du calcul du tarif Yalidine.';
        });
      }
    } finally {
      if (mounted && reqSeq == _quoteRequestSeq) {
        setState(() {
          _isLoadingQuote = false;
        });
      }
    }
  }

  void _tryPrefillRecipientFromProfile(
      UserProvider? uProvider, DefaultBillingAndShippingProvider? shipProvider) {
    if (!_prefilledName && _nameController.text.trim().isEmpty) {
      String candidate = (uProvider?.user.data?.name ?? '').trim();
      if (candidate.isEmpty) {
        candidate = (psValueHolder?.loginUserName ?? '').trim();
      }
      if (candidate.isEmpty) {
        final String f =
            (shipProvider?.defaultBillingAndShipping.data?.shippingFirstName ??
                    '')
                .trim();
        final String l =
            (shipProvider?.defaultBillingAndShipping.data?.shippingLastName ??
                    '')
                .trim();
        candidate = '$f $l'.trim();
      }
      if (candidate.isNotEmpty && candidate != '-') {
        _prefilledName = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _nameController.text.trim().isEmpty) {
            _nameController.text = candidate;
          }
        });
      }
    }

    if (!_prefilledPhone && _phoneController.text.trim().isEmpty) {
      String candidate = (uProvider?.user.data?.userPhone ?? '').trim();
      if (candidate.isEmpty) {
        candidate =
            (shipProvider?.defaultBillingAndShipping.data?.shippingPhoneNo ??
                    '')
                .trim();
      }
      if (candidate.isNotEmpty) {
        candidate = candidate.replaceAll('-', '').trim();
        _prefilledPhone = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _phoneController.text.trim().isEmpty) {
            _phoneController.text = candidate;
          }
        });
      }
    }
  }

  Future<void> _showWilayaPickerSheet() async {
    String query = '';
    final _WilayaOption? selected = await showModalBottomSheet<_WilayaOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Utils.isLightMode(context) ? Colors.white : PsColors.achromatic800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final List<_WilayaOption> filtered = _wilayas.where((_WilayaOption w) {
              if (query.trim().isEmpty) {
                return true;
              }
              final String q = query.trim().toLowerCase();
              return w.code.toString().contains(q) ||
                  w.nameFr.toLowerCase().contains(q) ||
                  w.nameAr.contains(query.trim());
            }).toList();

            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.72,
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                    child: Text(
                      'Choisir votre Wilaya',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      autofocus: false,
                      decoration: InputDecoration(
                        hintText: 'Rechercher wilaya (ex: 16, Alger, وهران)...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        isDense: true,
                        filled: true,
                        fillColor: Utils.isLightMode(context)
                            ? const Color(0xFFFAF7F2)
                            : PsColors.achromatic700,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (String v) {
                        setModalState(() {
                          query = v;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (BuildContext context, int index) {
                        final _WilayaOption w = filtered[index];
                        final bool isSelected = w.code == _selectedWilayaCode;
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 15,
                            backgroundColor: isSelected
                                ? PsColors.burgundy
                                : PsColors.burgundy.withValues(alpha: 0.1),
                            child: Text(
                              w.code.toString().padLeft(2, '0'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : PsColors.burgundy,
                              ),
                            ),
                          ),
                          title: Text(
                            w.nameFr,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          subtitle: w.nameAr.isNotEmpty ? Text(w.nameAr) : null,
                          trailing: isSelected
                              ? const Icon(Icons.check_circle,
                                  color: PsColors.burgundy, size: 20)
                              : null,
                          onTap: () => Navigator.of(ctx).pop(w),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (selected != null && selected.code != _selectedWilayaCode) {
      await _onWilayaSelected(selected.code);
    }
  }

  Future<void> _showCommunePickerSheet() async {
    if (_communes.isEmpty) {
      if (!_isLoadingCommunes) {
        await _fetchCommunes(_selectedWilayaCode);
      }
      if (_communes.isEmpty) {
        return;
      }
    }
    String query = '';
    final _CommuneOption? selected = await showModalBottomSheet<_CommuneOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Utils.isLightMode(context) ? Colors.white : PsColors.achromatic800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final List<_CommuneOption> filtered =
                _communes.where((_CommuneOption c) {
              if (query.trim().isEmpty) {
                return true;
              }
              final String q = query.trim().toLowerCase();
              return c.nameFr.toLowerCase().contains(q) ||
                  c.nameAr.contains(query.trim());
            }).toList();

            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.68,
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                    child: Text(
                      'Commune — $_selectedWilayaNameFr',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      autofocus: false,
                      decoration: InputDecoration(
                        hintText: 'Rechercher votre commune...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        isDense: true,
                        filled: true,
                        fillColor: Utils.isLightMode(context)
                            ? const Color(0xFFFAF7F2)
                            : PsColors.achromatic700,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (String v) {
                        setModalState(() {
                          query = v;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (BuildContext context, int index) {
                        final _CommuneOption c = filtered[index];
                        final bool isSelected =
                            c.nameFr == _selectedCommuneName;
                        return ListTile(
                          dense: true,
                          title: Text(
                            c.nameFr,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          subtitle: c.nameAr.isNotEmpty ? Text(c.nameAr) : null,
                          trailing: isSelected
                              ? const Icon(Icons.check_circle,
                                  color: PsColors.burgundy, size: 20)
                              : null,
                          onTap: () => Navigator.of(ctx).pop(c),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (selected != null && selected.nameFr != _selectedCommuneName) {
      setState(() {
        _selectedCommuneName = selected.nameFr;
        _selectedCommuneNameAr = selected.nameAr;
      });

      await Future.wait(<Future<void>>[
        _fetchStopDesks(_selectedWilayaCode,
            communeId: selected.id, communeName: selected.nameFr),
        _fetchYalidineQuote(),
      ]);
    }
  }

  Future<void> _showStopDeskPickerSheet() async {
    if (_stopDesks.isEmpty) {
      if (!_isLoadingStopDesks) {
        await _fetchStopDesks(_selectedWilayaCode);
      }
      if (_stopDesks.isEmpty) {
        return;
      }
    }

    String query = '';
    final _StopDeskOption? selected =
        await showModalBottomSheet<_StopDeskOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Utils.isLightMode(context) ? Colors.white : PsColors.achromatic800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final String q = query.trim().toLowerCase();
            final String cleanSelectedCommune =
                _selectedCommuneName.trim().toLowerCase();

            // Filter by search query
            final List<_StopDeskOption> filtered =
                _stopDesks.where((_StopDeskOption d) {
              if (q.isEmpty) {
                return true;
              }
              return d.name.toLowerCase().contains(q) ||
                  d.communeName.toLowerCase().contains(q) ||
                  d.address.toLowerCase().contains(q);
            }).toList();

            // Sort: bureaus matching selected commune come first, keeping all selectable
            filtered.sort((_StopDeskOption a, _StopDeskOption b) {
              final bool aMatch = cleanSelectedCommune.isNotEmpty &&
                  (a.communeName.toLowerCase() == cleanSelectedCommune ||
                      a.communeName.toLowerCase().contains(cleanSelectedCommune) ||
                      cleanSelectedCommune.contains(a.communeName.toLowerCase()) ||
                      a.name.toLowerCase().contains(cleanSelectedCommune));
              final bool bMatch = cleanSelectedCommune.isNotEmpty &&
                  (b.communeName.toLowerCase() == cleanSelectedCommune ||
                      b.communeName.toLowerCase().contains(cleanSelectedCommune) ||
                      cleanSelectedCommune.contains(b.communeName.toLowerCase()) ||
                      b.name.toLowerCase().contains(cleanSelectedCommune));

              if (aMatch && !bMatch) {
                return -1;
              }
              if (!aMatch && bMatch) {
                return 1;
              }
              return a.name.compareTo(b.name);
            });

            final bool isLight = Utils.isLightMode(context);

            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.78,
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Bureaux Yalidine — ${_cleanWilayaName(_selectedWilayaNameFr)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_stopDesks.length} bureaux disponibles dans la wilaya',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded, size: 22),
                          color: PsColors.burgundy,
                          tooltip: 'Actualiser en direct',
                          onPressed: () async {
                            setModalState(() {
                              _isLoadingStopDesks = true;
                            });
                            await _fetchStopDesks(_selectedWilayaCode,
                                refresh: true);
                            if (ctx.mounted) {
                              setModalState(() {});
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextField(
                      autofocus: false,
                      decoration: InputDecoration(
                        hintText:
                            'Rechercher par bureau, commune ou adresse...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        isDense: true,
                        filled: true,
                        fillColor: isLight
                            ? const Color(0xFFFAF7F2)
                            : PsColors.achromatic700,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (String v) {
                        setModalState(() {
                          query = v;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Icon(Icons.location_off_outlined,
                                      size: 40, color: Colors.grey.shade400),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Aucun bureau trouvé pour "$query"',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const Divider(
                                height: 1, indent: 16, endIndent: 16),
                            itemBuilder: (BuildContext context, int index) {
                              final _StopDeskOption desk = filtered[index];
                              final bool isSelected =
                                  desk.id == _selectedStopDeskId;
                              final bool isCommuneMatch =
                                  cleanSelectedCommune.isNotEmpty &&
                                      (desk.communeName.toLowerCase() ==
                                              cleanSelectedCommune ||
                                          desk.communeName
                                              .toLowerCase()
                                              .contains(cleanSelectedCommune) ||
                                          cleanSelectedCommune.contains(
                                              desk.communeName.toLowerCase()) ||
                                          desk.name
                                              .toLowerCase()
                                              .contains(cleanSelectedCommune));

                              return InkWell(
                                onTap: () => Navigator.of(ctx).pop(desk),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  color: isSelected
                                      ? PsColors.burgundy
                                          .withValues(alpha: 0.06)
                                      : null,
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Container(
                                        margin: const EdgeInsets.only(top: 2),
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? PsColors.burgundy
                                              : (isLight
                                                  ? const Color(0xFFF0EBE1)
                                                  : PsColors.achromatic700),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.storefront_rounded,
                                          size: 18,
                                          color: isSelected
                                              ? Colors.white
                                              : (isLight
                                                  ? PsColors.burgundy
                                                  : Colors.white70),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Row(
                                              children: <Widget>[
                                                Expanded(
                                                  child: Text(
                                                    desk.name,
                                                    style: TextStyle(
                                                      fontWeight: isSelected
                                                          ? FontWeight.w700
                                                          : FontWeight.w600,
                                                      fontSize: 14,
                                                      color: isSelected
                                                          ? PsColors.burgundy
                                                          : null,
                                                    ),
                                                  ),
                                                ),
                                                if (isCommuneMatch) ...<Widget>[
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                          0xFFE8F5E9),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                    ),
                                                    child: Text(
                                                      'Proche de $_selectedCommuneName',
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color:
                                                            Color(0xFF2E7D32),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 3),
                                            Row(
                                              children: <Widget>[
                                                const Icon(
                                                    Icons.location_on_outlined,
                                                    size: 13,
                                                    color: Colors.grey),
                                                const SizedBox(width: 3),
                                                Expanded(
                                                  child: Text(
                                                    desk.address.isNotEmpty
                                                        ? '${desk.communeName} — ${desk.address}'
                                                        : desk.communeName,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (isSelected)
                                        const Padding(
                                          padding: EdgeInsets.only(top: 6),
                                          child: Icon(
                                            Icons.check_circle_rounded,
                                            color: PsColors.burgundy,
                                            size: 20,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (selected != null && selected.id != _selectedStopDeskId) {
      setState(() {
        _selectedStopDeskId = selected.id;
        _selectedStopDeskName = selected.name;
        _selectedStopDeskCommune = selected.communeName;
        _selectedStopDeskAddress = selected.address;
      });
    }
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final bool isLight = Utils.isLightMode(context);
    return Container(
      margin: const EdgeInsets.only(bottom: PsDimens.space14),
      padding: const EdgeInsets.all(PsDimens.space14),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : PsColors.achromatic800,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLight
              ? const Color(0xFFEAE2D8)
              : PsColors.achromatic700,
          width: 1.0,
        ),
        boxShadow: isLight
            ? <BoxShadow>[
                const BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, color: PsColors.burgundy, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15.5,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildRecipientSection() {
    final bool isLight = Utils.isLightMode(context);
    final Color fieldFill =
        isLight ? const Color(0xFFFAF7F2) : PsColors.achromatic700;

    return _buildSectionCard(
      title: 'Destinataire',
      icon: Icons.person_outline_rounded,
      child: Column(
        children: <Widget>[
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Nom complet *',
              hintText: 'Ex: Amine Benali',
              prefixIcon: const Icon(Icons.badge_outlined, size: 20),
              isDense: true,
              filled: true,
              fillColor: fieldFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: PsColors.burgundy, width: 1.2),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Téléphone *',
              hintText: '05 / 06 / 07 XX XX XX XX',
              prefixIcon: const Icon(Icons.phone_outlined, size: 20),
              isDense: true,
              filled: true,
              fillColor: fieldFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: PsColors.burgundy, width: 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    final bool isLight = Utils.isLightMode(context);
    final Color fieldFill =
        isLight ? const Color(0xFFFAF7F2) : PsColors.achromatic700;

    final String cleanWilayaFr = _cleanWilayaName(_selectedWilayaNameFr);
    final String wilayaDisplay =
        '${_selectedWilayaCode.toString().padLeft(2, '0')} - $cleanWilayaFr'
        '${_selectedWilayaNameAr.isNotEmpty ? ' ($_selectedWilayaNameAr)' : ''}';

    final String communeDisplay = _selectedCommuneName.isNotEmpty
        ? '$_selectedCommuneName${_selectedCommuneNameAr.isNotEmpty ? ' ($_selectedCommuneNameAr)' : ''}'
        : (_isLoadingCommunes
            ? 'Chargement des communes...'
            : 'Sélectionner une commune');

    return _buildSectionCard(
      title: 'Destination (Wilaya & Commune)',
      icon: Icons.location_on_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Wilaya *',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: _showWilayaPickerSheet,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
              decoration: BoxDecoration(
                color: fieldFill,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: PsColors.burgundy.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.map_outlined,
                      size: 18, color: PsColors.burgundy),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      wilayaDisplay,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_isLoadingWilayas)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 22),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Commune / Région *',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: _isLoadingCommunes ? null : _showCommunePickerSheet,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
              decoration: BoxDecoration(
                color: fieldFill,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: PsColors.burgundy.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.location_city_outlined,
                      size: 18, color: PsColors.burgundy),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      communeDisplay,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: _selectedCommuneName.isNotEmpty
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: _selectedCommuneName.isNotEmpty
                            ? null
                            : Colors.grey,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_isLoadingCommunes)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 22),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYalidineDeliveryCards() {
    final bool isLight = Utils.isLightMode(context);

    return _buildSectionCard(
      title: 'Livraison Yalidine',
      icon: Icons.local_shipping_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (_isLoadingQuote)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          if (!_isLoadingQuote && !_hasLiveQuote && _quoteError != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.error_outline, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _quoteError!,
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ),
                  TextButton(
                    onPressed: _fetchYalidineQuote,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),

          // Route display: Expédié depuis : [Item Wilaya] → [Buyer Wilaya]
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isLight ? Colors.white : PsColors.achromatic800,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isLight
                    ? const Color(0xFFE5E7EB)
                    : PsColors.achromatic600,
              ),
            ),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.local_shipping_outlined,
                  size: 16,
                  color: PsColors.burgundy,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Expédié depuis : $_fromWilayaName → $_selectedWilayaNameFr',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isLight ? PsColors.text800 : PsColors.achromatic50,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Option 1: Yalidine Stop-Desk (Bureau Yalidine)
          InkWell(
            onTap: () {
              setState(() {
                _isStopDesk = true;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isStopDesk
                    ? PsColors.burgundy.withValues(alpha: 0.07)
                    : (isLight
                        ? const Color(0xFFFAF7F2)
                        : PsColors.achromatic700),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isStopDesk
                      ? PsColors.burgundy
                      : Colors.grey.withValues(alpha: 0.3),
                  width: _isStopDesk ? 1.8 : 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(
                        _isStopDesk
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: _isStopDesk ? PsColors.burgundy : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              'Yalidine Stop-Desk (Bureau Yalidine)',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Retrait au bureau Yalidine • ~$_estimatedDays jour(s)',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: PsColors.burgundy,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _hasLiveQuote
                              ? '${_stopDeskFeeDzd.toStringAsFixed(0)} DA'
                              : '...',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_isStopDesk) ...<Widget>[
                    const SizedBox(height: 10),
                    if (_isLoadingStopDesks && _stopDesks.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: isLight ? Colors.white : PsColors.achromatic800,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: PsColors.burgundy.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Row(
                          children: <Widget>[
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: PsColors.burgundy,
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Recherche des bureaux Yalidine en direct...',
                                style: TextStyle(fontSize: 12.5),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (_stopDesks.isEmpty) ...<Widget>[
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.amber.shade700.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Icon(Icons.info_outline,
                                    size: 18, color: Colors.amber.shade800),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _stopDeskError != null && _stopDeskError!.isNotEmpty
                                        ? 'Yalidine: $_stopDeskError'
                                        : 'Aucun bureau Yalidine disponible actuellement pour cette wilaya.',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: PsColors.burgundy,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            InkWell(
                              onTap: () {
                                _fetchStopDesks(_selectedWilayaCode,
                                    communeName: _selectedCommuneName,
                                    refresh: true);
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: PsColors.burgundy.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: PsColors.burgundy.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Icon(Icons.refresh,
                                        size: 14, color: PsColors.burgundy),
                                    SizedBox(width: 5),
                                    Text(
                                      'Actualiser',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: PsColors.burgundy,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...<Widget>[
                      if (_communeStopDesks.isNotEmpty) ...<Widget>[
                        Padding(
                          padding: const EdgeInsets.only(top: 2, bottom: 6),
                          child: Row(
                            children: <Widget>[
                              const Icon(Icons.storefront_rounded,
                                  size: 15, color: PsColors.burgundy),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  _selectedCommuneName.isNotEmpty
                                      ? 'Bureaux à $_selectedCommuneName (${_communeStopDesks.length}) :'
                                      : 'Bureaux disponibles :',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: isLight
                                        ? PsColors.achromatic800
                                        : Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ..._communeStopDesks.map((_StopDeskOption desk) {
                          final bool isSelected =
                              desk.id == _selectedStopDeskId;
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedStopDeskId = desk.id;
                                _selectedStopDeskName = desk.name;
                                _selectedStopDeskCommune = desk.communeName;
                                _selectedStopDeskAddress = desk.address;
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 7),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 9),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? PsColors.burgundy.withValues(alpha: 0.08)
                                    : (isLight
                                        ? Colors.white
                                        : PsColors.achromatic800),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? PsColors.burgundy
                                      : Colors.grey.withValues(alpha: 0.35),
                                  width: isSelected ? 1.6 : 1.0,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Icon(
                                      isSelected
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_off,
                                      size: 18,
                                      color: isSelected
                                          ? PsColors.burgundy
                                          : Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          desk.name,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w600,
                                            color: isSelected
                                                ? PsColors.burgundy
                                                : null,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (desk.address.isNotEmpty) ...<Widget>[
                                          const SizedBox(height: 2),
                                          Text(
                                            desk.address,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: Colors.grey.shade600,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        if (_selectedStopDeskId != null &&
                            _selectedStopDeskId!.isNotEmpty &&
                            !_communeStopDesks.any((_StopDeskOption d) =>
                                d.id == _selectedStopDeskId)) ...<Widget>[
                          Container(
                            margin: const EdgeInsets.only(bottom: 7),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 9),
                            decoration: BoxDecoration(
                              color: PsColors.burgundy.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: PsColors.burgundy,
                                width: 1.6,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(
                                    Icons.radio_button_checked,
                                    size: 18,
                                    color: PsColors.burgundy,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        _selectedStopDeskName,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: PsColors.burgundy,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (_selectedStopDeskAddress.isNotEmpty ||
                                          _selectedStopDeskCommune
                                              .isNotEmpty) ...<Widget>[
                                        const SizedBox(height: 2),
                                        Text(
                                          _selectedStopDeskAddress.isNotEmpty
                                              ? '$_selectedStopDeskCommune — $_selectedStopDeskAddress'
                                              : _selectedStopDeskCommune,
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: Colors.grey.shade600,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ] else ...<Widget>[
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.amber.shade700
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Icon(Icons.info_outline,
                                  size: 16, color: Colors.amber.shade800),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _fallbackToWilaya && _selectedCommuneName.isNotEmpty
                                      ? 'Aucun bureau direct à $_selectedCommuneName. Choisissez un bureau dans la wilaya :'
                                      : (_selectedCommuneName.isNotEmpty
                                          ? 'Bureaux disponibles dans la wilaya pour $_selectedCommuneName :'
                                          : 'Sélectionnez votre bureau de retrait :'),
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.amber.shade900,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_selectedStopDeskName.isNotEmpty) ...<Widget>[
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 9),
                            decoration: BoxDecoration(
                              color:
                                  PsColors.burgundy.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: PsColors.burgundy,
                                width: 1.6,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(
                                    Icons.radio_button_checked,
                                    size: 18,
                                    color: PsColors.burgundy,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        _selectedStopDeskName,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: PsColors.burgundy,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (_selectedStopDeskAddress.isNotEmpty ||
                                          _selectedStopDeskCommune
                                              .isNotEmpty) ...<Widget>[
                                        const SizedBox(height: 2),
                                        Text(
                                          _selectedStopDeskAddress.isNotEmpty
                                              ? '$_selectedStopDeskCommune — $_selectedStopDeskAddress'
                                              : _selectedStopDeskCommune,
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: Colors.grey.shade600,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                      InkWell(
                        onTap: _showStopDeskPickerSheet,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: PsColors.burgundy.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: PsColors.burgundy.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              const Icon(Icons.storefront_outlined,
                                  size: 16, color: PsColors.burgundy),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  _allWilayaStopDesks.isNotEmpty
                                      ? 'Voir tous les bureaux de la wilaya (${_allWilayaStopDesks.length})'
                                      : 'Voir tous les bureaux de la wilaya',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: PsColors.burgundy,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right_rounded,
                                  size: 16, color: PsColors.burgundy),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Option 2: Yalidine Livraison à Domicile
          InkWell(
            onTap: () {
              setState(() {
                _isStopDesk = false;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: !_isStopDesk
                    ? PsColors.burgundy.withValues(alpha: 0.07)
                    : (isLight
                        ? const Color(0xFFFAF7F2)
                        : PsColors.achromatic700),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: !_isStopDesk
                      ? PsColors.burgundy
                      : Colors.grey.withValues(alpha: 0.3),
                  width: !_isStopDesk ? 1.8 : 1.0,
                ),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    !_isStopDesk
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: !_isStopDesk ? PsColors.burgundy : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Yalidine Livraison à Domicile',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _selectedCommuneName.isNotEmpty
                              ? 'Livraison à $_selectedCommuneName • ~$_estimatedDays jour(s)'
                              : 'Livraison directe • ~$_estimatedDays jour(s)',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: !_isStopDesk
                          ? PsColors.burgundy
                          : Colors.grey.shade700,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _hasLiveQuote
                          ? '${_homeFeeDzd.toStringAsFixed(0)} DA'
                          : '...',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    orderIdRepository = Provider.of<OrderIdRepository>(context);
    vendorPaypalTokenRepository =
        Provider.of<VendorPaypalTokenRepository>(context);
    vendorItemBoughtRepository =
        Provider.of<VendorItemBoughtRepository>(context);
    productRepository = Provider.of<ProductRepository>(context);
    vendorUserDetailRepository = Provider.of<VendorUserRepository>(context);
    vendorInfoRepository = Provider.of<VendorInfoRepository>(context);
    userRepository = Provider.of<UserRepository>(context);

    psValueHolder = Provider.of<PsValueHolder>(context, listen: false);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? dynamic) async {
        if (didPop) {
          return;
        }
        Navigator.pop(context, '1');
      },
      child: Scaffold(
          appBar: AppBar(
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarIconBrightness: Utils.getBrightnessForAppBar(context),
            ),
            title: Text('check_out'.tr,
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    color: Utils.isLightMode(context)
                        ? PsColors.achromatic900
                        : PsColors.achromatic50,
                    fontWeight: FontWeight.w500,
                    fontSize: PsDimens.space18)),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context, '1');
              },
            ),
          ),
          body: MultiProvider(
              providers: <SingleChildWidget>[
                ChangeNotifierProvider<UserProvider?>(
                    lazy: false,
                    create: (BuildContext context) {
                      userProvider = UserProvider(
                          repo: userRepository, psValueHolder: psValueHolder);
                      if (psValueHolder?.loginUserId != null &&
                          psValueHolder!.loginUserId!.isNotEmpty) {
                        userProvider?.getUser(psValueHolder?.loginUserId,
                            psValueHolder?.languageCode ?? 'en');
                      }
                      return userProvider;
                    }),
                ChangeNotifierProvider<DefaultBillingAndShippingProvider?>(
                    lazy: false,
                    create: (BuildContext context) {
                      defaultBillingAndShippingProvider =
                          DefaultBillingAndShippingProvider(context: context);

                      defaultBillingAndShippingProvider?.loadData(
                          requestPathHolder: RequestPathHolder(
                              loginUserId:
                                  Utils.checkUserLoginId(psValueHolder),
                              languageCode: psValueHolder?.languageCode));
                      return defaultBillingAndShippingProvider;
                    }),
                ChangeNotifierProvider<GetOrderIdProvider?>(
                    lazy: false,
                    create: (BuildContext context) {
                      getOrderIdProvider =
                          GetOrderIdProvider(repo: orderIdRepository);
                      return getOrderIdProvider;
                    }),
                ChangeNotifierProvider<VendorPayPalTokenProvider?>(
                    lazy: false,
                    create: (BuildContext context) {
                      vendorPayPalTokenProvider = VendorPayPalTokenProvider(
                          repo: vendorPaypalTokenRepository);
                      return vendorPayPalTokenProvider;
                    }),
                ChangeNotifierProvider<VendorItemBoughtProvider?>(
                    lazy: false,
                    create: (BuildContext context) {
                      vendorItemBoughtProvider = VendorItemBoughtProvider(
                          vendorItemBoughtRepository:
                              vendorItemBoughtRepository);

                      return vendorItemBoughtProvider;
                    }),
                ChangeNotifierProvider<ItemDetailProvider?>(
                    lazy: false,
                    create: (BuildContext context) {
                      itemDetailProvider = ItemDetailProvider(
                          repo: productRepository,
                          psValueHolder: psValueHolder);
                      itemDetailProvider?.loadData(
                          requestPathHolder: RequestPathHolder(
                              loginUserId: psValueHolder?.loginUserId,
                              itemId: widget.checkoutItemList[0].itemId ?? '0',
                              languageCode: psValueHolder?.languageCode));

                      return itemDetailProvider;
                    }),
                ChangeNotifierProvider<VendorInfoProvider?>(
                    lazy: false,
                    create: (BuildContext context) {
                      vendorInfoProvider = VendorInfoProvider(
                        repo: vendorInfoRepository,
                      );

                      vendorInfoProvider?.loadData(
                          requestPathHolder: RequestPathHolder(
                              loginUserId:
                                  Utils.checkUserLoginId(psValueHolder),
                              vendorId: widget.vendorId,
                              headerToken: psValueHolder?.headerToken));
                      return vendorInfoProvider;
                    }),
                ChangeNotifierProvider<AddToCartProvider>(
                    lazy: false,
                    create: (BuildContext context) {
                      addToCartProvider = AddToCartProvider(context: context);

                      addToCartProvider.loadData(
                          dataConfig: DataConfiguration(
                              dataSourceType: DataSourceType.SERVER_DIRECT),
                          requestPathHolder: RequestPathHolder(
                              isCheckoutPage: PsConst.ONE,
                              loginUserId: psValueHolder?.loginUserId,
                              languageCode: psValueHolder?.languageCode));
                      addToCartProvider.addSingleItemCheckoutItem(
                          widget.checkoutItemList[0]);
                      return addToCartProvider;
                    }),
                ChangeNotifierProvider<VendorUserDetailProvider>(
                    lazy: false,
                    create: (BuildContext context) {
                      vendorUserDetailProvider = VendorUserDetailProvider(
                          repo: vendorUserDetailRepository,
                          psValueHolder: psValueHolder);
                      vendorUserDetailProvider!.loadData(
                          requestPathHolder: RequestPathHolder(
                        loginUserId: Utils.checkUserLoginId(psValueHolder),
                        vendorId: widget.vendorId,
                        ownerUserId: Utils.checkUserLoginId(psValueHolder),
                      ));
                      return vendorUserDetailProvider!;
                    }),
              ],
              child: Consumer6<
                      AddToCartProvider,
                      GetOrderIdProvider,
                      VendorInfoProvider,
                      VendorPayPalTokenProvider,
                      DefaultBillingAndShippingProvider,
                      UserProvider>(
                  builder: (BuildContext context,
                      AddToCartProvider addToCartProvider,
                      GetOrderIdProvider getOrderIdProvider,
                      VendorInfoProvider vendorInfoProvider,
                      VendorPayPalTokenProvider vendorPayPalTokenProvider,
                      DefaultBillingAndShippingProvider
                          defaultBillingAndShippingProvider,
                      UserProvider uProvider,
                      Widget? child) {
                _tryPrefillRecipientFromProfile(
                    uProvider, defaultBillingAndShippingProvider);

                final List<ShoppingCartItem> availableShoppingCartList =
                    <ShoppingCartItem>[];
                final List<ShoppingCartItem> soldOutShoppingCartList =
                    <ShoppingCartItem>[];
                final String basketItemCurrencySymbol =
                    addToCartProvider.shoppingCart.data?.vendorCurrencySymbol ??
                        'DA';

                if (widget.isSingleItemCheckout) {
                  availableShoppingCartList
                      .add(addToCartProvider.singleItemCheckoutItem);
                } else {
                  final List<ShoppingCartItem> shoppingCartList =
                      addToCartProvider.shoppingCart.data?.items ??
                          <ShoppingCartItem>[];
                  for (final ShoppingCartItem item in shoppingCartList) {
                    if (item.isSoldOut == '0') {
                      availableShoppingCartList.add(item);
                    } else if (item.isSoldOut == '1') {
                      soldOutShoppingCartList.add(item);
                    }
                  }

                  addToCartProvider
                      .addAvaliavleShoppingCartList(availableShoppingCartList);
                  addToCartProvider
                      .addSoldOutShoppingCartList(soldOutShoppingCartList);
                }

                bool vendorExpOrSoldOut() {
                  return vendorUserDetailProvider
                              ?.vendorUserDetail.data?.expiredStatus ==
                          PsConst.EXPIRED_NOTI ||
                      (soldOutShoppingCartList.isNotEmpty &&
                          availableShoppingCartList.isEmpty);
                }

                // Live selected Yalidine fee (Stop-Desk vs Home)
                final double selectedYalidineFee =
                    _isStopDesk ? _stopDeskFeeDzd : _homeFeeDzd;
                final String effectiveDeliveryCharges =
                    selectedYalidineFee.toStringAsFixed(0);

                double? originalPrice;
                double? currentPrice;
                String? currency;
                String? subTotal;
                String? discountPrice;
                String? singleItemTotalPrice;
                String? currencySymbol;

                if (availableShoppingCartList.isNotEmpty) {
                  final ShoppingCartItem cart = availableShoppingCartList[0];
                  originalPrice =
                      double.tryParse(cart.originalPrice.toString()) ?? 0.0;
                  currentPrice =
                      double.tryParse(cart.salePrice.toString()) ?? 0.0;
                  final double qty =
                      double.tryParse(cart.quantity.toString()) ?? 1.0;
                  currency = cart.vendorCurrencySymbol ?? 'DA';
                  subTotal = (originalPrice * qty).toStringAsFixed(0);
                  discountPrice =
                      ((originalPrice - currentPrice) * qty).toStringAsFixed(0);
                  final double itemSub = currentPrice * qty;
                  final double afterCoupon =
                      (itemSub - _couponDiscountDzd - _affiliationDiscountDzd) >
                              0
                          ? (itemSub -
                              _couponDiscountDzd -
                              _affiliationDiscountDzd)
                          : 0.0;
                  singleItemTotalPrice =
                      (afterCoupon + selectedYalidineFee).toStringAsFixed(0);
                  currencySymbol = cart.vendorCurrencySymbol ?? 'DA';
                }

                final double basketSubtotal = double.tryParse(
                        addToCartProvider.shoppingCart.data?.subTotal ?? '0') ??
                    0.0;
                final double basketDiscount = double.tryParse(
                        addToCartProvider.shoppingCart.data?.totalDiscount ??
                            '0') ??
                    0.0;
                final double basketNet = (basketSubtotal -
                            basketDiscount -
                            _couponDiscountDzd -
                            _affiliationDiscountDzd) >
                        0
                    ? (basketSubtotal -
                        basketDiscount -
                        _couponDiscountDzd -
                        _affiliationDiscountDzd)
                    : 0.0;
                final String finalBasketTotalPrice =
                    (basketNet + selectedYalidineFee).toStringAsFixed(0);

                // For Stop-Desk orders, pass the desk's communeName; for Home, pass selected Commune
                final String effectiveCommuneName = (_isStopDesk &&
                        _selectedStopDeskCommune.isNotEmpty)
                    ? _selectedStopDeskCommune
                    : (_selectedCommuneName.isNotEmpty
                        ? _selectedCommuneName
                        : _selectedWilayaNameFr);

                final double grossTotal = vendorExpOrSoldOut()
                    ? 0.0
                    : widget.isSingleItemCheckout
                        ? (double.tryParse(singleItemTotalPrice ?? '0') ?? 0.0)
                        : (double.tryParse(finalBasketTotalPrice) ?? 0.0);

                final double walletAmountUsed =
                    (_useWallet && _walletBalance > 0)
                        ? (_walletBalance >= grossTotal
                            ? grossTotal
                            : _walletBalance)
                        : 0.0;

                final double remainingToPay = (grossTotal - walletAmountUsed) > 0
                    ? (grossTotal - walletAmountUsed)
                    : 0.0;

                final bool isWalletOnly = _useWallet &&
                    (_walletBalance >= grossTotal) &&
                    grossTotal > 0;

                return Stack(children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: PsDimens.space16),
                    child: ListView(
                      children: <Widget>[
                        const SizedBox(height: PsDimens.space12),

                        // 1. Recipient Full Name & Phone (pre-filled from user profile)
                        _buildRecipientSection(),

                        // 2. Wilaya & Commune Selectors (from DZBuild dzship)
                        _buildLocationSection(),

                        // 3. Yalidine Stop-Desk & Home Delivery Cards with exact DZD prices
                        _buildYalidineDeliveryCards(),

                        // 4. Payment Method
                        Text('check_out_payment_method'.tr,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                                    fontSize: 16, fontWeight: FontWeight.w700)),
                        if (!isWalletOnly)
                          CustomPaymentRoleWidget(
                              value: 5,
                              isSelected: vendorInfoProvider.selectedValue == 5,
                              groupValue: vendorInfoProvider.selectedValue,
                              onChanged: (int? a) {
                                if (a != null) {
                                  vendorInfoProvider.updateSelectedValue(a);
                                }
                              },
                              image: Image.asset(
                                  'assets/images/payment/cash_on_delivery.png'),
                              paymentName: 'vendor_cash_on_delivery'.tr)
                        else
                          Container(
                            margin: const EdgeInsets.only(top: PsDimens.space8),
                            padding: const EdgeInsets.all(PsDimens.space12),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.green.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: <Widget>[
                                Icon(Icons.check_circle,
                                    color: Colors.green[700], size: 22),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Paiement intégral via Solde Wallet (0 DZD à la livraison)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green[800],
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Coupon Code Card
                        const SizedBox(height: PsDimens.space12),
                        Container(
                          padding: const EdgeInsets.all(PsDimens.space12),
                          decoration: BoxDecoration(
                            color: Utils.isLightMode(context)
                                ? PsColors.achromatic50
                                : PsColors.achromatic800,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _couponIsValid
                                  ? Colors.green
                                  : (Utils.isLightMode(context)
                                      ? PsColors.achromatic200
                                      : PsColors.achromatic700),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'coupon__code_label'.tr,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: TextField(
                                      controller: _couponController,
                                      textCapitalization:
                                          TextCapitalization.characters,
                                      enabled: _appliedCouponCode == null,
                                      decoration: InputDecoration(
                                        hintText: 'coupon__enter_code'.tr,
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 10),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: _isValidatingCoupon
                                        ? null
                                        : (_appliedCouponCode != null
                                            ? _removeCoupon
                                            : () {
                                                final double sub = widget
                                                        .isSingleItemCheckout
                                                    ? ((currentPrice ?? 0.0) *
                                                        (availableShoppingCartList
                                                                .isNotEmpty
                                                            ? (double.tryParse(
                                                                    availableShoppingCartList[0]
                                                                        .quantity
                                                                        .toString()) ??
                                                                1.0)
                                                            : 1.0))
                                                    : (basketSubtotal -
                                                        basketDiscount);
                                                _applyCouponCode(sub);
                                              }),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          _appliedCouponCode != null
                                              ? Colors.grey.shade700
                                              : PsColors.primary500,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: _isValidatingCoupon
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(_appliedCouponCode != null
                                            ? 'coupon__remove'.tr
                                            : 'coupon__apply'.tr),
                                  ),
                                ],
                              ),
                              if (_couponMessage != null) ...<Widget>[
                                const SizedBox(height: 6),
                                Text(
                                  _couponIsValid
                                      ? '$_couponMessage (-${_couponDiscountDzd.toStringAsFixed(0)} DA)'
                                      : _couponMessage!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _couponIsValid
                                        ? Colors.green[700]
                                        : Colors.red[700],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Text(
                                'affiliation__code_label'.tr,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: TextField(
                                      controller: _affiliationController,
                                      textCapitalization:
                                          TextCapitalization.characters,
                                      enabled: _appliedAffiliationCode == null,
                                      decoration: InputDecoration(
                                        hintText: 'affiliation__enter_code'.tr,
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 10),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: _isValidatingAffiliation
                                        ? null
                                        : (_appliedAffiliationCode != null
                                            ? _removeAffiliation
                                            : () {
                                                final double sub = widget
                                                        .isSingleItemCheckout
                                                    ? ((currentPrice ?? 0.0) *
                                                        (availableShoppingCartList
                                                                .isNotEmpty
                                                            ? (double.tryParse(
                                                                    availableShoppingCartList[0]
                                                                        .quantity
                                                                        .toString()) ??
                                                                1.0)
                                                            : 1.0))
                                                    : (basketSubtotal -
                                                        basketDiscount);
                                                _applyAffiliationCode(
                                                    (sub - _couponDiscountDzd) >
                                                            0
                                                        ? (sub -
                                                            _couponDiscountDzd)
                                                        : 0.0);
                                              }),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          _appliedAffiliationCode != null
                                              ? Colors.grey.shade700
                                              : PsColors.primary500,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: _isValidatingAffiliation
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(_appliedAffiliationCode != null
                                            ? 'coupon__remove'.tr
                                            : 'coupon__apply'.tr),
                                  ),
                                ],
                              ),
                              if (_affiliationMessage != null) ...<Widget>[
                                const SizedBox(height: 6),
                                Text(
                                  _affiliationIsValid
                                      ? '$_affiliationMessage (-${_affiliationDiscountDzd.toStringAsFixed(0)} DA)'
                                      : _affiliationMessage!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _affiliationIsValid
                                        ? Colors.green[700]
                                        : Colors.red[700],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Wallet Balance Toggle Card
                        if (_walletBalance > 0) ...<Widget>[
                          const SizedBox(height: PsDimens.space12),
                          Container(
                            decoration: BoxDecoration(
                              color: _useWallet
                                  ? (Utils.isLightMode(context)
                                      ? PsColors.primary500.withOpacity(0.06)
                                      : PsColors.primary500.withOpacity(0.18))
                                  : (Utils.isLightMode(context)
                                      ? PsColors.achromatic50
                                      : PsColors.achromatic800),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _useWallet
                                    ? PsColors.primary500
                                    : (Utils.isLightMode(context)
                                        ? PsColors.achromatic200
                                        : PsColors.achromatic700),
                                width: _useWallet ? 1.5 : 1.0,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: PsDimens.space14,
                                vertical: PsDimens.space12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: PsColors.primary500
                                            .withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.account_balance_wallet_outlined,
                                        size: 22,
                                        color: PsColors.primary500,
                                      ),
                                    ),
                                    const SizedBox(width: PsDimens.space12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            'Utiliser mon solde Wallet',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall!
                                                .copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14),
                                          ),
                                          const SizedBox(height: 2),
                                          if (_isLoadingWallet)
                                            const SizedBox(
                                              width: 12,
                                              height: 12,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 1.5),
                                            )
                                          else
                                            Text(
                                              '${Utils.getPriceFormat(_walletBalance.toStringAsFixed(0), psValueHolder?.priceFormat ?? '#,##0')} DZD disponibles',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall!
                                                  .copyWith(
                                                      color: PsColors.primary500,
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 12),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Switch.adaptive(
                                      value: _useWallet,
                                      activeColor: PsColors.primary500,
                                      onChanged: (bool val) {
                                        setState(() {
                                          _useWallet = val;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                if (_useWallet) ...<Widget>[
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isWalletOnly
                                          ? Colors.green.withOpacity(0.1)
                                          : PsColors.primary500
                                              .withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: <Widget>[
                                        Icon(
                                          isWalletOnly
                                              ? Icons.check_circle_outline
                                              : Icons.info_outline,
                                          size: 16,
                                          color: isWalletOnly
                                              ? Colors.green[700]
                                              : PsColors.primary500,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            isWalletOnly
                                                ? 'Votre solde Wallet couvre 100% de la commande (0 DZD à payer).'
                                                : '${walletAmountUsed.toStringAsFixed(0)} DZD déduits du solde • Reste à payer : ${remainingToPay.toStringAsFixed(0)} DZD',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: isWalletOnly
                                                  ? Colors.green[800]
                                                  : (Utils.isLightMode(context)
                                                      ? PsColors.text800
                                                      : PsColors.text50),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: PsDimens.space16),

                        /// Available List View
                        if (availableShoppingCartList.isNotEmpty)
                          CustomCheckOutAvailableVerticalListView(
                            isVendorExpired: vendorUserDetailProvider
                                    ?.vendorUserDetail.data?.expiredStatus ??
                                0,
                            title: vendorUserDetailProvider
                                    ?.vendorUserDetail.data?.name ??
                                '',
                            availableItemList: availableShoppingCartList,
                            vendorId: widget.vendorId,
                            isSingleItemCheckout: widget.isSingleItemCheckout,
                          ),

                        /// Empty available shopping cart
                        if (availableShoppingCartList.isEmpty)
                          CustomEmptyAvaliableShoppingCartWidget(
                              isVendorExpired: vendorUserDetailProvider
                                  ?.vendorUserDetail.data?.expiredStatus,
                              vendorName: vendorUserDetailProvider
                                      ?.vendorUserDetail.data?.name ??
                                  ''),

                        /// Sold Out List View
                        if (soldOutShoppingCartList.isNotEmpty)
                          CustomCheckOutSoldOutVerticalListView(
                            isVendorExpired: vendorUserDetailProvider
                                    ?.vendorUserDetail.data?.expiredStatus ??
                                0,
                            soldOutItemList: soldOutShoppingCartList,
                            vendorId: widget.vendorId,
                            isSingleItemCheckout: widget.isSingleItemCheckout,
                          ),

                        OrderSummaryWidget(
                          currency: (widget.isSingleItemCheckout)
                              ? currency ?? 'DA'
                              : addToCartProvider.shoppingCart.data
                                      ?.vendorCurrencySymbol ??
                                  'DA',
                          deliveryCharges: vendorExpOrSoldOut()
                              ? '0'
                              : effectiveDeliveryCharges,
                          discount: vendorExpOrSoldOut()
                              ? '0'
                              : (widget.isSingleItemCheckout)
                                  ? discountPrice ?? '0'
                                  : addToCartProvider
                                          .shoppingCart.data?.totalDiscount ??
                                      '0',
                          subTotal: vendorExpOrSoldOut()
                              ? '0'
                              : (widget.isSingleItemCheckout)
                                  ? subTotal ?? '0'
                                  : addToCartProvider
                                          .shoppingCart.data?.subTotal ??
                                      '0',
                          walletAmountUsed: walletAmountUsed > 0
                              ? walletAmountUsed.toStringAsFixed(0)
                              : null,
                          couponDiscount: _couponDiscountDzd > 0
                              ? _couponDiscountDzd.toStringAsFixed(0)
                              : null,
                          couponCode: _appliedCouponCode,
                          affiliationDiscount: _affiliationDiscountDzd > 0
                              ? _affiliationDiscountDzd.toStringAsFixed(0)
                              : null,
                          affiliationCode: _appliedAffiliationCode,
                          totalPayable: remainingToPay.toStringAsFixed(0),
                        ),

                        const SizedBox(height: 92)
                      ],
                    ),
                  ),
                  CustomPlaceOrderButtonWidget(
                      titleTextColor: vendorExpOrSoldOut()
                          ? PsColors.achromatic400
                          : PsColors.achromatic50,
                      color: vendorExpOrSoldOut()
                          ? Utils.isLightMode(context)
                              ? PsColors.achromatic100
                              : PsColors.achromatic600
                          : PsColors.primary500,
                      vendorExpOrSoldOut: vendorExpOrSoldOut(),
                      shoppingCartList: availableShoppingCartList,
                      defaultShippingAndBilling: false,
                      isSingleItemCheckout: widget.isSingleItemCheckout,
                      totalPrice: vendorExpOrSoldOut()
                          ? '0'
                          : widget.isSingleItemCheckout
                              ? singleItemTotalPrice
                              : finalBasketTotalPrice,
                      currencySymbol: widget.isSingleItemCheckout
                          ? currencySymbol
                          : basketItemCurrencySymbol,
                      vendorId: widget.isSingleItemCheckout
                          ? (itemDetailProvider?.itemDetail.data?.vendorId ??
                              widget.vendorId)
                          : (addToCartProvider.shoppingCart.data?.vendorId ??
                              widget.vendorId),
                      vendorCurrencyShortForm: widget.isSingleItemCheckout
                          ? itemDetailProvider
                                  ?.product.itemCurrency?.currencyShortForm ??
                              'DZD'
                          : addToCartProvider
                                  .shoppingCart.data?.vendorCurrencyShortForm ??
                              'DZD',
                      deliveryType: _isStopDesk ? 'stopdesk' : 'home',
                      deliveryFee: effectiveDeliveryCharges,
                      toWilayaId: _selectedWilayaCode.toString(),
                      fromWilayaId: _fromWilayaCode.toString(),
                      toCommuneName: effectiveCommuneName,
                      toWilayaName: _selectedWilayaNameFr,
                      yalidineStopDeskId:
                          _isStopDesk ? _selectedStopDeskId : null,
                      stopDeskName: _isStopDesk ? _selectedStopDeskName : null,
                      recipientName: _nameController.text.trim(),
                      recipientPhone: _phoneController.text.trim(),
                      walletAmountUsed: walletAmountUsed > 0
                          ? walletAmountUsed.toStringAsFixed(0)
                          : '0',
                      isWalletOnly: isWalletOnly,
                      couponCode: _appliedCouponCode,
                      affiliationCode: _appliedAffiliationCode),
                ]);
              }))),
    );
  }
}
