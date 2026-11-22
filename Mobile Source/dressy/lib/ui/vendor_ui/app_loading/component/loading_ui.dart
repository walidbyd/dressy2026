import 'package:flutter/material.dart';
import '../../../../../../config/ps_colors.dart';
import '../../../../../../core/vendor/utils/utils.dart';

class LoadingUi extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double maxLogoWidth = (screenWidth * 0.55).clamp(160.0, 240.0);
    final bool isLight = Utils.isLightMode(context);
    final Widget _imageWidget = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxLogoWidth, maxHeight: 70),
      child: Image.asset(
        'assets/images/LOGO_DRESSY.png',
        fit: BoxFit.contain,
      ),
    );
    return Scaffold(
      backgroundColor: isLight ? PsColors.achromatic50 : PsColors.achromatic900,
      body: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            _imageWidget,
            const SizedBox(
              height: 32.0,
            ),
            SizedBox(
              width: 140,
              height: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFED7768)),
                  backgroundColor: isLight ? const Color(0xFFFDEEEB) : const Color(0x33ED7768),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
