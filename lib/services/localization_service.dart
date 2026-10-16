import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final localizationProvider =
    StateNotifierProvider<LocalizationNotifier, String>((ref) {
      return LocalizationNotifier();
    });

class LocalizationNotifier extends StateNotifier<String> {
  LocalizationNotifier() : super('en') {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('app_language');
      if (saved != null && (saved == 'en' || saved == 'hi')) {
        state = saved;
      }
    } catch (_) {}
  }

  Future<void> toggleLanguage(String lang) async {
    state = lang;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_language', lang);
    } catch (_) {}
  }
}

// Simple translation dictionary
const Map<String, Map<String, String>> _translations = {
  'en': {
    'Live Headcount': 'Live Headcount',
    'Absent Summary': 'Absent Summary',
    'Upcoming Leaves': 'Upcoming Leaves',
    'Dashboard': 'Dashboard',
    'Menu Planner': 'Menu Planner',
    'Students': 'Students',
    'Analytics': 'Analytics',
    'Settings': 'Settings',
  },
  'hi': {
    'Live Headcount': 'आज की गिनती (Live)',
    'Absent Summary': 'छुट्टी का ब्यौरा',
    'Upcoming Leaves': 'आने वाली छुट्टियां',
    'Dashboard': 'डैशबोर्ड',
    'Menu Planner': 'मेन्यू प्लानर',
    'Students': 'विद्यार्थी',
    'Analytics': 'एनालिटिक्स',
    'Settings': 'सेटिंग्स',
  },
};

extension LocalizationExtension on String {
  String tr(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localizationProvider);
    return _translations[lang]?[this] ?? this;
  }
}
