import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:medicare/firebase_options.dart' as prod;

// Set at build time via --dart-define=FLUTTER_APP_ENV=<value>
// Valid values: dev | staging | prod   (defaults to dev)
const _env = String.fromEnvironment('FLUTTER_APP_ENV', defaultValue: 'dev');

/// Provides environment-aware configuration for the app.
///
/// Usage in build commands:
///   flutter run  --dart-define=FLUTTER_APP_ENV=dev
///   flutter build web --release --dart-define=FLUTTER_APP_ENV=prod
///
/// To wire up separate Firebase projects for dev/staging:
///   1. Create the Firebase project in the console.
///   2. Run:
///        flutterfire configure \
///          --project=<dev-project-id> \
///          --out=lib/firebase_options_dev.dart
///   3. Import the file here and update the switch in [firebaseOptions].
class Environment {
  Environment._();

  /// The active environment name ('dev', 'staging', or 'prod').
  static const String name = _env;

  static bool get isDev     => name == 'dev';
  static bool get isStaging => name == 'staging';
  static bool get isProd    => name == 'prod';

  /// Returns the correct [FirebaseOptions] for the current environment.
  static FirebaseOptions get firebaseOptions {
    switch (name) {
      case 'staging':
        // TODO: import firebase_options_staging.dart when staging project exists
        // import 'package:medicare/firebase_options_staging.dart' as staging;
        // return staging.DefaultFirebaseOptions.currentPlatform;
        return prod.DefaultFirebaseOptions.currentPlatform;

      case 'dev':
        // TODO: import firebase_options_dev.dart when dev project exists
        // import 'package:medicare/firebase_options_dev.dart' as dev;
        // return dev.DefaultFirebaseOptions.currentPlatform;
        return prod.DefaultFirebaseOptions.currentPlatform;

      case 'prod':
      default:
        return prod.DefaultFirebaseOptions.currentPlatform;
    }
  }

  /// Prints the active environment to the console (debug builds only).
  static void log() {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[Environment] FLUTTER_APP_ENV=$name  '
            '(isDev=$isDev, isStaging=$isStaging, isProd=$isProd)');
    }
  }
}
