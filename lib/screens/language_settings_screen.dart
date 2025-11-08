import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/language_provider.dart';
import '../services/translation_service.dart';

class LanguageSettingsScreen extends ConsumerWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(languageProvider);
    final languageNotifier = ref.read(languageProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(t('profile.language')),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // En-tête
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Text(
              t('language.select_language'),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
            ),
          ),

          // Option Français
          _buildLanguageOption(
            context: context,
            locale: const Locale('fr', 'FR'),
            name: 'Français',
            flag: '🇫🇷',
            isSelected: currentLocale.languageCode == 'fr',
            onTap: () {
              languageNotifier.setLanguage(const Locale('fr', 'FR'));
              Navigator.of(context).pop();
            },
          ),

          const SizedBox(height: 12),

          // Option English
          _buildLanguageOption(
            context: context,
            locale: const Locale('en', 'US'),
            name: 'English',
            flag: '🇬🇧',
            isSelected: currentLocale.languageCode == 'en',
            onTap: () {
              languageNotifier.setLanguage(const Locale('en', 'US'));
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required Locale locale,
    required String name,
    required String flag,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Flag emoji
              Text(
                flag,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 16),
              // Language name
              Expanded(
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                ),
              ),
              // Check icon if selected
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

