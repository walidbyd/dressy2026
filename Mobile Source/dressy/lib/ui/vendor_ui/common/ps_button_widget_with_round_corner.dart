import 'package:flutter/material.dart';
import '../../../../../../config/ps_colors.dart';
import '../../../../../../core/vendor/provider/language/app_localization_provider.dart';

import '../../../core/vendor/constant/ps_dimens.dart';

class PSButtonWidgetRoundCorner extends StatefulWidget {
  const PSButtonWidgetRoundCorner(
      {this.onPressed,
      this.titleText = '',
      this.titleTextColor,
      this.titleTextAlign = TextAlign.center,
      this.colorData,
      this.width,
      this.height,
      this.gradient,
      this.hasBorder = false,
      this.hasShadow = false});

  final Function? onPressed;
  final String titleText;
  final Color? titleTextColor;
  final Color? colorData;
  final double? width;
  final double? height;
  final bool hasBorder;
  final Gradient? gradient;
  final bool hasShadow;
  final TextAlign titleTextAlign;

  @override
  _PSButtonWidgetRoundCornerState createState() =>
      _PSButtonWidgetRoundCornerState();
}

class _PSButtonWidgetRoundCornerState extends State<PSButtonWidgetRoundCorner> {
  Color? _color;
  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null;
    _color = widget.colorData;
    _color ??= PsColors.primary500;

    final Color effectiveColor =
        isDisabled ? const Color(0xFFE8DFE2) : _color!;
    Color effectiveTextColor;
    if (widget.titleTextColor != null) {
      effectiveTextColor = widget.titleTextColor!;
    } else if (isDisabled) {
      effectiveTextColor = const Color(0xFF6E6568);
    } else if (widget.hasBorder ||
        effectiveColor == Colors.white ||
        effectiveColor == Colors.transparent ||
        effectiveColor == const Color(0xFFFAF7F2)) {
      effectiveTextColor = const Color(0xFF5C1A2B);
    } else {
      effectiveTextColor = Colors.white;
    }

