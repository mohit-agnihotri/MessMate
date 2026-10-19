import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Security result holding validation outcome and failure reasons.
class PasswordValidationResult {
  final bool isValid;
  final int strengthScore; // 0 (Very Weak) to 4 (Very Strong)
  final List<String> issues;
  final bool isBreached;
  final int breachCount;

  const PasswordValidationResult({
    required this.isValid,
    required this.strengthScore,
    this.issues = const [],
    this.isBreached = false,
    this.breachCount = 0,
  });

  String get strengthLabel {
    switch (strengthScore) {
      case 0:
        return 'Very Weak';
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      default:
        return 'Unknown';
    }
  }
}

/// Centralized Security & Cryptographic Protection Service.
///
/// Features:
/// 1. Zero-knowledge HaveIBeenPwned k-Anonymity Leaked Password Detection.
/// 2. Strict Password Policy Enforcement (Length, Entropy, Character Diversity).
/// 3. SHA-256 Salted Hashing for PINs and Secrets.
/// 4. Brute-Force Rate Limiting & Account Lockout Defense.
class SecurityService {
  SecurityService._();

  static const String _salt = 'MessMate_SecureSalt_v1_#@!987';

  // ─── Brute-Force Defense State ─────────────────────────────────────
  static int _failedAttempts = 0;
  static DateTime? _lockoutUntil;
  static const int maxFailedAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 5);

  /// Checks if authentication attempts are currently rate-limited/locked.
  static bool isLockedOut() {
    if (_lockoutUntil == null) return false;
    if (DateTime.now().isAfter(_lockoutUntil!)) {
      _lockoutUntil = null;
      _failedAttempts = 0;
      return false;
    }
    return true;
  }

  /// Returns remaining lockout time in seconds.
  static int remainingLockoutSeconds() {
    if (!isLockedOut() || _lockoutUntil == null) return 0;
    return _lockoutUntil!.difference(DateTime.now()).inSeconds.clamp(0, 300);
  }

  /// Registers a failed attempt and activates lockout if threshold exceeded.
  static void recordFailedAttempt() {
    _failedAttempts++;
    if (_failedAttempts >= maxFailedAttempts) {
      _lockoutUntil = DateTime.now().add(lockoutDuration);
      debugPrint('[SecurityService] ALERT: Brute-force lockout triggered until $_lockoutUntil');
    }
  }

  /// Clears failed attempt counters upon verified access.
  static void recordSuccessfulAttempt() {
    _failedAttempts = 0;
    _lockoutUntil = null;
  }

  /// Manually clears lockout and resets failed attempts.
  static void resetLockout() {
    _failedAttempts = 0;
    _lockoutUntil = null;
  }

  // ─── Cryptographic Hashing ─────────────────────────────────────────

  /// Generates salted SHA-256 hash of a string (PIN or secret).
  static String hashSecret(String secret) {
    final bytes = utf8.encode('$secret:$_salt');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verifies an input secret against a stored hash (with legacy plaintext fallback support).
  static bool verifySecret(String input, String storedHashOrPlaintext) {
    if (input.trim().isEmpty || storedHashOrPlaintext.trim().isEmpty) return false;
    final cleanInput = input.trim();
    final cleanStored = storedHashOrPlaintext.trim();

    // 1. Compare against salted SHA-256
    final computedHash = hashSecret(cleanInput);
    if (computedHash == cleanStored) return true;

    // 2. Legacy fallback if stored format was not yet hashed
    if (cleanInput == cleanStored) return true;

    return false;
  }

  // ─── Password Policy Engine ────────────────────────────────────────

  /// Validates password against enterprise security rules:
  /// - Min 8 characters (Recommended 10+)
  /// - At least one uppercase letter
  /// - At least one lowercase letter
  /// - At least one numeric digit
  /// - At least one special character (!@#$%^&*...)
  /// - Not in common dictionary blacklist
  static PasswordValidationResult validatePasswordRules(String password) {
    final issues = <String>[];
    int score = 0;

    if (password.length < 8) {
      issues.add('Password must be at least 8 characters long');
    } else {
      score++;
      if (password.length >= 12) score++;
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      issues.add('Include at least one uppercase letter (A-Z)');
    } else {
      score++;
    }

    if (!RegExp(r'[a-z]').hasMatch(password)) {
      issues.add('Include at least one lowercase letter (a-z)');
    }

    if (!RegExp(r'[0-9]').hasMatch(password)) {
      issues.add('Include at least one number (0-9)');
    } else {
      score++;
    }

    if (!RegExp(r'[!@#\$&*~%^()_\-+=\[\]{}|:;,.?]').hasMatch(password)) {
      issues.add('Include at least one special character (!@#\$%^&*...)');
    }

    if (_commonPasswords.contains(password.toLowerCase().trim())) {
      issues.add('This password is too common and easily guessable');
      score = 0;
    }

    final normalizedScore = score.clamp(0, 4);
    final isValid = issues.isEmpty;

    return PasswordValidationResult(
      isValid: isValid,
      strengthScore: normalizedScore,
      issues: issues,
    );
  }

  // ─── HaveIBeenPwned Leaked Password Detection (k-Anonymity) ─────────

  /// Checks if the password has appeared in previous global data breaches
  /// using the official HaveIBeenPwned API via private k-Anonymity.
  ///
  /// Neither the password nor its full hash is ever sent to the network.
  /// Only the first 5 characters of the SHA-1 hash are transmitted.
  static Future<PasswordValidationResult> checkPasswordSecurity(String password) async {
    // 1. Local Policy Check
    final localResult = validatePasswordRules(password);
    if (!localResult.isValid) {
      return localResult;
    }

    // 2. Leaked Database Lookup (k-Anonymity)
    try {
      final sha1Bytes = utf8.encode(password);
      final sha1Hash = sha1.convert(sha1Bytes).toString().toUpperCase();
      final prefix = sha1Hash.substring(0, 5);
      final suffix = sha1Hash.substring(5);

      final url = Uri.parse('https://api.pwnedpasswords.com/range/$prefix');
      final response = await http.get(url, headers: {
        'User-Agent': 'MessMate-Security-Checker/1.0',
      }).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final lines = response.body.split('\r\n');
        for (final line in lines) {
          final parts = line.split(':');
          if (parts.length == 2 && parts[0].trim() == suffix) {
            final count = int.tryParse(parts[1].trim()) ?? 1;
            return PasswordValidationResult(
              isValid: false,
              strengthScore: 0,
              isBreached: true,
              breachCount: count,
              issues: [
                'SECURITY WARNING: This password was found in $count public data leaks. Choose a different, unique password.',
              ],
            );
          }
        }
      }
    } catch (e) {
      debugPrint('[SecurityService] HIBP lookup notice (network offline or skipped): $e');
    }

    return localResult;
  }

  static const Set<String> _commonPasswords = {
    '123456',
    '12345678',
    '123456789',
    'password',
    'password123',
    'admin',
    'admin123',
    'welcome',
    'welcome123',
    'messmate',
    'messmate123',
    'qwerty',
    'letmein',
    'testing123',
  };
}
