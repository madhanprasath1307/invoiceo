import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoiceo/database/database_helper.dart';
import 'package:invoiceo/l10n/app_localizations.dart';
import 'package:invoiceo/screens/auth/login_screen.dart';
import 'package:invoiceo/common/constants.dart';
import 'package:invoiceo/common/setting_key.dart';
import 'package:invoiceo/providers/app_config_provider.dart';
import 'package:invoiceo/providers/repositories.dart';
import 'package:invoiceo/utils/app_logger.dart';
import 'package:invoiceo/utils/post_auth_navigation.dart';
import 'package:invoiceo/utils/saved_session.dart';
import 'package:invoiceo/models/user.dart';

const _tag = 'SplashScreen';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await DatabaseHelper().database;
    } catch (e, stack) {
      AppLogger.e(_tag, 'Database initialization failed', e, stack);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.splashInitErrorTitle),
          content: Text(l10n.splashInitErrorMessage('$e')),
          actions: [
            ElevatedButton(
              onPressed: () => _initializeApp(),
              child: Text(l10n.actionRetry),
            ),
          ],
        ),
      );
      return;
    }

    AppLogger.d(_tag, 'DB path: ${DatabaseHelper.path}');

    if (!mounted) return;
    // Used less than the chosen time ago (Settings → Automatic sign-out; 3 days unless changed): open straight in
    // as the same user. Not in the cloud edition or a test build (its sign-in has its own checks).
    final user = await _savedUser();
    if (!mounted) return;
    if (user != null) {
      await navigateAfterAuth(context, ref, user);
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  Future<User?> _savedUser() async {
    try {
      if (ref.read(appEditionConfigProvider).isCloud || TestBuildConfig.isTestBuild) return null;
      final minutes = parseAutoSignOutMinutes(
          await ref.read(settingsRepositoryProvider).getSetting(SettingKey.autoSignOutMinutes));
      return await SavedSession.restore(ref.read(authRepositoryProvider), minutes);
    } catch (e, stack) {
      AppLogger.e(_tag, 'Saved sign-in not used', e, stack);
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(AppLocalizations.of(context)!.splashInitializingMessage,
                style: const TextStyle(fontSize: 18)),
            AppSpacing.hXlarge,
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
