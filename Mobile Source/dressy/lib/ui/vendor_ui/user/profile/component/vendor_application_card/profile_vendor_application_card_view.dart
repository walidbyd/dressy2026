import 'package:flutter/material.dart';

class ProfileVendorApplicationCard extends StatelessWidget {
  const ProfileVendorApplicationCard(
      {Key? key, required this.animationController})
      : super(key: key);

  final AnimationController? animationController;

  @override
  Widget build(BuildContext context) {
    return const SliverToBoxAdapter(child: SizedBox());
  }
}
