import 'package:flutter/material.dart';
import '../../../vendor_ui/language/view/choose_language_view.dart';

class CustomOnBoardLanguageContainerView extends StatelessWidget {
  const CustomOnBoardLanguageContainerView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const LanguageListView(fromBoard: true);
  }
}
