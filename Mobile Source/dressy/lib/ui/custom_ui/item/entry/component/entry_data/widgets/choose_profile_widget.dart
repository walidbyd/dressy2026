import 'package:flutter/material.dart';

class CustomChooseProfileWidget extends StatelessWidget {
  const CustomChooseProfileWidget({Key? key, required this.flag})
      : super(key: key);

  final String flag;

  @override
  Widget build(BuildContext context) {
    // Dressy C2C: Auto-bind seller store, remove "Choose Account" prompt completely
    return const SizedBox.shrink();
  }
}
