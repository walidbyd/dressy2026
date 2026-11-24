import 'package:flutter/material.dart';
import '../../../../../../config/ps_colors.dart';
import '../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../core/vendor/utils/utils.dart';

class ConfirmDialogView extends StatefulWidget {
  const ConfirmDialogView({
    Key? key,
    this.description,
    this.leftButtonText,
    this.rightButtonText,
    this.title,
    this.onAgreeTap,
    this.onCancelTap,
    this.iconData,
    this.confirmColor,
    this.cancelColor,
  }) : super(key: key);

  final String? description;
  final String? leftButtonText;
  final String? rightButtonText;
  final String? title;
  final Function? onAgreeTap;
  final Function? onCancelTap;
  final IconData? iconData;
  final Color? confirmColor;
  final Color? cancelColor;

  @override
  _ConfirmDialogViewState createState() => _ConfirmDialogViewState();
}

class _ConfirmDialogViewState extends State<ConfirmDialogView> {
  @override
  Widget build(BuildContext context) {
    return _NewConfirmDialog(widget: widget);
  }
}

class _NewConfirmDialog extends StatelessWidget {
  const _NewConfirmDialog({
    Key? key,
    required this.widget,
  }) : super(key: key);

  final ConfirmDialogView widget;

  IconData _resolveIcon() {
    if (widget.iconData != null) {
      return widget.iconData!;
    }
    final String combined =
        '${widget.title ?? ''} ${widget.description ?? ''}'.toLowerCase();
    if (combined.contains('logout') ||
        combined.contains('déconnect') ||
        combined.contains('deconnect') ||
        combined.contains('quitter')) {
      return Icons.logout_rounded;
    }
    if (combined.contains('language') ||
        combined.contains('langue') ||
        combined.contains('locale')) {
      return Icons.language_rounded;
    }
    if (combined.contains('delete') ||
        combined.contains('supprim') ||
        combined.contains('remove')) {
      return Icons.delete_outline_rounded;
    }
    return Icons.help_outline_rounded;
  }

  bool _isDestructive() {
    final String combined =
        '${widget.title ?? ''} ${widget.description ?? ''}'.toLowerCase();
    return combined.contains('delete') ||
        combined.contains('supprim') ||
        combined.contains('remove');
  }

  @override
  Widget build(BuildContext context) {
    final bool isLight = Utils.isLightMode(context);
    final IconData icon = _resolveIcon();
    final bool isDestructive = _isDestructive();

    final Color primaryTone = widget.confirmColor ??
        (isDestructive ? const Color(0xFFDC2626) : PsColors.burgundy);

    final Color badgeBg = primaryTone.withValues(alpha: 0.10);
    final Color badgeIconColor = primaryTone;

    final String combined =
        '${widget.title ?? ''} ${widget.description ?? ''}'.toLowerCase();
    final String resolvedTitle =
        (widget.title != null && widget.title!.trim().isNotEmpty)
            ? widget.title!.trim()
            : (combined.contains('logout') || combined.contains('déconnect')
                ? 'home__menu_drawer_logout'.tr
                : (combined.contains('langue') || combined.contains('language')
                    ? 'language_setting__title'.tr
                    : 'Confirmation'.tr));

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22.0),
      ),
      elevation: 6,
      backgroundColor: isLight ? Colors.white : const Color(0xFF1F2937),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            // Top Icon Badge (52px circular, 10% opacity tint)
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: badgeBg,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 26,
                  color: badgeIconColor,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Dialog Title
            if (resolvedTitle.isNotEmpty) ...<Widget>[
              Text(
                resolvedTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: isLight ? PsColors.text800 : PsColors.text50,
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Dialog Description
            if (widget.description != null &&
                widget.description!.trim().isNotEmpty) ...<Widget>[
              Text(
                widget.description!.trim(),
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w400,
                  color: isLight ? PsColors.text600 : PsColors.text300,
                ),
              ),
              const SizedBox(height: 24),
            ] else ...<Widget>[
              const SizedBox(height: 16),
            ],

            // Action Buttons: Cancel (Left) + Confirm (Right)
            Row(
              children: <Widget>[
                // Left Button (Cancel / Annuler)
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isLight
                            ? const Color(0xFFF3F4F6)
                            : const Color(0xFF374151),
                        side: BorderSide(
                          color: isLight
                              ? const Color(0xFFE5E7EB)
                              : const Color(0xFF4B5563),
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onPressed: () {
                        if (widget.onCancelTap != null) {
                          widget.onCancelTap!();
                        } else {
                          Navigator.of(context).pop(false);
                        }
                      },
                      child: Text(
                        (widget.leftButtonText != null &&
                                widget.leftButtonText!.isNotEmpty)
                            ? widget.leftButtonText!
                            : 'dialog__cancel'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isLight
                              ? const Color(0xFF374151)
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Right Button (Confirm / Oui)
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryTone,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onPressed: () {
                        if (widget.onAgreeTap != null) {
                          widget.onAgreeTap!();
                        } else {
                          Navigator.of(context).pop(true);
                        }
                      },
                      child: Text(
                        (widget.rightButtonText != null &&
                                widget.rightButtonText!.isNotEmpty)
                            ? widget.rightButtonText!
                            : 'dialog__ok'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
