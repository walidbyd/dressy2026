import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../config/ps_colors.dart';
import '../../../../config/route/route_paths.dart';
import '../../../../core/vendor/constant/ps_dimens.dart';
import '../../../../core/vendor/provider/language/app_localization_provider.dart';
import '../../../../core/vendor/provider/language/language_provider.dart';
import '../../../../core/vendor/repository/language_repository.dart';
import '../../../../core/vendor/utils/ps_progress_dialog.dart';
import '../../../../core/vendor/utils/utils.dart';
import '../../../../core/vendor/viewobject/common/language.dart';
import '../../common/dialog/confirm_dialog_view.dart';

class LanguageListView extends StatefulWidget {
  const LanguageListView({Key? key, this.fromBoard = false}) : super(key: key);
  final bool fromBoard;

  @override
  _LanguageListViewState createState() => _LanguageListViewState();
}

class _LanguageListViewState extends State<LanguageListView> {
  LanguageRepository? repo;
  late LanguageProvider _languageProvider;

  static final List<Language> _dressyLanguages = <Language>[
    Language(
      id: '4',
      symbol: 'fr',
      languageCode: 'fr',
      countryCode: 'FR',
      name: 'Français',
      code: 'fr',
      enable: '1',
    ),
    Language(
      id: '2',
      symbol: 'ar',
      languageCode: 'ar',
      countryCode: 'DZ',
      name: 'العربية',
      code: 'ar',
      enable: '1',
    ),
    Language(
      id: '1',
      symbol: 'en',
      languageCode: 'en',
      countryCode: 'US',
      name: 'English',
      code: 'en',
      enable: '1',
    ),
  ];

  late Language _selectedLanguage;
  bool _initialized = false;
  bool _isApplying = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      repo = Provider.of<LanguageRepository>(context);
      _languageProvider = LanguageProvider(repo: repo);

      final AppLocalization langProvider =
          Provider.of<AppLocalization>(context, listen: false);
      final String currentCode =
          langProvider.currentLocale.languageCode.toLowerCase();

