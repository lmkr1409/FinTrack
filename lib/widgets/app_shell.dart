import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../features/dashboard/screens/insights_screen.dart';
import '../features/labeling/screens/label_screen.dart';
import '../features/labeling/screens/labeling_rules_screen.dart';
import '../features/settings/screens/configuration_screen.dart';
import '../features/settings/screens/export_import_screen.dart';
import '../features/help/screens/help_screen.dart';

import '../features/help/screens/app_tour_screen.dart';
import '../services/sms_listener_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/settings/screens/lock_screen.dart';
import '../services/security_service.dart';
import '../services/providers.dart';

/// Root widget: Material 3 Navigation Drawer with themed gradient header.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  bool _isLocked = false;
  bool _isSyncingSms = true; // Assume syncing starts on launch
  int _syncCurrent = 0;
  int _syncTotal = 0;
  DateTime? _lastUnlockTime;
  DateTime? _lastPauseTime;

  static const _titles = [
    'Insights',
    'Configuration',
    'Labeling Rules',
    'Transactions',
    'Backup & Restore',
    'Help & Guide',
  ];
  static const _screens = <Widget>[
    InsightsScreen(),
    ConfigurationScreen(),
    LabelingRulesScreen(),
    LabelScreen(),
    ExportImportScreen(),
    HelpScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLockStatus();
      _startInitialSync();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _lastPauseTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      _checkGracePeriodAndLock();
    }
  }

  Future<void> _checkGracePeriodAndLock() async {
    if (_lastPauseTime == null) {
      _checkLockStatus();
      return;
    }

    final security = ref.read(securityServiceProvider);
    final timeout = await security.getLockTimeoutSeconds();
    final backgroundDuration = DateTime.now().difference(_lastPauseTime!).inSeconds;

    if (backgroundDuration >= timeout) {
      _checkLockStatus();
    }
  }

  Future<void> _checkLockStatus() async {
    final security = ref.read(securityServiceProvider);
    final shouldLock = await security.shouldShowLock();
    
    // Ignore if unlocked in the last 2 seconds (to prevent biometric bounce loops)
    if (_lastUnlockTime != null && 
        DateTime.now().difference(_lastUnlockTime!).inSeconds < 2) {
      return;
    }

    if (shouldLock && !_isLocked) {
      _showLockScreen();
    }
  }

  void _showLockScreen() async {
    final security = ref.read(securityServiceProvider);
    final hasCreds = await security.hasCredentials();
    final method = await security.getAuthMethod();

    if (mounted) {
      setState(() => _isLocked = true);

      if (!hasCreds) {
        // MANDATORY SETUP FLOW
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => LockScreen(
              mode: LockScreenMode.setup,
              method: AuthMethod.pin, // Default to PIN setup
              isMandatory: true,
              onSetupComplete: (pin) async {
                await security.savePin(pin);
                await security.setAuthMethod(AuthMethod.pin);
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
            ),
            fullscreenDialog: true,
          ),
        );
      } else {
        // AUTHENTICATION FLOW
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => LockScreen(
              mode: LockScreenMode.authenticate,
              method: method,
              onAuthenticated: () {
                Navigator.pop(context);
              },
            ),
            fullscreenDialog: true,
          ),
        );
      }

      _lastUnlockTime = DateTime.now();

      // Small delay before setting _isLocked to false to catch any trailing resumed events
      // during modal dialog pop transitions.
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        setState(() => _isLocked = false);
      }
    }
  }

  Future<void> _startInitialSync() async {
    final container = ProviderScope.containerOf(context);
    setState(() => _isSyncingSms = true);
    
    await SmsListenerService.syncInboxMessages(
      container,
      onProgress: (current, total) {
        if (mounted) {
          setState(() {
            _syncCurrent = current;
            _syncTotal = total;
          });
        }
      },
    );

    if (mounted) {
      // Small delay just to show 100% completion briefly if it was long
      if (_syncTotal > 0) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
      setState(() {
        _isSyncingSms = false;
      });
      _checkOnboarding();
    }
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final onboarded = prefs.getBool('onboarding_shown') ?? false;
    if (!onboarded && mounted) {
      await prefs.setBool('onboarding_shown', true);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const AppTourScreen(),
          fullscreenDialog: true,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSyncingSms) {
      double progress = _syncTotal > 0 ? _syncCurrent / _syncTotal : 0.0;
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_balance_wallet_rounded, size: 64, color: AppColors.primary),
              const SizedBox(height: 24),
              const Text('Syncing Messages...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  value: _syncTotal > 0 ? progress : null,
                  backgroundColor: AppColors.surfaceContainer,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              if (_syncTotal > 0)
                Text('$_syncCurrent / $_syncTotal (${(progress * 100).toStringAsFixed(0)}%)', style: const TextStyle(color: AppColors.textMuted)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      drawer: NavigationDrawer(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
          Navigator.pop(context); // close drawer
        },
        children: [
          // Gradient header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.gradientStart, AppColors.gradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 36,
                  color: Colors.white,
                ),
                SizedBox(height: 10),
                Text(
                  'FinTrack',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Personal Finance Tracker',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const NavigationDrawerDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: Text('Insights'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: Text('Configuration'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.rule_outlined),
            selectedIcon: Icon(Icons.rule_rounded),
            label: Text('Labeling Rules'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: Text('Transactions'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.backup_outlined),
            selectedIcon: Icon(Icons.backup),
            label: Text('Backup & Restore'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.help_outline_rounded),
            selectedIcon: Icon(Icons.help_rounded),
            label: Text('Help & Guide'),
          ),
        ],
      ),
      body: _screens[_selectedIndex],
    );
  }
}
