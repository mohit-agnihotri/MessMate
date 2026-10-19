/// Master Admin & Security Configuration.
/// Holds default fallback credentials, whitelists, and UPI remittance metadata.
class AdminConfig {
  AdminConfig._();

  /// Default fallback salted SHA-256 hash of Master PIN (prevents plaintext storage in binary).
  static const String defaultMasterPinHash =
      '5daad081c23a1a01894770cbe7b1ffa07b8465e02b4fa541eba5927a0c1c13e0';

  /// Legacy compatibility fallback (deprecated; verification uses SHA-256 hash)
  static const String defaultMasterPin = defaultMasterPinHash;

  /// Default whitelisted admin emails (case-insensitive check).
  static const List<String> defaultAdminEmails = [
    'mohitagnihotri.dev@gmail.com',
    'mohit.developer@gmail.com',
    'admin@messmate.app',
    'agnihotrimohit185@gmail.com',
    'mohitagnihotri1320@gmail.com',
    'mohitagnihotri1305@gmail.com',
  ];

  /// Developer Direct UPI ID for 0% gateway cut remittances.
  static const String developerUpiId = '7974220107@axl';
  static const String developerUpiName = 'MessMate Founder & Dev';

  /// Checks if the given email matches known Super Admin email patterns.
  static bool isSuperAdminEmail(String? email, [List<String>? dynamicWhitelist]) {
    if (email == null || email.trim().isEmpty) return false;
    final normalized = email.trim().toLowerCase();
    
    // Check dynamic whitelist from Firestore first
    if (dynamicWhitelist != null && dynamicWhitelist.isNotEmpty) {
      if (dynamicWhitelist.any((e) => e.trim().toLowerCase() == normalized)) {
        return true;
      }
    }

    // Check hardcoded defaults
    return defaultAdminEmails.any((e) => e.toLowerCase() == normalized);
  }
}
