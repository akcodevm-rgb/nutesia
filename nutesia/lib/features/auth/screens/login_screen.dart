import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gap/gap.dart';
import '../../../core/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInAnonymously() async {
    setState(() => _isLoading = true);
    try {
      await _auth.signInAnonymously();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _submitEmailAuth() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter email and password')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.eco, size: 64, color: AppTheme.primary),
                const Gap(16),
                const Text(
                  'Welcome to Nutesia',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const Gap(8),
                Text(
                  _isLogin ? 'Sign in to continue' : 'Create a new account',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const Gap(48),
                TextFormField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Email',
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: AppTheme.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.email, color: Colors.white54),
                  ),
                ),
                const Gap(16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: AppTheme.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.lock, color: Colors.white54),
                  ),
                ),
                const Gap(32),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                else ...[
                  ElevatedButton(
                    onPressed: _submitEmailAuth,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: AppTheme.background,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(_isLogin ? 'Sign In' : 'Sign Up', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const Gap(16),
                  TextButton(
                    onPressed: () => setState(() => _isLogin = !_isLogin),
                    child: Text(_isLogin ? "Don't have an account? Sign Up" : 'Already have an account? Sign In', style: const TextStyle(color: AppTheme.primary)),
                  ),
                  const Gap(24),
                  const Row(
                    children: [
                      Expanded(child: Divider(color: Colors.white24)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('OR', style: TextStyle(color: Colors.white54)),
                      ),
                      Expanded(child: Divider(color: Colors.white24)),
                    ],
                  ),
                  const Gap(24),
                  OutlinedButton.icon(
                    onPressed: _signInAnonymously,
                    icon: const Icon(Icons.person_outline, color: Colors.white),
                    label: const Text('Continue as Guest', style: TextStyle(color: Colors.white)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
