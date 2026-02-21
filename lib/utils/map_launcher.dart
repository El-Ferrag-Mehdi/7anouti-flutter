import 'package:url_launcher/url_launcher.dart';

Future<bool> launchMaps({
  double? latitude,
  double? longitude,
  String? address,
}) async {
  final hasCoords = latitude != null && longitude != null;
  final hasAddress = address != null && address.trim().isNotEmpty;

  if (!hasCoords && !hasAddress) return false;

  final query = hasCoords
      ? '${latitude!},${longitude!}'
      : Uri.encodeComponent(address!.trim());

  final uri = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=$query',
  );

  if (await canLaunchUrl(uri)) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
  return false;
}
