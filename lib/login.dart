import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard.dart';
import 'screens/onboarding_screen.dart';
import 'screens/admin_dashboard.dart';
import 'services/firestore_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  String email = "", password = "", university = "";
  bool loading = false;
  bool showSignup = false;

  late final AnimationController _logoController;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _logoController.forward();
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  Future<void> _handleAuthSuccess(User user) async {
    print("Auth success for user: ${user.uid}");
    try {
      // 1. Get Role
      print("Fetching user role...");
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        print(
          "User document does not exist. Creating default student profile.",
        );
        await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
          "role": "student",
          "university_id": university,
        });
      }

      final data = userDoc.data();
      final role = data?['role'] ?? 'student';
      print("User role: $role");

      if (!mounted) return;

      if (role == 'admin') {
        print("Navigating to AdminDashboard");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboard()),
        );
      } else {
        // 2. Check Onboarding for Students
        print("Checking onboarding status...");
        final hasOnboarded = await FirestoreService().hasCompletedOnboarding();
        print("Has onboarded: $hasOnboarded");

        if (!mounted) return;

        if (hasOnboarded) {
          print("Navigating to Dashboard");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const Dashboard()),
          );
        } else {
          print("Navigating to OnboardingScreen");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          );
        }
      }
    } catch (e) {
      print("Error in _handleAuthSuccess: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
        setState(() => loading = false);
      }
    }
  }

  Future<void> signup() async {
    setState(() => loading = true);
    try {
      var userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // Default to student
      await FirebaseFirestore.instance
          .collection("users")
          .doc(userCredential.user!.uid)
          .set({"role": "student", "university_id": university});

      await _handleAuthSuccess(userCredential.user!);
    } catch (e) {
      if (e is FirebaseAuthException && e.code == 'email-already-in-use') {
        // Automatically try logging in instead
        print("Email already in use, attempting to login...");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account exists! Logging you in...'),
              backgroundColor: Colors.blue,
            ),
          );
        }
        await login();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Signup failed: $e')));
        }
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> login() async {
    setState(() => loading = true);
    try {
      var userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      await _handleAuthSuccess(userCredential.user!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Login failed: $e')));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: CurvedAnimation(
                    parent: _logoController,
                    curve: Curves.elasticOut,
                  ),
                  child: Hero(
                    tag: 'app-logo',
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 180,
                      height: 180,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback if logo not found
                        return Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF6366F1),
                                const Color(0xFF8B5CF6),
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet,
                            size: 90,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Welcome to MoneyMind',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                AnimatedSize(
                  duration: const Duration(milliseconds: 350),
                  child: Column(
                    children: [
                      TextField(
                        onChanged: (v) => email = v,
                        decoration: const InputDecoration(labelText: "Email"),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        onChanged: (v) => password = v,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Password",
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (showSignup)
                        Column(
                          children: [
                            TextField(
                              onChanged: (v) => university = v,
                              decoration: const InputDecoration(
                                labelText: "University Code",
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (loading)
                  const CircularProgressIndicator()
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: showSignup ? signup : login,
                        child: Text(showSignup ? 'Sign Up' : 'Login'),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: () =>
                            setState(() => showSignup = !showSignup),
                        child: Text(
                          showSignup ? 'Have an account?' : 'Create Account',
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
