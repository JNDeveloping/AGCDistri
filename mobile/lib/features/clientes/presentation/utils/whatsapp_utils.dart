import 'package:url_launcher/url_launcher.dart';

String? buildWhatsappUrl(String? rawPhone) {
  if (rawPhone == null) return null;
  var digits = rawPhone.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return null;
  if (digits.startsWith('54')) digits = digits.substring(2);
  if (digits.startsWith('9')) digits = digits.substring(1);
  return 'https://wa.me/549$digits';
}

Future<bool> openClientWhatsapp(String? rawPhone) async {
  final url = buildWhatsappUrl(rawPhone);
  if (url == null) return false;

  final uri = Uri.parse(url);
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
