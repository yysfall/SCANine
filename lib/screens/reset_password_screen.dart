import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    final password = _passwordCtrl.text;
    final confirmPassword = _confirmPasswordCtrl.text;

    if (password.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        _error = 'Please fill in both fields.';
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _error = 'Password must be at least 6 characters.';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _error = 'Passwords do not match.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          password: password,
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully!'),
        ),
      );

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (route) => false,
      );
    } on AuthException catch (e) {
      setState(() {
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _error = 'Something went wrong. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primaryDark,
                ],
              ),
            ),
            child: Row(
              children: [
                const ScanRingIcon(),
                const SizedBox(width: 8),
                Text(
                  'SCANine',
                  style: AppText.display(
                    size: 22,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RESET PASSWORD',
                    style: AppText.eyebrow(),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Create a new password',
                    style: AppText.display(size: 22),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Enter a new password for your SCANine account.',
                    style: AppText.muted(size: 13),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'New Password',
                    style: AppText.body(
                      size: 12,
                      w: FontWeight.w600,
                      color: AppColors.inkSoft,
                    ),
                  ),

                  const SizedBox(height: 6),

                  TextField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    'Confirm Password',
                    style: AppText.body(
                      size: 12,
                      w: FontWeight.w600,
                      color: AppColors.inkSoft,
                    ),
                  ),

                  const SizedBox(height: 6),

                  TextField(
                    controller: _confirmPasswordCtrl,
                    obscureText: _obscureConfirm,
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirm = !_obscureConfirm;
                          });
                        },
                      ),
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: AppColors.alert,
                        fontSize: 12,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _updatePassword,
                      child: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Update Password'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}