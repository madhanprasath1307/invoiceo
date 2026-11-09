import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoiceo/common/constants.dart';
import 'package:invoiceo/l10n/app_localizations.dart';
import 'package:invoiceo/providers/repositories.dart';
import 'package:invoiceo/services/backend_services.dart';
import 'package:invoiceo/utils/contact_support.dart';
import 'package:invoiceo/utils/reset_code_verifier.dart';
import 'package:invoiceo/theme/brand_colors.dart';
import 'package:invoiceo/widgets/language_picker.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _usernameController = TextEditingController();
  final _responseCodeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _installationId;
  String? _companyName;
  String? _verifiedUserId;
  bool _codeJustVerified = false;
  String? _verifiedUsername;
  bool _isVerifying = false;
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInstallationId();
    _loadCompanyName();
  }

  Future<void> _loadInstallationId() async {
    final id = await BackendServices.installation.getOrCreateInstallationId();
    if (!mounted) return;
    setState(() => _installationId = id);
  }

  // Whichever company is currently active is whose `users` table the
  // username below gets looked up against — surfaced here so it's obvious
  // which company's login is about to be reset (relevant once more than one
  // company is registered on this device).
  Future<void> _loadCompanyName() async {
    final info = await ref.read(companyInfoRepositoryProvider).getCompanyInfo();
    if (!mounted) return;
    setState(() => _companyName = info?.name);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _responseCodeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _copyInstallationId() async {
    if (_installationId == null) return;
    await Clipboard.setData(ClipboardData(text: _installationId!));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text(AppLocalizations.of(context)!.resetPasswordIdCopiedMessage)),
    );
  }

  Future<void> _verifyCode() async {
    final l10n = AppLocalizations.of(context)!;
    final username = _usernameController.text.trim();
    final responseCode = _responseCodeController.text.trim();

    setState(() => _errorMessage = null);

    if (username.isEmpty || responseCode.isEmpty) {
      setState(() => _errorMessage = l10n.resetPasswordEnterFieldsMessage);
      return;
    }
    if (_installationId == null) {
      setState(() => _errorMessage = l10n.resetPasswordStillLoadingMessage);
      return;
    }

    setState(() => _isVerifying = true);

    final repo = ref.read(authRepositoryProvider);
    final user = await repo.getUserByUsername(username);
    // The code is signed for one username, so a code made for another
    // user (for example 'admin') does not work here. It is signed
    // lowercased, but usernames are case-sensitive here ('Bob' and 'bob'
    // can both exist), so refuse when another account differs only by
    // case: the code would fit both.
    final folded = username.toLowerCase();
    final sameNameCount = user == null
        ? 0
        : (await repo.getAllUsers())
            .where((u) => u.username.trim().toLowerCase() == folded)
            .length;
    final valid = sameNameCount == 1 &&
        await ResetCodeVerifier.verifyResetCode(
          installationId: _installationId!,
          username: username,
          responseCode: responseCode,
        );

    if (!mounted) return;
    setState(() => _isVerifying = false);

    if (user == null || !valid) {
      setState(() => _errorMessage = l10n.resetPasswordInvalidCodeMessage);
      return;
    }

    setState(() => _codeJustVerified = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    setState(() {
      _verifiedUserId = user.id;
      _verifiedUsername = user.username;
    });
  }

  Future<void> _submitNewPassword() async {
    final l10n = AppLocalizations.of(context)!;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    setState(() => _errorMessage = null);

    if (newPassword.length < 8) {
      setState(() => _errorMessage = l10n.changePasswordMinLengthMessage);
      return;
    }
    if (newPassword.toLowerCase() == _verifiedUsername?.toLowerCase()) {
      setState(() => _errorMessage = l10n.changePasswordSameAsUsernameMessage);
      return;
    }
    if (newPassword != confirmPassword) {
      setState(() => _errorMessage = l10n.userMgmtPasswordsDoNotMatchMessage);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ref
          .read(authRepositoryProvider)
          .updatePassword(_verifiedUserId!, newPassword);
      await ref
          .read(authRepositoryProvider)
          .markPasswordChanged(_verifiedUserId!);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.resetPasswordSuccessMessage),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = l10n.resetPasswordFailedMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.sizeOf(context).width;
    // Same phone/tablet fix as login_screen.dart: fill the width (minus
    // side padding) on phones instead of the old `width * 0.3`, which
    // shrank to an unusably narrow card on tablet/phone widths.
    final isPhone = screenWidth < 600;
    final cardWidth = isPhone ? screenWidth - 48 : 460.0;
    final cardPadding = isPhone ? 20.0 : 32.0;
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? null
          : BrandColors.primarySoft,
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                // Room above the card for the language button in the top corner.
                padding: const EdgeInsets.fromLTRB(16, 56, 16, 24),
                child: Card(
                  elevation: 8,
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  child: Container(
                    width: cardWidth,
                    padding: EdgeInsets.all(cardPadding),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.password_outlined,
                              color: Theme.of(context).primaryColor,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                l10n.resetPasswordTitle,
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        if (_verifiedUserId == null) ...[
                          AppSpacing.hSmall,
                          Text(l10n.resetPasswordIntro,
                              style: const TextStyle(fontSize: 13.5)),
                          AppSpacing.hLarge,

                          // Step 1: what to send. Support signs the code for one
                          // username, so they need it with the Installation ID.
                          _step(1, l10n.resetPasswordStep1Title,
                              l10n.resetPasswordStep1Body),
                          AppSpacing.hSmall,
                          Container(
                            padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: SelectableText(
                                    _installationId ??
                                        l10n.resetPasswordLoadingLabel,
                                    style: const TextStyle(
                                        fontFamily: 'monospace', fontSize: 13),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 18),
                                  tooltip: l10n.resetPasswordCopyIdTooltip,
                                  onPressed: _installationId == null
                                      ? null
                                      : _copyInstallationId,
                                ),
                              ],
                            ),
                          ),
                          AppSpacing.hSmall,
                          Align(
                            alignment: Alignment.centerLeft,
                            child: OutlinedButton.icon(
                              key: const ValueKey('resetOpenSupport'),
                              onPressed: contactSupport,
                              icon: const Icon(Icons.support_agent, size: 18),
                              label: Text(l10n.resetPasswordSupportButton),
                            ),
                          ),

                          AppSpacing.hLarge,
                          _step(2, l10n.resetPasswordStep2Title,
                              l10n.resetPasswordStep2Body),
                          AppSpacing.hLarge,
                          _step(3, l10n.resetPasswordStep3Title,
                              l10n.resetPasswordUsernameHelp),

                          AppSpacing.hMedium,

                          if (_codeJustVerified)
                            _buildSuccessBox(l10n.resetPasswordVerifiedMessage)
                          else ...[
                            if (_companyName != null &&
                                _companyName!.isNotEmpty) ...[
                              Text(
                                l10n.resetPasswordCompanyLabel(_companyName!),
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant),
                              ),
                              AppSpacing.hSmall,
                            ],
                            TextField(
                              controller: _usernameController,
                              decoration: InputDecoration(
                                labelText: l10n.loginUsernameLabel,
                                prefixIcon: const Icon(Icons.person),
                                border: const OutlineInputBorder(),
                              ),
                            ),
                            AppSpacing.hMedium,
                            TextField(
                              controller: _responseCodeController,
                              decoration: InputDecoration(
                                labelText: l10n.resetPasswordResponseCodeLabel,
                                prefixIcon: const Icon(Icons.vpn_key_outlined),
                                border: const OutlineInputBorder(),
                              ),
                            ),
                            if (_errorMessage != null) ...[
                              AppSpacing.hMedium,
                              _buildErrorBox(_errorMessage!),
                            ],
                            AppSpacing.hXlarge,
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isVerifying ? null : _verifyCode,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 50),
                                  backgroundColor:
                                      Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                ),
                                child: _isVerifying
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(l10n.resetPasswordVerifyButton),
                              ),
                            ),
                          ],
                        ] else ...[
                          _buildSuccessBox(l10n.resetPasswordVerifiedMessage),
                          AppSpacing.hMedium,
                          TextField(
                            controller: _newPasswordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: l10n.changePasswordNewPasswordLabel,
                              prefixIcon: const Icon(Icons.lock),
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                          ),
                          AppSpacing.hMedium,
                          TextField(
                            controller: _confirmPasswordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: l10n.userMgmtConfirmNewPasswordLabel,
                              prefixIcon: const Icon(Icons.lock),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          if (_errorMessage != null) ...[
                            AppSpacing.hMedium,
                            _buildErrorBox(_errorMessage!),
                          ],
                          AppSpacing.hXlarge,
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  _isSubmitting ? null : _submitNewPassword,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 50),
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(l10n.resetPasswordSetButton),
                            ),
                          ),
                        ],
                        AppSpacing.hMedium,
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(l10n.resetPasswordBackToLoginButton),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Language, top right (same button as on the login page).
          const Positioned(
            right: 12,
            top: 12,
            child: SafeArea(child: LanguageMenuButton()),
          ),
        ],
      ),
    );
  }

  /// One numbered step of the reset: a round number, a bold heading and a short line under it.
  Widget _step(int number, String title, String body) {
    final primary = Theme.of(context).primaryColor;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
          child: Text('$number',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(body,
                  style: TextStyle(
                      fontSize: 12.5,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessBox(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        border: Border.all(color: Colors.green[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.green, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBox(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
