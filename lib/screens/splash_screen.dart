import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import 'auth/login_screen.dart';
import 'main_nav_screen.dart';
import 'dart:ui';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotateController;
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late AnimationController _ringController;
  late AnimationController _particleController;

  late Animation<double> _rotateAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _glowAnim;
  late Animation<double> _ringAnim;
  late Animation<double> _particleAnim;

  @override
  void initState() {
    super.initState();

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _rotateAnim = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.linear),
    );

    _pulseAnim = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    _glowAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOutSine),
    );

    _ringAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeInOutSine),
    );

    _particleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.easeInOutSine),
    );

    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.initAuth();
    await Future.delayed(const Duration(seconds: 4));
    if (!mounted) return;

    if (authProvider.isAuthenticated) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainNavScreen(),
          transitionDuration: const Duration(milliseconds: 800),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(
            opacity: anim,
            child: child,
          ),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const LoginScreen(),
          transitionDuration: const Duration(milliseconds: 800),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(
            opacity: anim,
            child: child,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _rotateController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    _ringController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: Stack(
        children: [
          // ── Layer 1: Deep ambient background gradient ──
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.4,
                  colors: [
                    Color(0xFF1A1200),
                    Color(0xFF0A0800),
                    Color(0xFF050505),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // ── Layer 2: Huge outer ambient glow (bottom) ──
          AnimatedBuilder(
            animation: _glowAnim,
            builder: (_, __) => Positioned(
              bottom: -size.height * 0.2,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: size.width * 1.5,
                  height: size.width * 1.5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFFD700).withOpacity(0.08 * _glowAnim.value),
                        const Color(0xFFB8860B).withOpacity(0.04 * _glowAnim.value),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Layer 3: Top aurora glow ──
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Positioned(
              top: -size.height * 0.15,
              left: size.width * 0.1,
              right: size.width * 0.1,
              child: Container(
                height: size.height * 0.45,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFD4AF37).withOpacity(0.12 * _pulseAnim.value),
                      const Color(0xFFFFD700).withOpacity(0.05 * _pulseAnim.value),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Layer 4: Floating particles ──
          AnimatedBuilder(
            animation: _particleAnim,
            builder: (_, __) => Positioned.fill(
              child: CustomPaint(
                painter: _ParticlePainter(_particleAnim.value, _rotateAnim.value),
              ),
            ),
          ),

          // ── Layer 5: Rotating outer shimmer ring ──
          AnimatedBuilder(
            animation: Listenable.merge([_rotateAnim, _ringAnim]),
            builder: (_, __) => Positioned.fill(
              child: Center(
                child: Transform.rotate(
                  angle: _rotateAnim.value,
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFFD700).withOpacity(0.15 * _ringAnim.value),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Layer 6: Rotating middle ring (opposite direction) ──
          AnimatedBuilder(
            animation: _rotateAnim,
            builder: (_, __) => Positioned.fill(
              child: Center(
                child: Transform.rotate(
                  angle: -_rotateAnim.value * 0.6,
                  child: _DashedRing(
                    radius: 220,
                    dashCount: 24,
                    color: const Color(0xFFD4AF37).withOpacity(0.25),
                    dashWidth: 12,
                    strokeWidth: 1.5,
                  ),
                ),
              ),
            ),
          ),

          // ── Layer 7: Inner rotating ring ──
          AnimatedBuilder(
            animation: _rotateAnim,
            builder: (_, __) => Positioned.fill(
              child: Center(
                child: Transform.rotate(
                  angle: _rotateAnim.value * 1.4,
                  child: _DashedRing(
                    radius: 168,
                    dashCount: 16,
                    color: const Color(0xFFFFD700).withOpacity(0.3),
                    dashWidth: 8,
                    strokeWidth: 1.2,
                  ),
                ),
              ),
            ),
          ),

          // ── Layer 8: Central pulsing glow orb ──
          AnimatedBuilder(
            animation: Listenable.merge([_pulseAnim, _glowAnim]),
            builder: (_, __) => Positioned.fill(
              child: Center(
                child: Transform.scale(
                  scale: _pulseAnim.value,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFFFD700).withOpacity(0.18 * _glowAnim.value),
                          const Color(0xFFB8860B).withOpacity(0.10 * _glowAnim.value),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(0.25 * _glowAnim.value),
                          blurRadius: 80,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Layer 9: Glassmorphism logo container ──
          Positioned.fill(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ─── Logo container with glow ring ───
                  AnimatedBuilder(
                    animation: Listenable.merge([_glowAnim, _pulseAnim]),
                    builder: (_, child) => Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF1E1600).withOpacity(0.9),
                            const Color(0xFF0A0800).withOpacity(0.95),
                          ],
                        ),
                        border: Border.all(
                          color: const Color(0xFFFFD700)
                              .withOpacity(0.5 + 0.3 * _glowAnim.value),
                          width: 1.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700)
                                .withOpacity(0.35 * _glowAnim.value),
                            blurRadius: 40 + 20 * _pulseAnim.value,
                            spreadRadius: 4 + 4 * _pulseAnim.value,
                          ),
                          BoxShadow(
                            color: const Color(0xFFD4AF37)
                                .withOpacity(0.15 * _glowAnim.value),
                            blurRadius: 80,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: child,
                    ),
                    child: ClipOval(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Center(
                          child: Image.asset(
                            'assets/images/GoldBarPay.png',
                            width: 78,
                            height: 78,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  )
                  .animate()
                  .scale(
                    duration: 900.ms,
                    delay: 300.ms,
                    begin: const Offset(0.3, 0.3),
                    end: const Offset(1.0, 1.0),
                    curve: Curves.elasticOut,
                  )
                  .fadeIn(duration: 600.ms, delay: 300.ms),

                  const SizedBox(height: 40),

                  // ─── Brand name ───
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                        Color(0xFFFFE066),
                        Color(0xFFFFD700),
                        Color(0xFFD4AF37),
                        Color(0xFFB8860B),
                        Color(0xFFD4AF37),
                        Color(0xFFFFD700),
                        Color(0xFFFFE066),
                      ],
                      stops: [0.0, 0.15, 0.35, 0.5, 0.65, 0.85, 1.0],
                    ).createShader(bounds),
                    child: Text(
                      'GOLD SAVINGS',
                      style: GoogleFonts.lexend(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 7,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 800.ms, duration: 700.ms)
                  .slideY(
                    begin: 0.4,
                    end: 0,
                    delay: 800.ms,
                    duration: 700.ms,
                    curve: Curves.easeOutCubic,
                  ),

                  const SizedBox(height: 10),

                  // ─── Tagline ───
                  Text(
                    'PREMIUM PLATFORM',
                    style: GoogleFonts.lexend(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 5,
                      color: const Color(0xFFD4AF37).withOpacity(0.7),
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 1200.ms, duration: 600.ms)
                  .slideY(
                    begin: 0.3,
                    end: 0,
                    delay: 1200.ms,
                    duration: 600.ms,
                    curve: Curves.easeOutCubic,
                  ),

                  const SizedBox(height: 28),

                  // ─── Horizontal gold divider ───
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _GoldDividerDot(),
                      const SizedBox(width: 6),
                      Container(
                        width: 70,
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              const Color(0xFFFFD700).withOpacity(0.8),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFFFD700),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 70,
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFFFD700).withOpacity(0.8),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _GoldDividerDot(),
                    ],
                  )
                  .animate()
                  .fadeIn(delay: 1500.ms, duration: 700.ms)
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1.0, 1.0),
                    delay: 1500.ms,
                    duration: 700.ms,
                    curve: Curves.easeOutBack,
                  ),
                ],
              ),
            ),
          ),

          // ── Loading dots at bottom ──
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                _AnimatedLoadingDots(),
                const SizedBox(height: 16),
                Text(
                  'Securing your wealth...',
                  style: GoogleFonts.lexend(
                    fontSize: 11,
                    color: const Color(0xFFD4AF37).withOpacity(0.45),
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w400,
                  ),
                )
                .animate()
                .fadeIn(delay: 2000.ms, duration: 800.ms),
              ],
            ),
          ),

          // ── Corner decorations ──
          Positioned(
            top: 50,
            left: 30,
            child: _CornerOrnament(flip: false)
                .animate()
                .fadeIn(delay: 1800.ms, duration: 600.ms)
                .scale(
                  begin: const Offset(0.0, 0.0),
                  end: const Offset(1.0, 1.0),
                  delay: 1800.ms,
                  duration: 600.ms,
                  curve: Curves.easeOutBack,
                ),
          ),
          Positioned(
            top: 50,
            right: 30,
            child: _CornerOrnament(flip: true)
                .animate()
                .fadeIn(delay: 1900.ms, duration: 600.ms)
                .scale(
                  begin: const Offset(0.0, 0.0),
                  end: const Offset(1.0, 1.0),
                  delay: 1900.ms,
                  duration: 600.ms,
                  curve: Curves.easeOutBack,
                ),
          ),
          Positioned(
            bottom: 130,
            left: 30,
            child: Transform.rotate(
              angle: math.pi,
              child: _CornerOrnament(flip: true),
            )
                .animate()
                .fadeIn(delay: 2000.ms, duration: 600.ms)
                .scale(
                  begin: const Offset(0.0, 0.0),
                  end: const Offset(1.0, 1.0),
                  delay: 2000.ms,
                  duration: 600.ms,
                  curve: Curves.easeOutBack,
                ),
          ),
          Positioned(
            bottom: 130,
            right: 30,
            child: Transform.rotate(
              angle: math.pi,
              child: _CornerOrnament(flip: false),
            )
                .animate()
                .fadeIn(delay: 2100.ms, duration: 600.ms)
                .scale(
                  begin: const Offset(0.0, 0.0),
                  end: const Offset(1.0, 1.0),
                  delay: 2100.ms,
                  duration: 600.ms,
                  curve: Curves.easeOutBack,
                ),
          ),
        ],
      ),
    );
  }
}

