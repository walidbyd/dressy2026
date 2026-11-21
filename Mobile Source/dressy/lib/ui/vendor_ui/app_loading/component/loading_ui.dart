import 'package:flutter/material.dart';
import '../../../../../../config/ps_colors.dart';
import '../../../../../../core/vendor/utils/utils.dart';

import '../../../../core/vendor/constant/ps_dimens.dart';
import '../../common/ps_square_progress_widget.dart';

class LoadingUi extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double maxLogoWidth = (screenWidth * 0.55).clamp(160.0, 240.0);
    final Widget _imageWidget = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxLogoWidth, maxHeight: 70),
      child: Image.asset(
        'assets/images/LOGO_DRESSY.png',
        fit: BoxFit.contain,
      ),
    );
    return Container(
        height: 400,
        color: Utils.isLightMode(context) ? PsColors.achromatic50 : PsColors.achromatic800,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _imageWidget,
                const SizedBox(
                  height: PsDimens.space24,
                ),
                Container(
                    padding: const EdgeInsets.all(PsDimens.space16),
                    child: PsSquareProgressWidget()),
              ],
            )
          ],
        ));
  }
}
