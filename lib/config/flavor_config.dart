/// Which app store this build targets.
/// Set by the flavor-specific entry point (main_amazon.dart, main_google.dart).
enum AppFlavor { ios, google, amazon }

class FlavorConfig {
  static AppFlavor _flavor = AppFlavor.ios;

  static void initialize(AppFlavor flavor) => _flavor = flavor;

  static AppFlavor get flavor => _flavor;
  static bool get isAmazon => _flavor == AppFlavor.amazon;
  static bool get isGoogle => _flavor == AppFlavor.google;
  static bool get isIos => _flavor == AppFlavor.ios;

  static String get storeName {
    switch (_flavor) {
      case AppFlavor.amazon:
        return 'Amazon Appstore';
      case AppFlavor.google:
        return 'Google Play';
      case AppFlavor.ios:
        return 'App Store';
    }
  }

  /// Replace with your real hosted URL before publishing.
  static String get privacyPolicyUrl => 'https://example.com/privacy';
}
