import 'dart:async';

import 'package:medicare/helpers/localizations/app_localization_delegate.dart';
import 'package:medicare/helpers/localizations/language.dart';
import 'package:medicare/helpers/services/navigation_service.dart';
import 'package:medicare/helpers/storage/local_storage.dart';
import 'package:medicare/helpers/theme/app_notifire.dart';
import 'package:medicare/helpers/theme/app_style.dart';
import 'package:medicare/helpers/theme/theme_customizer.dart';
import 'package:medicare/controller/auth_controller.dart';
import 'package:medicare/controller/app_notification_controller.dart';
import 'package:medicare/routes.dart';
import 'package:medicare/views/ui/error_pages/error_404_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:medicare/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:url_strategy/url_strategy.dart';

Future<void> main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Log Flutter framework errors (layout overflows, build errors, etc.)
      // without navigating away — these are non-fatal in most cases.
      FlutterError.onError = FlutterError.presentError;

      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      setPathUrlStrategy();

      await LocalStorage.init();
      AppStyle.init();
      await ThemeCustomizer.init();
      Get.put(AppAuthController(), permanent: true);
      Get.put(AppNotificationController(), permanent: true);

      runApp(ChangeNotifierProvider<AppNotifier>(
        create: (context) => AppNotifier(),
        child: const MyApp(),
      ));
    },
    // Catches unhandled async errors (zone errors).
    (Object error, StackTrace stack) {
      _goToError500();
    },
  );
}

void _goToError500() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (Get.currentRoute != '/error/500') {
      Get.offAllNamed('/error/500');
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppNotifier>(
      builder: (_, notifier, ___) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeCustomizer.instance.theme,
          navigatorKey: NavigationService.navigatorKey,
          initialRoute: "/dashboard",
          getPages: getPageRoute(),
          // Show 404 page for any unrecognised route.
          unknownRoute: GetPage(
            name: '/error/404',
            page: () => const Error404Screen(),
            transition: Transition.noTransition,
          ),
          builder: (context, child) {
            NavigationService.registerContext(context);
            return Directionality(
              textDirection: AppTheme.textDirection,
              child: child ?? Container(),
            );
          },
          localizationsDelegates: [
            AppLocalizationsDelegate(context),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: Language.getLocales(),
        );
      },
    );
  }
}
