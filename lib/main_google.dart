import 'config/flavor_config.dart';
import 'main.dart';

/// Google Play Store entry point.
///
/// Set in android/app/build.gradle as the flavorApplication for the
/// 'google' product flavor:
///
///   google {
///     dimension "store"
///     applicationId "com.yourname.toothhurts"
///     manifestPlaceholders = [appName: "ToothHurts"]
///   }
///
/// And set the main entrypoint in the flavor's build config:
///   flavorDimensions += "store"
///   productFlavors {
///     google { ... resValue "string", "app_entry", "main_google" }
///   }
void main() {
  bootstrap(AppFlavor.google);
}
