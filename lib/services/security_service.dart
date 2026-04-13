import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../repositories/general_settings_repository.dart';

enum AuthMethod { pin, pattern, fingerprint, none }

class SecurityService {
  final GeneralSettingsRepository _settingsRepo;
  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  SecurityService(this._settingsRepo);

  static const String _lockEnabledKey = 'security_lock_enabled';
  static const String _authMethodKey = 'security_auth_method';
  static const String _pinKey = 'security_pin_value';
  static const String _patternKey = 'security_pattern_value';
  static const String _lockTimeoutKey = 'security_lock_timeout';

  Future<bool> isLockEnabled() async {
    final value = await _settingsRepo.getSetting(_lockEnabledKey);
    // Mandatory on first install: default to true if null
    if (value == null) return true;
    return value == 'true';
  }

  Future<void> setLockEnabled(bool enabled) async {
    await _settingsRepo.setSetting(_lockEnabledKey, enabled.toString());
  }

  Future<AuthMethod> getAuthMethod() async {
    final value = await _settingsRepo.getSetting(_authMethodKey);
    switch (value) {
      case 'pin':
        return AuthMethod.pin;
      case 'pattern':
        return AuthMethod.pattern;
      case 'fingerprint':
        return AuthMethod.fingerprint;
      default:
        return AuthMethod.none;
    }
  }

  Future<void> setAuthMethod(AuthMethod method) async {
    await _settingsRepo.setSetting(_authMethodKey, method.name);
  }

  Future<void> savePin(String pin) async {
    await _secureStorage.write(key: _pinKey, value: pin);
  }

  Future<bool> verifyPin(String pin) async {
    final savedPin = await _secureStorage.read(key: _pinKey);
    return savedPin == pin;
  }

  Future<void> savePattern(List<int> pattern) async {
    await _secureStorage.write(key: _patternKey, value: pattern.join(','));
  }

  Future<bool> verifyPattern(List<int> pattern) async {
    final savedPattern = await _secureStorage.read(key: _patternKey);
    return savedPattern == pattern.join(',');
  }

  Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  Future<bool> authenticateBiometrically() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Please authenticate to access FinTrack',
        authMessages: const [],
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (e) {
      return false;
    }
  }

  Future<bool> hasCredentials() async {
    final pin = await _secureStorage.read(key: _pinKey);
    final pattern = await _secureStorage.read(key: _patternKey);
    return pin != null || pattern != null;
  }

  /// Whether the app should actually show the lock screen right now.
  /// (If enabled)
  Future<bool> shouldShowLock() async {
    return await isLockEnabled();
  }

  Future<int> getLockTimeoutSeconds() async {
    final value = await _settingsRepo.getSetting(_lockTimeoutKey);
    if (value == null) return 180; // Default to 3 minutes
    return int.tryParse(value) ?? 180;
  }

  Future<void> setLockTimeoutSeconds(int seconds) async {
    await _settingsRepo.setSetting(_lockTimeoutKey, seconds.toString());
  }
}
