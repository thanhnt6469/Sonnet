import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return PopupMenuButton<String>(
          icon: const Icon(
            Icons.language,
            color: Colors.white,
            size: 24,
          ),
          onSelected: (String languageCode) {
            languageProvider.changeLanguage(languageCode);
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<String>(
              value: 'en',
              child: Row(
                children: [
                  const Text('🇺🇸'),
                  const SizedBox(width: 8),
                  Text(
                    languageProvider.getLanguageName('en'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (languageProvider.currentLocale.languageCode == 'en')
                    const Spacer(),
                  if (languageProvider.currentLocale.languageCode == 'en')
                    const Icon(Icons.check, color: Colors.green),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'vi',
              child: Row(
                children: [
                  const Text('🇻🇳'),
                  const SizedBox(width: 8),
                  Text(
                    languageProvider.getLanguageName('vi'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (languageProvider.currentLocale.languageCode == 'vi')
                    const Spacer(),
                  if (languageProvider.currentLocale.languageCode == 'vi')
                    const Icon(Icons.check, color: Colors.green),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
} 