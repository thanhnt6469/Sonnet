import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'l10n/app_localizations.dart';
import 'widgets/language_selector.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback showPromptScreen;
  const HomeScreen({super.key, required this.showPromptScreen});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF330000), Color(0xFF000000)],
          ),
        ),
        child: Stack(
          children: [
            Transform.translate(
              offset: const Offset(0, 30),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Stack(
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width,
                            decoration: const BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage("assets/images/sonnet.png"),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 40.0),
                              child: Container(
                                padding: const EdgeInsets.all(5.0),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFFFFFFFF),
                                    width: 0.4,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Container(
                                  height: 110.0,
                                  width: 110.0,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFFFFFF),
                                    shape: BoxShape.circle,
                                    image: DecorationImage(
                                      image: AssetImage("assets/images/sonnetlogo.png"),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 15.0),
                        child: Column(
                          children: [
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: GoogleFonts.inter(height: 1.3),
                                children: [
                                  TextSpan(
                                    text: '${l10n.get('ai_curated_music')} \n',
                                    style: const TextStyle(
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.w300,
                                      color: Color(0xFFFFFFFF),
                                    ),
                                  ),
                                  TextSpan(
                                    text: l10n.get('get_started_now'),
                                    style: const TextStyle(
                                      height: 1.5,
                                      fontSize: 20.0,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFFFFFFF),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 20.0),
                              child: GestureDetector(
                                onTap: widget.showPromptScreen,
                                child: Container(
                                  padding: const EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFCCCC).withOpacity(0.3),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Container(
                                    height: 50.0,
                                    width: 50.0,
                                    padding: const EdgeInsets.all(2.0),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFFFFFF),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.arrow_forward),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Positioned(
              top: 30.0,
              right: 20.0,
              child: LanguageSelector(),
            ),
          ],
        ),
      ),
    );
  }
}
