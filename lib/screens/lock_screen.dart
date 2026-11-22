import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';
import 'dashboard_tab.dart';

/// Shown over the app after it was hidden. Unlock with the 4 digit PIN.
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _pin = '';
  bool _checking = false;

  Future<void> _press(String key) async {
    if (_checking) return;
    if (key == 'back') {
      if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
      return;
    }
    if (_pin.length >= 4) return;
    setState(() => _pin += key);
    if (_pin.length == 4) {
      setState(() => _checking = true);
      final ok = await context.read<AuthProvider>().unlock(_pin);
      if (!mounted) return;
      setState(() {
        _checking = false;
        if (!ok) _pin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = firstNameFrom(auth.email);

    return Scaffold(
      backgroundColor: AppColors.midnight,
      body: Stack(
        children: [
          const Positioned(top: -120, right: -80, child: GlowBlob(color: AppColors.primary, size: 340)),
          const Positioned(bottom: -140, left: -100, child: GlowBlob(color: AppColors.purple, size: 360)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(gradient: AppGradients.brand, shape: BoxShape.circle),
                        child: CircleAvatar(
                          radius: 34,
                          backgroundColor: AppColors.midnight,
                          child: Text(name[0],
                              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Welcome back, $name',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text('Enter your PIN to unlock EcoPay',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
                      const SizedBox(height: 28),

                      // PIN dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < 4; i++)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              margin: const EdgeInsets.symmetric(horizontal: 10),
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: i < _pin.length ? AppGradients.brand : null,
                                border: i < _pin.length
                                    ? null
                                    : Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(
                        height: 36,
                        child: Center(
                          child: Text(
                            auth.lockError ?? '',
                            style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),

                      // Keypad
                      for (final row in const [
                        ['1', '2', '3'],
                        ['4', '5', '6'],
                        ['7', '8', '9'],
                        ['', '0', 'back'],
                      ])
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [for (final k in row) _Key(label: k, onTap: () => _press(k))],
                          ),
                        ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => context.read<AuthProvider>().signOut(),
                        child: Text('Not you? Sign out', style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
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

class _Key extends StatelessWidget {
  const _Key({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox(width: 74, height: 74);
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      shape: CircleBorder(side: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 74,
          height: 74,
          child: Center(
            child: label == 'back'
                ? const Icon(Icons.backspace_outlined, color: Colors.white)
                : Text(label,
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }
}
