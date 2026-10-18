/// Master Admin & Security Configuration.
/// Holds default fallback credentials, whitelists, and UPI remittance metadata.
class AdminConfig {
  AdminConfig._();

  /// Default fallback 6-digit Master PIN if not yet initialized in Firestore.
  static const String defaultMasterPin = '778899';

  /// Default whitelisted admin emails (case-insensitive check).
  static const List<String> defaultAdminEmails = [
    'mohitagnihotri.dev@gmail.com',
    'mohit.developer@gmail.com',
    'admin@messmate.app',
  ];

  /// Developer Direct UPI ID for 0% gateway cut remittances.
  static const String developerUpiId = 'messmate.admin@okaxis';
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
