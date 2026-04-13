import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';
import 'package:pattern_lock/pattern_lock.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/providers.dart';
import '../../../services/security_service.dart';

enum LockScreenMode { setup, authenticate }

class LockScreen extends ConsumerStatefulWidget {
  final LockScreenMode mode;
  final AuthMethod method;
  final Function(String)? onSetupComplete;
  final Function(List<int>)? onPatternSetupComplete;
  final VoidCallback? onAuthenticated;
  final bool isMandatory;

  const LockScreen({
    super.key,
    required this.mode,
    required this.method,
    this.onSetupComplete,
    this.onPatternSetupComplete,
    this.onAuthenticated,
    this.isMandatory = false,
  });

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String _error = '';
  bool _showPinFallback = false;
  final _pinController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.mode == LockScreenMode.authenticate && widget.method == AuthMethod.fingerprint) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _authenticateBiometrically();
      });
    }
  }

  Future<void> _authenticateBiometrically() async {
    final security = ref.read(securityServiceProvider);
    final success = await security.authenticateBiometrically();
    if (success) {
      widget.onAuthenticated?.call();
    }
  }

  void _handlePinSubmit(String pin) async {
    final security = ref.read(securityServiceProvider);
    if (widget.mode == LockScreenMode.setup) {
      widget.onSetupComplete?.call(pin);
    } else {
      final success = await security.verifyPin(pin);
      if (success) {
        widget.onAuthenticated?.call();
      } else {
        setState(() => _error = 'Invalid PIN');
        _pinController.clear();
      }
    }
  }

  void _handlePatternSubmit(List<int> pattern) async {
    final security = ref.read(securityServiceProvider);
    if (widget.mode == LockScreenMode.setup) {
      widget.onPatternSetupComplete?.call(pattern);
    } else {
      final success = await security.verifyPattern(pattern);
      if (success) {
        widget.onAuthenticated?.call();
      } else {
        setState(() => _error = 'Invalid Pattern');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.background, AppColors.surfaceDim],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
              const Icon(Icons.lock_outline_rounded, size: 64, color: AppColors.primary),
              const SizedBox(height: 24),
              Text(
                widget.mode == LockScreenMode.setup 
                    ? 'Set Security Lock' 
                    : 'App Locked',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                _getInstructionText(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 48),
              if (widget.method == AuthMethod.pin || _showPinFallback) _buildPinUI(),
              if (widget.method == AuthMethod.pattern && !_showPinFallback) _buildPatternUI(),
              if (widget.method == AuthMethod.fingerprint && 
                  widget.mode == LockScreenMode.authenticate &&
                  !_showPinFallback) 
                _buildBiometricRetryUI(),
              
              if (_error.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(_error, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.expense, fontWeight: FontWeight.bold)),
              ],
              if (widget.isMandatory && widget.mode == LockScreenMode.setup) ...[
                const SizedBox(height: 48),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 48),
                  child: Text(
                    'Security setup is mandatory on first installation to protect your financial data.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ),
              ],
            ],
            ),
          ),
        ),
      ),
    );
  }

  String _getInstructionText() {
    if (widget.mode == LockScreenMode.setup) {
      return widget.method == AuthMethod.pin ? 'Enter a 6-digit PIN' : 'Draw a pattern to secure the app';
    }
    return widget.method == AuthMethod.fingerprint ? 'Use biometrics to unlock' : 'Enter your credentials';
  }

  Widget _buildPinUI() {
    final defaultPinTheme = PinTheme(
      width: 48,
      height: 56,
      textStyle: const TextStyle(fontSize: 22, color: AppColors.textPrimary, fontWeight: FontWeight.bold),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
    );

    return Center(
      child: Pinput(
        length: 6,
        controller: _pinController,
        focusNode: _focusNode,
        autofocus: true,
        defaultPinTheme: defaultPinTheme,
        hapticFeedbackType: HapticFeedbackType.lightImpact,
        onCompleted: _handlePinSubmit,
        cursor: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 9),
              width: 22,
              height: 1,
              color: AppColors.primary,
            ),
          ],
        ),
        focusedPinTheme: defaultPinTheme.copyWith(
          decoration: defaultPinTheme.decoration!.copyWith(
            border: Border.all(color: AppColors.primary, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildPatternUI() {
    return SizedBox(
      height: 300,
      child: PatternLock(
        notSelectedColor: AppColors.border,
        selectedColor: AppColors.secondary,
        pointRadius: 8,
        showInput: true,
        dimension: 3,
        onInputComplete: _handlePatternSubmit,
      ),
    );
  }

  Widget _buildBiometricRetryUI() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.fingerprint_rounded,
              size: 64, color: AppColors.primary),
          onPressed: _authenticateBiometrically,
        ),
        const SizedBox(height: 16),
        const Text(
          'Tap sensor icon if prompt dismissed',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 24),
        TextButton.icon(
          onPressed: () => setState(() => _showPinFallback = true),
          icon: const Icon(Icons.pin_rounded, size: 18),
          label: const Text('Use PIN instead'),
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
        ),
      ],
    );
  }
}
