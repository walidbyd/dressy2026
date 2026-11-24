import 'package:flutter/material.dart';

import '../../../../config/ps_colors.dart';
import '../../../../core/vendor/constant/ps_constants.dart';
import '../../../../core/vendor/viewobject/default_icon.dart';
import 'ps_ui_widget.dart';

class CategoryIllustrationWidget extends StatelessWidget {
  const CategoryIllustrationWidget({
    Key? key,
    required this.name,
    this.defaultIcon,
    this.size = 44.0,
    this.iconSize = 22.0,
  }) : super(key: key);

  final String? name;
  final DefaultIcon? defaultIcon;
  final double size;
  final double iconSize;

  static IconData getIconForName(String? rawName) {
    if (rawName == null || rawName.isEmpty) {
      return Icons.checkroom;
    }
    final String n = rawName.toLowerCase();

    // Main Categories
    if (n.contains('women') || n.contains('femme') || n.contains('نساء') || n.contains('femmes')) {
      return Icons.woman;
    }
    if (n.contains('baby') || n.contains('bébé') || n.contains('bebe') || n.contains('طفل') || n.contains('أطفال')) {
      return Icons.child_care;
    }

    // Subcategories
    if (n.contains('dress') || n.contains('robe') || n.contains('فستان') || n.contains('فساتين')) {
      return Icons.dry_cleaning;
    }
    if (n.contains('top') || n.contains('t-shirt') || n.contains('haut') || n.contains('قميص') || n.contains('تيشرت')) {
      return Icons.checkroom;
    }
    if (n.contains('sweater') || n.contains('cardigan') || n.contains('pull') || n.contains('gilet') || n.contains('سترة')) {
      return Icons.style;
    }
    if (n.contains('coat') || n.contains('jacket') || n.contains('manteau') || n.contains('veste') || n.contains('معطف') || n.contains('جاكيت')) {
      return Icons.checkroom;
    }
    if (n.contains('jean') || n.contains('trouser') || n.contains('pantalon') || n.contains('بنطلون') || n.contains('جينز')) {
      return Icons.accessibility_new;
    }
    if (n.contains('skirt') || n.contains('short') || n.contains('jupe') || n.contains('تنورة') || n.contains('شورت')) {
      return Icons.sports_tennis;
    }
    if (n.contains('suit') || n.contains('blazer') || n.contains('costume') || n.contains('بدلة') || n.contains('بليزر')) {
      return Icons.business_center;
    }
    if (n.contains('active') || n.contains('lounge') || n.contains('sport') || n.contains('رياض')) {
      return Icons.fitness_center;
    }
    if (n.contains('swim') || n.contains('lingerie') || n.contains('maillot') || n.contains('سباحة') || n.contains('ملابس داخلية')) {
      return Icons.pool;
    }
    if (n.contains('traditional') || n.contains('occasion') || n.contains('tradition') || n.contains('تقليد') || n.contains('مناسب')) {
      return Icons.auto_awesome;
    }
    if (n.contains('shoe') || n.contains('chaussure') || n.contains('حذاء') || n.contains('أحذية') || n.contains('sock') || n.contains('chaussette')) {
      return Icons.hiking;
    }
    if (n.contains('bag') || n.contains('sac') || n.contains('حقيب') || n.contains('حقائب') || n.contains('backpack')) {
      return Icons.shopping_bag;
    }
    if (n.contains('accessoir') || n.contains('access') || n.contains('jewel') || n.contains('bijou') || n.contains('مجوهر') || n.contains('إكسسوار')) {
      return Icons.diamond;
    }
    if (n.contains('body') || n.contains('onesie') || n.contains('grenouillère')) {
      return Icons.child_care;
    }
    if (n.contains('outfit') || n.contains('ensemble') || n.contains('طقم')) {
      return Icons.style;
    }
    if (n.contains('sleep') || n.contains('pyjama') || n.contains('بيجامة')) {
      return Icons.bedtime;
    }
    if (n.contains('gear') || n.contains('stroller') || n.contains('poussette') || n.contains('عربة')) {
      return Icons.stroller;
    }
    if (n.contains('toy') || n.contains('jouet') || n.contains('لعبة') || n.contains('ألعاب')) {
      return Icons.toys;
    }

    return Icons.checkroom;
  }

  static Color getIconColor(String? rawName) {
    if (rawName == null || rawName.isEmpty) {
      return const Color(0xFFE91E63);
    }
    final String n = rawName.toLowerCase();
    if (n.contains('women') || n.contains('femme') || n.contains('نساء') || n.contains('dress') || n.contains('robe')) {
      return const Color(0xFFE91E63);
    }
    if (n.contains('baby') || n.contains('bébé') || n.contains('bebe') || n.contains('طفل') || n.contains('stroller')) {
      return const Color(0xFF00BCD4);
    }
    if (n.contains('shoe') || n.contains('chaussure') || n.contains('bag') || n.contains('sac')) {
      return const Color(0xFFFF9800);
    }
    if (n.contains('jewel') || n.contains('bijou') || n.contains('access')) {
      return const Color(0xFF9C27B0);
    }
    if (n.contains('jean') || n.contains('pantalon') || n.contains('suit')) {
      return const Color(0xFF3F51B5);
    }
    if (n.contains('sport') || n.contains('active') || n.contains('swim')) {
      return const Color(0xFF4CAF50);
    }
    return const Color(0xFFE91E63);
  }

  @override
  Widget build(BuildContext context) {
    if (defaultIcon != null &&
        defaultIcon!.imgPath != null &&
        defaultIcon!.imgPath!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          width: size,
          height: size,
          color: PsColors.primary50,
          padding: const EdgeInsets.all(6),
          child: PsNetworkIcon(
            imageAspectRation: PsConst.Aspect_Ratio_1x,
            photoKey: '',
            defaultIcon: defaultIcon,
            boxfit: BoxFit.cover,
          ),
        ),
      );
    }

    final IconData iconData = getIconForName(name);
    final Color iconColor = getIconColor(name);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: iconColor.withValues(alpha: 0.25), width: 1.0),
      ),
      alignment: Alignment.center,
      child: Icon(
        iconData,
        size: iconSize,
        color: iconColor,
      ),
    );
  }
}