    return Container(
      width: widget.width,
      height: widget.height ?? 46,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(
          Radius.circular(4.0),
        ),
        color: effectiveColor,
      ),
      child: Material(
        color: effectiveColor,
        type: MaterialType.card,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
            side: widget.hasBorder
                ? const BorderSide(color: Color(0xFFD8C7CC), width: 1.0)
                : BorderSide.none,
            borderRadius:
                const BorderRadius.all(Radius.circular(PsDimens.space4))),
        child: InkWell(
          onTap: widget.onPressed as void Function()?,
          highlightColor: PsColors.primary900,
          child: Center(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: PsDimens.space8),
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  widget.titleText,
                  textAlign: widget.titleTextAlign,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: effectiveTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PSButtonWithIconWidget extends StatefulWidget {
  const PSButtonWithIconWidget(
      {this.onPressed,
      this.titleText = '',
      this.colorData,
      this.width,
      this.gradient,
      this.icon,
      this.iconAlignment = MainAxisAlignment.center,
      this.hasShadow = false,
      this.iconColor});

  final Function? onPressed;
  final String titleText;
  final Color? colorData;
  final double? width;
  final IconData? icon;
  final Gradient? gradient;
  final MainAxisAlignment iconAlignment;
  final bool hasShadow;
  final Color? iconColor;

  @override
  _PSButtonWithIconWidgetState createState() => _PSButtonWithIconWidgetState();
}

class _PSButtonWithIconWidgetState extends State<PSButtonWithIconWidget> {
  Color? _color;
  Color? _iconColor;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null;
    _color = widget.colorData ?? PsColors.primary500;
    final Color effectiveColor =
        isDisabled ? const Color(0xFFE8DFE2) : _color!;

    Color effectiveTextColor;
    if (isDisabled) {
      effectiveTextColor = const Color(0xFF6E6568);
    } else if (effectiveColor == Colors.white ||
        effectiveColor == Colors.transparent ||
        effectiveColor == const Color(0xFFFAF7F2)) {
      effectiveTextColor = const Color(0xFF5C1A2B);
    } else {
      effectiveTextColor = Colors.white;
    }

    _iconColor = widget.iconColor ?? effectiveTextColor;

    return Container(
      width: widget.width, //MediaQuery.of(context).size.width,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(
          Radius.circular(4.0),
        ),
        color: effectiveColor,
      ),
      child: Material(
        color: effectiveColor,
        type: MaterialType.card,
        clipBehavior: Clip.antiAlias,
        shape: const BeveledRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(PsDimens.space8))),
        child: InkWell(
          onTap: widget.onPressed as void Function()?,
          highlightColor: PsColors.primary900,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: widget.iconAlignment,
            children: <Widget>[
              if (widget.icon != null) Icon(widget.icon, color: _iconColor),
              if (widget.icon != null && widget.titleText != '')
                const SizedBox(
                  width: PsDimens.space12,
                ),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.titleText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          color: effectiveTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PSButtonWidgetWithIconRoundCorner extends StatefulWidget {
  const PSButtonWidgetWithIconRoundCorner(
      {this.onPressed,
      this.titleText = '',
      this.titleTextAlign = TextAlign.center,
      this.colorData,
      this.width,
      this.icon,
      this.gradient,
      this.iconColor,
      this.iconAlignment = MainAxisAlignment.center,
      this.hasShadow = false});

  final Function? onPressed;
  final String titleText;
  final Color? colorData;
  final double? width;
  final IconData? icon;
  final Gradient? gradient;
  final bool hasShadow;
  final TextAlign titleTextAlign;
  final MainAxisAlignment iconAlignment;
  final Color? iconColor;

  @override
  _PSButtonWidgetWithIconRoundCornerState createState() =>
      _PSButtonWidgetWithIconRoundCornerState();
}

class _PSButtonWidgetWithIconRoundCornerState
    extends State<PSButtonWidgetWithIconRoundCorner> {
  Color? _color;
  Color? _iconColor;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null;
    _color = widget.colorData ?? PsColors.primary500;
    final Color effectiveColor =
        isDisabled ? const Color(0xFFE8DFE2) : _color!;

    Color effectiveTextColor;
    if (isDisabled) {
      effectiveTextColor = const Color(0xFF6E6568);
    } else if (widget.titleText == 'edit_profile__title'.tr ||
        widget.titleText == 'Reset'.tr ||
        widget.titleText == 'map_filter__reset'.tr) {
      effectiveTextColor = Theme.of(context).primaryColor;
    } else if (effectiveColor == Colors.white ||
        effectiveColor == Colors.transparent ||
        effectiveColor == const Color(0xFFFAF7F2)) {
      effectiveTextColor = const Color(0xFF5C1A2B);
    } else {
      effectiveTextColor = Colors.white;
    }

    _iconColor = widget.iconColor ?? effectiveTextColor;

    return Container(
      width: MediaQuery.of(context).size.width,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(
          Radius.circular(4.0),
        ),
        color: effectiveColor,
      ),
      child: Material(
        color: effectiveColor,
        type: MaterialType.card,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
            side: BorderSide(
                color: effectiveColor == Colors.white ||
                        effectiveColor == Colors.transparent
                    ? const Color(0xFFD8C7CC)
                    : Colors.transparent),
            borderRadius:
                const BorderRadius.all(Radius.circular(PsDimens.space8))),
        child: InkWell(
          onTap: widget.onPressed as void Function()?,
          highlightColor: PsColors.primary900,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: widget.iconAlignment,
            children: <Widget>[
              if (widget.icon != null) Icon(widget.icon, color: _iconColor),
              if (widget.icon != null && widget.titleText != '')
                const SizedBox(
                  width: PsDimens.space4,
                ),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.titleText.toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: effectiveTextColor,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PSButtonWidgetWithIconRoundCorner2 extends StatefulWidget {
  const PSButtonWidgetWithIconRoundCorner2(
      {this.onPressed,
      this.titleText = '',
      this.titleTextAlign = TextAlign.center,
      this.colorData,
      this.width,
      this.icon,
      this.gradient,
      this.iconColor,
      this.iconAlignment = MainAxisAlignment.center,
      this.hasShadow = false});

  final Function? onPressed;
  final String titleText;
  final Color? colorData;
  final double? width;
  final IconData? icon;
  final Gradient? gradient;
  final bool hasShadow;
  final TextAlign titleTextAlign;
  final MainAxisAlignment iconAlignment;
  final Color? iconColor;

  @override
  _PSButtonWidgetWithIconRoundCorner2State createState() =>
      _PSButtonWidgetWithIconRoundCorner2State();
}

class _PSButtonWidgetWithIconRoundCorner2State
    extends State<PSButtonWidgetWithIconRoundCorner2> {
  Color? _color;
  Color? _iconColor;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null;
    _color = widget.colorData ?? Colors.white;
    final Color effectiveColor =
        isDisabled ? const Color(0xFFE8DFE2) : _color!;

    final Color effectiveTextColor = isDisabled
        ? const Color(0xFF6E6568)
        : (effectiveColor == Colors.white ||
                effectiveColor == const Color(0xFFFAF7F2) ||
                effectiveColor == Colors.transparent
            ? const Color(0xFF1E191B)
            : Colors.white);

    _iconColor = widget.iconColor ??
        (effectiveTextColor == Colors.white
            ? Colors.white
            : const Color(0xFF5C1A2B));

    return Container(
      width: MediaQuery.of(context).size.width,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFD8C7CC)),
        color: effectiveColor,
      ),
      child: Material(
        color: effectiveColor,
        type: MaterialType.card,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onPressed as void Function()?,
          highlightColor: PsColors.primary900,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.titleText.toUpperCase(),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: effectiveTextColor,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              if (widget.icon != null)
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Icon(widget.icon, color: _iconColor),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class PSButtonWidgetWithIconRoundCorner3 extends StatefulWidget {
  const PSButtonWidgetWithIconRoundCorner3(
      {this.onPressed,
      this.titleText = '',
      this.titleTextAlign = TextAlign.center,
      this.colorData,
      this.width,
      this.icon,
      this.gradient,
      this.iconColor,
      this.iconAlignment = MainAxisAlignment.center,
      this.hasShadow = false});

  final Function? onPressed;
  final String titleText;
  final Color? colorData;
  final double? width;
  final IconData? icon;
  final Gradient? gradient;
  final bool hasShadow;
  final TextAlign titleTextAlign;
  final MainAxisAlignment iconAlignment;
  final Color? iconColor;

  @override
  _PSButtonWidgetWithIconRoundCorner3State createState() =>
      _PSButtonWidgetWithIconRoundCorner3State();
}

class _PSButtonWidgetWithIconRoundCorner3State
    extends State<PSButtonWidgetWithIconRoundCorner3> {
  Color? _color;
  Color? _iconColor;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null;
    _color = widget.colorData ?? Colors.white;
    final Color effectiveColor =
        isDisabled ? const Color(0xFFE8DFE2) : _color!;

    final Color effectiveTextColor = isDisabled
        ? const Color(0xFF6E6568)
        : (effectiveColor == Colors.white ||
                effectiveColor == const Color(0xFFFAF7F2) ||
                effectiveColor == Colors.transparent
            ? const Color(0xFF1E191B)
            : Colors.white);

    _iconColor = widget.iconColor ??
        (effectiveTextColor == Colors.white
            ? Colors.white
            : const Color(0xFF5C1A2B));

    return Container(
      width: widget.width,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFD8C7CC)),
        color: effectiveColor,
      ),
      child: Material(
        color: effectiveColor,
        type: MaterialType.card,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onPressed as void Function()?,
          highlightColor: PsColors.primary900,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              if (widget.icon != null)
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Icon(widget.icon, color: _iconColor),
                ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.titleText.toUpperCase(),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: effectiveTextColor,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