// ─── Dashed Ring Painter ───────────────────────────────────────────────────
class _DashedRing extends StatelessWidget {
  final double radius;
  final int dashCount;
  final Color color;
  final double dashWidth;
  final double strokeWidth;

  const _DashedRing({
    required this.radius,
    required this.dashCount,
    required this.color,
    required this.dashWidth,
    required this.strokeWidth,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: radius,
      height: radius,
      child: CustomPaint(
        painter: _DashedRingPainter(
          dashCount: dashCount,
          color: color,
          dashWidth: dashWidth,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _DashedRingPainter extends CustomPainter {
  final int dashCount;
  final Color color;
  final double dashWidth;
  final double strokeWidth;

  _DashedRingPainter({
    required this.dashCount,
    required this.color,
    required this.dashWidth,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final angleStep = 2 * math.pi / dashCount;
    final dashAngle = dashWidth / radius;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * angleStep;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedRingPainter old) => false;
}

// ─── Particle Painter ─────────────────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final double progress;
  final double rotation;

  _ParticlePainter(this.progress, this.rotation);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final paint = Paint()..style = PaintingStyle.fill;

    final positions = [
      [0.18, -0.25, 3.0, 0.6],
      [-0.22, -0.18, 2.0, 0.4],
      [0.30, 0.10, 2.5, 0.5],
      [-0.28, 0.22, 1.8, 0.35],
      [0.12, 0.32, 2.2, 0.45],
      [-0.15, -0.35, 2.8, 0.55],
      [0.38, -0.08, 1.5, 0.3],
      [-0.35, 0.05, 2.0, 0.4],
      [0.05, -0.38, 2.3, 0.48],
      [-0.08, 0.35, 1.6, 0.32],
    ];

    for (int i = 0; i < positions.length; i++) {
      final p = positions[i];
      final angle = rotation * (i.isEven ? 1 : -1) + i * 0.628;
      final r = 130.0 + i * 10.0;
      final x = cx + r * math.cos(angle) * 0.9;
      final y = cy + r * math.sin(angle) * 0.9;
      final alpha = ((0.2 + 0.8 * progress) * (p[3] as double)).clamp(0.0, 1.0);

      paint.color = const Color(0xFFFFD700).withOpacity(alpha);
      canvas.drawCircle(Offset(x, y), p[2] as double, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) =>
      old.progress != progress || old.rotation != rotation;
}

// ─── Gold Divider Dot ─────────────────────────────────────────────────────
class _GoldDividerDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFD4AF37).withOpacity(0.5),
      ),
    );
  }
}

// ─── Corner Ornament ──────────────────────────────────────────────────────
class _CornerOrnament extends StatelessWidget {
  final bool flip;
  const _CornerOrnament({required this.flip});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scaleX: flip ? -1 : 1,
      child: SizedBox(
        width: 40,
        height: 40,
        child: CustomPaint(painter: _CornerPainter()),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4AF37).withOpacity(0.45)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, 0)
      ..lineTo(0, size.height);