      _selectedLanguage = _dressyLanguages.firstWhere(
        (Language lang) =>
            lang.languageCode?.toLowerCase() == currentCode ||
            lang.symbol?.toLowerCase() == currentCode,
        orElse: () => _dressyLanguages[0], // Default: Français
      );
      _initialized = true;
    }
  }

  Future<void> _applyLanguageAndContinue(
      BuildContext context, Language language) async {
    if (_isApplying) {
      return;
    }
    setState(() {
      _isApplying = true;
    });

    try {
      final AppLocalization langProvider =
          Provider.of<AppLocalization>(context, listen: false);

      await langProvider.setLocale(
        language.toLocale(),
        language.code ?? language.languageCode!,
        language.id ?? '1',
      );
      await _languageProvider.addLanguage(language);
      await _languageProvider.replaceUserChangesLocalLanguage(true);
      await _languageProvider.replaceShowOnboardLanguage(false);
      await _languageProvider.replaceItemLocationData(
          '', 'Toute l’Algérie', '0', '0');
      await _languageProvider.replaceItemLocationTownshipData(
          '', '', 'Toute l’Algérie', '0', '0');

      if (!mounted) {
        return;
      }

      Navigator.pushReplacementNamed(
        context,
        RoutePaths.introSlider,
        arguments: false,
      );
    } catch (e) {
      Utils.psPrint('Error applying language: $e');
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          RoutePaths.introSlider,
          arguments: false,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isApplying = false;
        });
      }
    }
  }

  Future<void> _applyLanguageAndReturn(
      BuildContext context, Language language) async {
    if (_isApplying) {
      return;
    }
    setState(() {
      _isApplying = true;
    });

    try {
      await PsProgressDialog.showDialog(context);
      final AppLocalization langProvider =
          Provider.of<AppLocalization>(context, listen: false);

      await langProvider.setLocale(
        language.toLocale(),
        language.code ?? language.languageCode!,
        language.id ?? '1',
      );
      await _languageProvider.addLanguage(language);
      await _languageProvider.replaceUserChangesLocalLanguage(true);

      await PsProgressDialog.dismissDialog();

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (e) {
      Utils.psPrint('Error applying language: $e');
      await PsProgressDialog.dismissDialog();
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isApplying = false;
        });
      }
    }
  }

  void _onLanguageCardTap(Language language) {
    setState(() {
      _selectedLanguage = language;
    });

    // If accessed from Settings, prompt with confirmation dialog
    if (!widget.fromBoard) {
      final AppLocalization langProvider =
          Provider.of<AppLocalization>(context, listen: false);
      final String activeCode =
          langProvider.currentLocale.languageCode.toLowerCase();

      if (language.languageCode?.toLowerCase() != activeCode) {
        showDialog<dynamic>(
          context: context,
          builder: (BuildContext dialogContext) {
            return ConfirmDialogView(
              iconData: Icons.language_rounded,
              title: 'Changer la langue ?',
              description:
                  'Voulez-vous changer la langue de l\'application en ${language.name} ?',
              leftButtonText: 'dialog__cancel'.tr,
              rightButtonText: 'dialog__ok'.tr,
              onAgreeTap: () async {
                Navigator.pop(dialogContext, true);
                await _applyLanguageAndReturn(context, language);
              },
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLight = Utils.isLightMode(context);
    final AppLocalization langProvider = Provider.of<AppLocalization>(context);
    final String activeCode =
        langProvider.currentLocale.languageCode.toLowerCase();
    final bool isDiffFromActive =
        _selectedLanguage.languageCode?.toLowerCase() != activeCode;

    final Widget content = SafeArea(
      child: Column(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: PsDimens.space20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  if (widget.fromBoard) ...<Widget>[
                    const SizedBox(height: PsDimens.space40),

                    // Top Icon Badge
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: PsColors.burgundy.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.language_rounded,
                          size: 30,
                          color: PsColors.burgundy,
                        ),
                      ),
                    ),
                    const SizedBox(height: PsDimens.space20),

                    // Title
                    Text(
                      'language_selection__choose'.tr.isNotEmpty
                          ? 'language_selection__choose'.tr
                          : 'Choisissez votre langue',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: isLight ? PsColors.text800 : PsColors.text50,
                      ),
                    ),
                    const SizedBox(height: PsDimens.space8),

                    // Subtitle
                    Text(
                      'Sélectionnez votre langue d\'affichage pour une expérience personnalisée sur Dressy.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: isLight ? PsColors.text500 : PsColors.text400,
                      ),
                    ),
                    const SizedBox(height: PsDimens.space36),
                  ] else ...<Widget>[
                    const SizedBox(height: PsDimens.space24),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Langue d\'affichage',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isLight ? PsColors.text800 : PsColors.text50,
                        ),
                      ),
                    ),
                    const SizedBox(height: PsDimens.space4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Choisissez la langue que vous préférez utiliser dans l\'application.',
                        style: TextStyle(
                          fontSize: 13,
                          color: isLight ? PsColors.text500 : PsColors.text400,
                        ),
                      ),
                    ),
                    const SizedBox(height: PsDimens.space20),
                  ],

                  // 3 Language Cards
                  ..._dressyLanguages.map((Language lang) {
                    final bool isSelected = _selectedLanguage.languageCode ==
                        lang.languageCode;
                    return _buildLanguageCard(
                      context: context,
                      language: lang,
                      isSelected: isSelected,
                      onTap: () => _onLanguageCardTap(lang),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),

          // Bottom Action Button
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: PsDimens.space20, vertical: PsDimens.space16),
            decoration: BoxDecoration(
              color: isLight ? Colors.white : PsColors.achromatic800,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: PsColors.burgundy,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _isApplying
                    ? null
                    : () {
                        if (widget.fromBoard) {
                          _applyLanguageAndContinue(context, _selectedLanguage);
                        } else {
                          if (isDiffFromActive) {
                            showDialog<dynamic>(
                              context: context,
                              builder: (BuildContext dialogContext) {
                                return ConfirmDialogView(
                                  iconData: Icons.language_rounded,
                                  title: 'Changer la langue ?',
                                  description:
                                      'Voulez-vous changer la langue de l\'application en ${_selectedLanguage.name} ?',
                                  leftButtonText: 'dialog__cancel'.tr,
                                  rightButtonText: 'dialog__ok'.tr,
                                  onAgreeTap: () async {
                                    Navigator.pop(dialogContext, true);
                                    await _applyLanguageAndReturn(
                                        context, _selectedLanguage);
                                  },
                                );
                              },
                            );
                          } else {
                            Navigator.of(context).pop();
                          }
                        }
                      },
                child: _isApplying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.fromBoard
                            ? ('language_selection__next'.tr.isNotEmpty
                                ? 'language_selection__next'.tr
                                : 'Suivant')
                            : (isDiffFromActive
                                ? 'Appliquer'
                                : 'Continuer'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );

    if (widget.fromBoard) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, dynamic result) {
          if (didPop) {
            return;
          }
          // Do nothing on back button during first-time onboarding
        },
        child: Scaffold(
          backgroundColor: isLight ? PsColors.achromatic50 : PsColors.achromatic900,
          body: content,
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: isLight ? PsColors.achromatic50 : PsColors.achromatic900,
        appBar: AppBar(
          title: Text(
            'language_setting__title'.tr.isNotEmpty
                ? 'language_setting__title'.tr
                : 'Langue',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isLight ? PsColors.text800 : PsColors.text50,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: isLight ? Colors.white : PsColors.achromatic800,
          iconTheme: IconThemeData(
            color: isLight ? PsColors.text800 : PsColors.text50,
          ),
        ),
        body: content,
      );
    }
  }

  Widget _buildLanguageCard({
    required BuildContext context,
    required Language language,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final bool isLight = Utils.isLightMode(context);
    final String nativeName = language.name ?? '';
    final String secondaryLabel = language.languageCode == 'fr'
        ? 'Français'
        : (language.languageCode == 'ar' ? 'العربية (Algérie)' : 'English');

    final String flag = language.languageCode == 'fr'
        ? '🇫🇷'
        : (language.languageCode == 'ar' ? '🇩🇿' : '🇬🇧');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isLight
                      ? PsColors.burgundy.withValues(alpha: 0.05)
                      : PsColors.burgundy.withValues(alpha: 0.16))
                  : (isLight ? Colors.white : PsColors.achromatic800),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? PsColors.burgundy
                    : (isLight
                        ? const Color(0xFFE5E7EB)
                        : const Color(0xFF374151)),
                width: isSelected ? 1.8 : 1.0,
              ),
              boxShadow: isSelected
                  ? <BoxShadow>[
                      BoxShadow(
                        color: PsColors.burgundy.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
            ),
            child: Row(
              children: <Widget>[
                // Flag Container
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? PsColors.burgundy.withValues(alpha: 0.10)
                        : (isLight
                            ? const Color(0xFFF3F4F6)
                            : const Color(0xFF374151)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    flag,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
                const SizedBox(width: 14),

                // Name & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        nativeName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected
                              ? (isLight ? PsColors.burgundy : Colors.white)
                              : (isLight ? PsColors.text800 : PsColors.text50),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        secondaryLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: isLight ? PsColors.text500 : PsColors.text400,
                        ),
                      ),
                    ],
                  ),
                ),

                // Selection Radio Circle
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? PsColors.burgundy : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? PsColors.burgundy
                          : (isLight
                              ? const Color(0xFFD1D5DB)
                              : const Color(0xFF6B7280)),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
