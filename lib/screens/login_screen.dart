import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService auth = context.watch<AuthService>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            children: <Widget>[
              const Spacer(),
              Image.asset(
                'assets/images/logo.jpg',
                width: 96,
                height: 96,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.auto_awesome,
                  size: 72,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Welcome to OleksandrAi',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Chat, experiments, learning and more — in one app.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
              const Spacer(),
              if (auth.error != null) ...<Widget>[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Text(
                    auth.error!,
                    style: const TextStyle(
                      color: Color(0xFFB91C1C),
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed:
                      auth.busy ? null : () => auth.signInWithGoogle(),
                  icon: auth.busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const _GoogleGlyph(),
                  label: Text(
                    auth.busy ? 'Signing in…' : 'Continue with Google',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Colors.black,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'By continuing you agree to our Terms and Privacy Policy.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    // Lightweight Google "G" rendered with shapes so no extra asset is needed.
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Paint paint = Paint()..style = PaintingStyle.fill;
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.6, 1.6, true, paint);
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 1.0, 1.6, true, paint);
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 2.6, 1.5, true, paint);
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, 4.1, 1.6, true, paint);
    // Center punch + bar
    paint.color = Colors.white;
    canvas.drawCircle(size.center(Offset.zero), size.width * 0.28, paint);
    paint.color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width * 0.70, size.height * 0.55),
        width: size.width * 0.35,
        height: size.height * 0.14,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
