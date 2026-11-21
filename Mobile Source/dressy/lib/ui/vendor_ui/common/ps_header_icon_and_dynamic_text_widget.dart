import 'package:flutter/material.dart';
import '../../../../../../config/ps_colors.dart';
import '../../../../../../core/vendor/provider/language/app_localization_provider.dart';

import '../../../core/vendor/constant/ps_dimens.dart';
import '../../../core/vendor/utils/utils.dart';

class PsHeaderIconAndDynamicTextWidget extends StatelessWidget {
  const PsHeaderIconAndDynamicTextWidget({
    Key? key,
    required this.text,
  }) : super(key: key);
  final String? text;
  @override
  Widget build(BuildContext context) {
    final Widget _textWidget = Text(
      text ?? 'app_name'.tr,
      style: Theme.of(context).textTheme.titleLarge!.copyWith(
          color: Utils.isLightMode(context)
              ? PsColors.achromatic800 : PsColors.achromatic50,
          fontSize: 20,
          fontWeight: FontWeight.w600),
    );

    final Widget _imageWidget = ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 48, maxWidth: 180),
      child: Image.asset(
        'assets/images/LOGO_DRESSY.png',
        fit: BoxFit.contain,
      ),
    );
    return Center(
      child: Column(
        children: <Widget>[
          const SizedBox(
            height: PsDimens.space32,
          ),
          _imageWidget,
          const SizedBox(
            height: PsDimens.space16,
          ),
          _textWidget,
          const SizedBox(
            height: PsDimens.space16,
          ),
        ],
      ),
    );
  }
}
