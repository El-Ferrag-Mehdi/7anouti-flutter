import 'package:url_launcher/url_launcher.dart';

const privacyPolicyUrl =
    'https://sevenanouti-backend.onrender.com/privacy-policy';

Future<bool> openPrivacyPolicy() async {
  final uri = Uri.parse(privacyPolicyUrl);
  final openedInApp = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
  if (openedInApp) {
    return true;
  }

  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
