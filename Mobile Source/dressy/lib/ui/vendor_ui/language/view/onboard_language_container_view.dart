import 'package:flutter/material.dart';
import 'choose_language_view.dart';

class OnBoardLanguageContainerView extends StatelessWidget {
  const OnBoardLanguageContainerView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const LanguageListView(fromBoard: true);
  }
}
