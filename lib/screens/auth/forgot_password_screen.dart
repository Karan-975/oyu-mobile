import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _emailSubmitted = false;
  bool _submitting = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    if (!_emailFormKey.currentState!.validate()) return;
    
    setState(() => _submitting = true);
    await Future.delayed(const Duration(milliseconds: 1000));
    
    if (mounted) {
      setState(() {
        _emailSubmitted = true;
        _submitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('[DEMO MODE] Reset OTP sent to email. Code is 7381.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _resetPassword() async {
    if (!_otpFormKey.currentState!.validate()) return;

    if (_otpCtrl.text.trim() != '7381') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid verification code. Please enter 7381.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_passwordCtrl.text != _confirmPasswordCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    await Future.delayed(const Duration(milliseconds: 1200));

    if (mounted) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully! Please login with your new password.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.navy),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_reset, size: 36, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Reset Password',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _emailSubmitted 
                    ? 'Enter the 4-digit verification code sent to ${_emailCtrl.text} and your new password.'
                    : 'Enter your email address and we\'ll send you a temporary verification code.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted),
              ),
              SizedBox(height: size.height * 0.04),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: !_emailSubmitted ? _buildEmailForm() : _buildOtpForm(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailForm() {
    return Form(
      key: _emailFormKey,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Request OTP',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                hintText: 'name@oyugreen.com',
                prefixIcon: Icon(Icons.mail_outline, size: 19),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _submitting ? null : _requestOtp,
              child: _submitting 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Send Reset OTP'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpForm() {
    return Form(
      key: _otpFormKey,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Set New Password',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy),
            ),
            const SizedBox(height: 16),

            // OTP Code
            TextFormField(
              controller: _otpCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Verification Code (OTP)',
                hintText: 'Enter 4-digit code',
                prefixIcon: Icon(Icons.security, size: 19),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Code is required' : null,
            ),
            const SizedBox(height: 14),

            // New Password
            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'New Password',
                prefixIcon: const Icon(Icons.lock_outline, size: 19),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 19),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                if (v.length < 6) return 'Password must be at least 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Confirm Password
            TextFormField(
              controller: _confirmPasswordCtrl,
              obscureText: _obscure,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: Icon(Icons.lock_outline, size: 19),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Confirm your password';
                return null;
              },
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _submitting ? null : _resetPassword,
              child: _submitting 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Reset Password'),
            ),
            const SizedBox(height: 12),

            TextButton(
              onPressed: () => setState(() => _emailSubmitted = false),
              child: const Text('Back to Email'),
            ),
          ],
        ),
      ),
    );
  }
}
