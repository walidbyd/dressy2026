

import 'package:flutter/material.dart';

import '../../../core/vendor/utils/utils.dart';

class PsSquareProgressWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container( 
      width : 25, 
      height : 25,       
      child: LinearProgressIndicator(
        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFED7768)),
        backgroundColor: Utils.isLightMode(context) ? const Color(0xFFFDEEEB) : const Color(0x33ED7768)
      ),
    );
  }
}