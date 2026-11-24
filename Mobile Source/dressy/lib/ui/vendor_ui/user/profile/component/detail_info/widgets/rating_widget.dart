import 'package:flutter/material.dart';

import '../../../../../../../config/route/route_paths.dart';
import '../../../../../../../core/vendor/viewobject/user.dart';

class RatingWidget extends StatelessWidget {
  const RatingWidget({
    Key? key,
    required this.user,
    this.starCount,
  }) : super(key: key);

  final User? user;
  final int? starCount;
  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const SizedBox();
    }

    final String rawRating =
        (user!.overallRating != null && user!.overallRating!.isNotEmpty)
            ? user!.overallRating!
            : '0';
    final double ratingVal = double.tryParse(rawRating) ?? 0.0;
    final String formattedRating =
        ratingVal > 0 ? ratingVal.toStringAsFixed(1) : '5.0';

    String reviewCountStr = user!.ratingCount ?? '';
    if (reviewCountStr.isEmpty || reviewCountStr == '0') {
      reviewCountStr = user!.ratingDetail?.totalRatingCount ?? '0';
    }
    final int count = int.tryParse(reviewCountStr) ?? 0;

    return InkWell(
      onTap: () {
        if (user!.userId != null && user!.userId!.isNotEmpty) {
          Navigator.pushNamed(context, RoutePaths.ratingList,
              arguments: user!.userId);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(top: 6, bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFBF4F5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE4A4AB), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.star_rounded,
              size: 16,
              color: Color(0xFF5C1A2B),
            ),
            const SizedBox(width: 4),
            Text(
              formattedRating,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF5C1A2B),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              count > 0 ? '($count avis)' : '(Nouveau)',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6E6568),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
