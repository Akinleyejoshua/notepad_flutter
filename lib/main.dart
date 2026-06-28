import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/note_provider.dart';
import 'providers/ui_provider.dart';
import 'widgets/global_overlay.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NotepadApp());
}

class NotepadApp extends StatelessWidget {
  const NotepadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotesProvider()),
        ChangeNotifierProvider(create: (_) => UiProvider()),
      ],
      child: MaterialApp(
        title: 'Voice Notepad',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', 'US'),
        ],
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF111111),
            brightness: Brightness.light,
            surface: const Color(0xFFF9FAFB),
          ),
          scaffoldBackgroundColor: const Color(0xFFF9FAFB),
          fontFamily: 'Bricolage',
        ),
        home: const GlobalOverlay(
          child: CustomSplashScreen(),
        ),
      ),
    );
  }
}