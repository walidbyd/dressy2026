import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:theme_manager/theme_manager.dart';

import 'config/ps_colors.dart';
import 'config/ps_config.dart';
import 'config/ps_theme_data.dart';
import 'config/route/router.dart' as router;
import 'core/vendor/db/common/ps_shared_preferences.dart';
import 'core/vendor/provider/language/app_localization_provider.dart';
import 'core/vendor/provider/order_id/order_id_provider.dart';
import 'core/vendor/provider/ps_provider_dependencies.dart';
import 'core/vendor/utils/utils.dart';
import 'core/vendor/viewobject/common/language.dart';
import 'firebase_options.dart';

Future<void> configure() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await AppLocalization.instance
        .ensureInitialized()
        .timeout(const Duration(seconds: 5));
  } catch (e) {
    Utils.psPrint('AppLocalization init error: $e');
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 6));
    // AppCheck
    await FirebaseAppCheck.instance.activate(
        androidProvider:
            kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity);
  } catch (e) {
    Utils.psPrint('Firebase init error: $e');
  }

  try {
    MobileAds.instance.initialize().timeout(const Duration(seconds: 4));
  } catch (e) {
    Utils.psPrint('MobileAds init error: $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await configure().timeout(const Duration(seconds: 10));
  } catch (e) {
    Utils.psPrint('Configure timeout or error: $e');
  }

  try {
    final SharedPreferences prefs = await SharedPreferences.getInstance()
        .timeout(const Duration(seconds: 4));
    if (prefs.getString('codeC') == null) {
      await prefs.setString('codeC', '');
      await prefs.setString('codeL', '');
    }
  } catch (e) {
    Utils.psPrint('SharedPreferences init error: $e');
  }

  try {
    if (Platform.isIOS) {
      FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
    }

    /// Update the iOS foreground notification presentation options to allow
    /// heads up notifications.
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    ).timeout(const Duration(seconds: 4));
  } catch (e) {
    Utils.psPrint('FCM permissions error: $e');
  }

  //check is apple signin is available
  try {
    await Utils.checkAppleSignInAvailable().timeout(const Duration(seconds: 3));
  } catch (e) {
    Utils.psPrint('AppleSignIn check error: $e');
  }

  try {
    WidgetsFlutterBinding.ensureInitialized();
    Utils.cameras = await availableCameras().timeout(const Duration(seconds: 3));
    print(Utils.cameras);
  } catch (e) {
    Utils.psPrint('Camera init error: $e');
  }

  PsConfig.showLog = true;
  runApp(PSApp());
}

List<Locale> getSupportedLanguages() {
  final List<Locale> localeList = <Locale>[];
  for (final Language lang in PsConfig.psSupportedLanguageList) {
    localeList.add(Locale(lang.languageCode!, lang.countryCode));
  }
  print('Loaded Languages');
  return localeList;
}

class PSApp extends StatefulWidget {
  @override
  _PSAppState createState() => _PSAppState();
}

class _PSAppState extends State<PSApp> {
  Completer<ThemeData>? themeDataCompleter;
  PsSharedPreferences? psSharedPreferences;

  @override
  void initState() {
    super.initState();
  }

  List<Locale> getSupportedLanguages() {
    final List<Locale> localeList = <Locale>[];
    for (final Language lang in PsConfig.psSupportedLanguageList) {
      localeList.add(Locale(lang.languageCode!, lang.countryCode));
    }
    print('Loaded Languages');
    return localeList;
  }

  @override
  Widget build(BuildContext context) {
    // init Color
    // PsColors.loadColor(context);
    print('*** ${Utils.convertColorToString(PsColors.primary500)}');
    // Utils.psPrint(EasyLocalization.of(context)!.locale.languageCode);

    return MultiProvider(
        providers: <SingleChildWidget>[
          ChangeNotifierProvider<AppLocalization>(
              create: (BuildContext context) {
            return AppLocalization.instance;
          }),
          ChangeNotifierProvider<OrderIdProvider>(
              create: (BuildContext context) {
            return OrderIdProvider.instance;
          }),
          ...providers,
        ],
        child: ThemeManager(
            defaultBrightnessPreference: BrightnessPreference.light,
            data: (Brightness brightness) {
              if (brightness == Brightness.light) {
                return themeData(ThemeData.light());
              } else {
                return themeData(ThemeData.dark());
              }
            },
            themedBuilder: (BuildContext context, ThemeState theme) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'Dressy',
                theme: theme.themeData,
                initialRoute: '/',
                onGenerateRoute: router.generateRoute,
                localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales:
                    context.watch<AppLocalization>().supportedLocales,
                locale: context.watch<AppLocalization>().currentLocale,
              );
            }));
  }
}
