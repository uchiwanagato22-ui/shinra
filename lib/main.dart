import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'services/firestore_service.dart';
import 'screens/chat_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ShinraApp());
}

class ShinraApp extends StatelessWidget {
  const ShinraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shinra.IA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF07090F),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE1233D),
          secondary: Color(0xFFD4AF37),
          surface: Color(0xFF0B0E18),
        ),
        textTheme: GoogleFonts.rajdhaniTextTheme(
          ThemeData.dark().textTheme,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

/// Redirige automatiquement vers Login ou vers le Chat selon l'état de
/// connexion Firebase. C'est le seul endroit où l'app "décide" si on est
/// identifié ou non.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF07090F),
            body: Center(child: CircularProgressIndicator(color: Color(0xFFE1233D))),
          );
        }
        if (snapshot.hasData) {
          FirestoreService.ensureUserProfile();
          return const ChatScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
