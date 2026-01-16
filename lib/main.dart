import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';
import 'dashboard.dart';
import 'screens/onboarding_screen.dart';
import 'screens/admin_dashboard.dart';
import 'services/firestore_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
    runApp(const MoneyMind());
}


class MoneyMind extends StatelessWidget {
  // Allow tests to inject a pre-determined current user to avoid calling
  // FirebaseAuth during unit/widget tests which don't initialize plugins.
  final User? currentUser;
  // If true, do not access FirebaseAuth.instance (useful for tests that don't
  // initialize Firebase).
  final bool skipAuth;

  const MoneyMind({super.key, this.currentUser, this.skipAuth = false});

  @override
  Widget build(BuildContext context) {
    final user =
        currentUser ?? (skipAuth ? null : FirebaseAuth.instance.currentUser);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MoneyMind AI',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF6366F1), // Indigo
          secondary: const Color(0xFF8B5CF6), // Purple
          surface: const Color(0xFF1E1E2E), // Dark surface
          error: const Color(0xFFEF4444),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.white,
          onError: Colors.white,
          surfaceContainerHighest: const Color(0xFF2D2D3A),
          onSurfaceVariant: Colors.grey[400]!,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF1E1E2E),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E1E2E),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1E1E2E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[800]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[800]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
          ),
          labelStyle: TextStyle(color: Colors.grey[400]),
          hintStyle: TextStyle(color: Colors.grey[600]),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        dividerTheme: DividerThemeData(
          color: Colors.grey[800],
          thickness: 1,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: user == null ? const LoginScreen() : const HomeRouter(),
    );
  }
}

class HomeRouter extends StatelessWidget {
  const HomeRouter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          // If there's an error (e.g. network, missing db), sign out and go to login
          // to prevent getting stuck in a loading loop.
          FirebaseAuth.instance.signOut();
          return const LoginScreen();
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const LoginScreen();
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final role = userData['role'] ?? 'student';

        if (role == 'admin') {
          return const AdminDashboard();
        }

        // If student, check onboarding
        return FutureBuilder<bool>(
          future: FirestoreService().hasCompletedOnboarding(),
          builder: (context, onboardSnap) {
            if (onboardSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final hasOnboarded = onboardSnap.data ?? false;
            return hasOnboarded ? const Dashboard() : const OnboardingScreen();
          },
        );
      },
    );
  }
}
