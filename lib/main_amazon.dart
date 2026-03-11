import 'config/flavor_config.dart';
import 'main.dart';

/// Amazon Appstore entry point.
///
/// IMPORTANT — Amazon Fire OS differences:
///
/// 1. BINARY FORMAT: Amazon requires an APK, not an AAB.
///    Build with: flutter build apk --flavor amazon --target lib/main_amazon.dart
///
/// 2. NO GOOGLE PLAY SERVICES: Fire OS ships without GMS.
///    Audit all transitive deps for com.google.android.gms usage.
///    In particular: Firebase, Google Sign-In, Google Maps, AdMob all FAIL silently.
///
/// 3. IN-APP PURCHASES: Flutter's `in_app_purchase` plugin uses Play Billing
///    and does NOT work on Amazon. Use the Amazon Appstore SDK via a
///    method channel or the community `amazon_iap` package if needed.
///
/// 4. PUSH NOTIFICATIONS: FCM does not deliver on Fire tablets.
///    Use Amazon Device Messaging (ADM) instead.
///
/// 5. APP SIGNING: Amazon re-signs the APK with their certificate.
///    Upload your signed APK; Amazon will override the signature.
///
/// 6. CHILD-DIRECTED CONTENT: If submitting to Kids category, set
///    tagForChildDirectedTreatment = true in any ad SDK and declare
///    COPPA compliance in the Amazon Developer Console.
void main() {
  bootstrap(AppFlavor.amazon);
}
