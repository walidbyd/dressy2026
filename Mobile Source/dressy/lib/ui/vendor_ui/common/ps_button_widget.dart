import 'package:flutter/material.dart';
import '../../../../../../config/ps_colors.dart';

import '../../../core/vendor/constant/ps_dimens.dart';
import '../../../core/vendor/utils/utils.dart';

class PSButtonWidget extends StatefulWidget {
  const PSButtonWidget(
      {this.onPressed,
      this.titleText = '',
      this.titleTextAlign = TextAlign.center,
      this.colorData,
      this.textColorData,
      this.width,
      this.gradient,
      this.hasShadow = false});

  final Function? onPressed;
  final String titleText;
  final Color? colorData;
  final Color? textColorData;
  final double? width;
  final Gradient? gradient;
  final bool hasShadow;
  final TextAlign titleTextAlign;

  @override
  _PSButtonWidgetState createState() => _PSButtonWidgetState();
}

class _PSButtonWidgetState extends State<PSButtonWidget> {
  Color? _color;
  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null;
    _color = widget.colorData;
    _color ??= Theme.of(context).primaryColor;

    Color effectiveColor = isDisabled ? const Color(0xFFE8DFE2) : _color!;
    Color effectiveTextColor;
    if (widget.textColorData != null) {
      effectiveTextColor = widget.textColorData!;
    } else if (isDisabled) {
      effectiveTextColor = const Color(0xFF6E6568);
    } else if (effectiveColor == Colors.transparent ||
        effectiveColor == Colors.white ||
        effectiveColor == const Color(0xFFFAF7F2)) {
      effectiveTextColor = const Color(0xFF5C1A2B);
    } else {
      effectiveTextColor = Colors.white;
    }

    return Container(
      width: MediaQuery.of(context).size.width,
      height: 40,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4), color: effectiveColor),
      child: Material(
        color: effectiveColor,
        type: MaterialType.card,
        clipBehavior: Clip.antiAlias,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(PsDimens.space4))),
        child: InkWell(
          onTap: widget.onPressed as void Function()?,
          highlightColor: PsColors.primary900,
          child: Center(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                  left: PsDimens.space8, right: PsDimens.space8),
              child: Text(widget.titleText,
                  textAlign: widget.titleTextAlign,
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      color: effectiveTextColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
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
      this.height,
      this.gradient,
      this.icon,
      this.iconAlignment = MainAxisAlignment.center,
      this.hasShadow = false,
      this.iconColor,
      this.textColor});

  final Function? onPressed;
  final String titleText;
  final Color? colorData;
  final double? width;
  final IconData? icon;
  final Gradient? gradient;
  final MainAxisAlignment iconAlignment;
  final bool hasShadow;
  final Color? iconColor;
  final Color? textColor;

  final double? height;

  @override
  _PSButtonWithIconWidgetState createState() => _PSButtonWithIconWidgetState();
}

class _PSButtonWithIconWidgetState extends State<PSButtonWithIconWidget> {
  Color? _color;
  Color? _iconColor;
  Color? _textColor;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null;
    _color = widget.colorData ?? PsColors.primary500;
    Color effectiveColor = isDisabled ? const Color(0xFFE8DFE2) : _color!;

    if (widget.textColor != null) {
      _textColor = widget.textColor;
    } else if (isDisabled) {
      _textColor = const Color(0xFF6E6568);
    } else if (effectiveColor == Colors.transparent ||
        effectiveColor == Colors.white ||
        effectiveColor == const Color(0xFFFAF7F2)) {
      _textColor = const Color(0xFF5C1A2B);
    } else {
      _textColor = Colors.white;
    }

    if (widget.iconColor != null) {
      _iconColor = widget.iconColor;
    } else {
      _iconColor = _textColor;
    }

    return Container(
      width: widget.width, //MediaQuery.of(context).size.width,
      height: widget.height ?? 40,
      decoration:
          BoxDecoration(borderRadius: BorderRadius.circular(4), color: effectiveColor),
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
                  width: PsDimens.space8,
                ),
              Flexible(
                child: Text(
                  widget.titleText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(color: _textColor, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
