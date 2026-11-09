import 'package:invoiceo/common/app_config.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the support form, which asks for what we need to help (app version,
/// computer, what went wrong). Falls back to email when no browser can be
/// opened. Used by Help -> Contact Support and by the Forgot password page.
Future<void> contactSupport() async {
  var opened = false;
  try {
    opened = await launchUrl(Uri.parse(AppConfig.supportForm), mode: LaunchMode.externalApplication);
  } catch (_) {}
  if (!opened) {
    await launchUrl(Uri(scheme: 'mailto', path: AppConfig.supportEmail), mode: LaunchMode.externalApplication);
  }
}
