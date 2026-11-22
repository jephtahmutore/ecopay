import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../state/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pin = TextEditingController();
  bool _showPin = false;

  @override
  void dispose() {
    _email.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    await context.read<AuthProvider>().signIn(_email.text, _pin.text);
  }

  void _forgotPin() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PIN reset is coming soon. Please contact support.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.midnight,
      body: Stack(
        children: [
          // Glowing colour blobs behind the form
          const Positioned(top: -120, left: -80, child: GlowBlob(color: AppColors.primary, size: 340)),
          const Positioned(bottom: -140, right: -100, child: GlowBlob(color: AppColors.blue, size: 380)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: AppGradients.brand,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: AppShadows.glow(AppColors.cyan),
                          ),
                          child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 34),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'EcoPay',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Send money home, fast and safely',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
                      ),
                      const SizedBox(height: 24),

                      // Login card
                      Glass(
                        radius: 28,
                        child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Welcome back',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink),
                              ),
                              const Text('Log in to your wallet', style: TextStyle(color: AppColors.muted)),
                              const SizedBox(height: 18),
                              TextFormField(
                                key: const Key('email'),
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.email],
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.alternate_email_rounded),
                                ),
                                validator: (v) => AuthService.isValidEmail(v ?? '')
                                    ? null
                                    : 'Enter a valid email address',
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                key: const Key('pin'),
                                controller: _pin,
                                obscureText: !_showPin,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.done,
                                maxLength: 4,
                                onFieldSubmitted: (_) => _submit(),
                                decoration: InputDecoration(
                                  labelText: '4 digit PIN',
                                  counterText: '',
                                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                                  suffixIcon: IconButton(
                                    tooltip: _showPin ? 'Hide PIN' : 'Show PIN',
                                    icon: Icon(_showPin ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                                    onPressed: () => setState(() => _showPin = !_showPin),
                                  ),
                                ),
                                validator: (v) => AuthService.isValidPin(v ?? '')
                                    ? null
                                    : 'Your PIN must be 4 digits',
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    minimumSize: const Size(0, 40),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: _forgotPin,
                                  child: const Text('Forgot PIN?'),
                                ),
                              ),
                              if (auth.error != null) ...[
                                ErrorText(auth.error!),
                                const SizedBox(height: 12),
                              ],
                              GradientButton(
                                key: const Key('signIn'),
                                onPressed: auth.busy ? null : _submit,
                                child: auth.busy ? const ButtonSpinner() : const Text('Sign in'),
                              ),
                            ],
                          ),
                        ),
                      ),
                        ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.verified_user_rounded, size: 16, color: AppColors.mint),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Your session is encrypted on this device',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
