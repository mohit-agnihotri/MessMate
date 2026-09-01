import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localizationProvider =
    StateNotifierProvider<LocalizationNotifier, String>((ref) {
      return LocalizationNotifier();
    });

class LocalizationNotifier extends StateNotifier<String> {
  LocalizationNotifier() : super('en'); // Default to English

  void toggleLanguage(String lang) {
    state = lang;
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
    'Live Headcount': 'Aaj Ki Ginti (Live)',
    'Absent Summary': 'Chhutti Ka Byora',
    'Upcoming Leaves': 'Aane Wali Chhuttiyan',
    'Dashboard': 'Dashboard',
    'Menu Planner': 'Menu Banayen',
    'Students': 'Vidyarthi',
    'Analytics': 'Analytics',
    'Settings': 'Settings',
  },
};

extension LocalizationExtension on String {
  String tr(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localizationProvider);
    return _translations[lang]?[this] ?? this;
  }
}