    canvas.drawPath(path, paint);

    // Small diamond
    final dp = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.6)
      ..style = PaintingStyle.fill;
    final c = Offset(0, 0);
    canvas.drawCircle(c, 2.5, dp);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}

// ─── Animated Loading Dots ────────────────────────────────────────────────
class _AnimatedLoadingDots extends StatefulWidget {
  @override
  State<_AnimatedLoadingDots> createState() => _AnimatedLoadingDotsState();
}

class _AnimatedLoadingDotsState extends State<_AnimatedLoadingDots>
    with TickerProviderStateMixin {
  final List<AnimationController> _controllers = [];
  final List<Animation<double>> _anims = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 5; i++) {
      final c = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900),
      );
      final a = Tween<double>(begin: 0.2, end: 1.0).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOutSine),
      );
      _controllers.add(c);
      _anims.add(a);
      Future.delayed(Duration(milliseconds: i * 160), () {
        if (mounted) c.repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        return AnimatedBuilder(
          animation: _anims[i],
          builder: (_, __) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == 2 ? 10 : 6,
            height: i == 2 ? 10 : 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFD700).withOpacity(_anims[i].value),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700)
                      .withOpacity(0.5 * _anims[i].value),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      }),
    )
    .animate()
    .fadeIn(delay: 1800.ms, duration: 700.ms);
  }
}
