import 'package:url_launcher/url_launcher.dart';

String _sanitizePhone(String phone) {
  return phone.replaceAll(RegExp(r'[\s\-()]'), '');
}

Future<bool> launchPhoneCall(String? phone) async {
  if (phone == null) return false;
  final trimmed = phone.trim();
  if (trimmed.isEmpty) return false;

  final cleaned = _sanitizePhone(trimmed);
  final uri = Uri(scheme: 'tel', path: cleaned);

  if (await canLaunchUrl(uri)) {
    return launchUrl(uri);
  }
  return false;
}
