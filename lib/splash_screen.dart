import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/session_service.dart';
import '../../data/repositories/splash_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// lib/views/Splash/splash_screen.dart
// ─────────────────────────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  late final AnimationController _controller;

  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _taglineOpacity;
  late final Animation<Offset>  _taglineSlide;
  late final Animation<double> _dotsOpacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 1600),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve:  const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
    );
    _logoScale = Tween<double>(begin: 0.80, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve:  const Interval(0.0, 0.50, curve: Curves.easeOutBack),
      ),
    );
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve:  const Interval(0.30, 0.70, curve: Curves.easeOut),
      ),
    );
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end:   Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve:  const Interval(0.30, 0.70, curve: Curves.easeOut),
      ),
    );
    _dotsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve:  const Interval(0.62, 1.0, curve: Curves.easeIn),
      ),
    );

    _initApp();
  }

  Future<void> _initApp() async {
    await Future.wait([
      _controller.forward(),
      _loadData(),
      Future.delayed(const Duration(milliseconds: 2000)),
    ]);
    if (!mounted) return;
    _navigate();
  }

  Future<void> _loadData() async {
    try {
      await Future.wait([
        SplashRepository.loadSessionState(),
        SplashRepository.loadDropdowns(),
      ]);
    } catch (_) {
      // Never crash the splash — screens reload their own data if needed
    }
  }

  void _navigate() {
    final String route;
    if (SplashRepository.cachedIsLoggedIn) {
      route = '/home';
    } else if (!SplashRepository.cachedIsOnboardDone) {
      route = '/onboarding';
    } else {
      route = '/login';
    }
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor:          Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness:     Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFCC247),
        body: SafeArea(
          child: Column(
            children: [
              // ── Logo + tagline (centred) ───────────────────────────────
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (_, child) => Opacity(
                          opacity: _logoOpacity.value,
                          child: Transform.scale(
                            scale: _logoScale.value,
                            child: child,
                          ),
                        ),
                        child: _buildLogo(),
                      ),
                      const SizedBox(height: 20),
                      // Tagline
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (_, child) => FadeTransition(
                          opacity: _taglineOpacity,
                          child: SlideTransition(
                            position: _taglineSlide,
                            child: child,
                          ),
                        ),
                        child: Text(
                          'Smart Fleet. Zero Hassle.',
                          style: TextStyle(
                            fontFamily:  'Manrope',
                            fontSize:    13,
                            fontWeight:  FontWeight.w500,
                            color: const Color(0xFF23262D).withOpacity(0.65),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Loading dots (bottom) ──────────────────────────────────
              AnimatedBuilder(
                animation: _dotsOpacity,
                builder: (_, child) =>
                    Opacity(opacity: _dotsOpacity.value, child: child),
                child: const Padding(
                  padding: EdgeInsets.only(bottom: 48),
                  child:   _LoadingDots(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(

          decoration: BoxDecoration(
            color:        const Color(0xFF23262D),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color:      Colors.black.withOpacity(0.18),
                blurRadius: 24,
                offset:     const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Image.asset(
              'assets/images/filter_logo.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(
                  Icons.car_repair_rounded,
                  color: const Color(0xFFFCC247),
                  size:  52,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Corporate',
          style: TextStyle(
            fontFamily:    'Manrope',
            fontSize:      15,
            fontWeight:    FontWeight.w600,
            color:         Color(0xFF23262D),
            letterSpacing: 3.0,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated loading dots — 3 dots with staggered pulse
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final start = (i * 0.2).clamp(0.0, 1.0);
        final end   = (start + 0.5).clamp(0.0, 1.0);
        final anim  = Tween<double>(begin: 0.3, end: 1.0).animate(
          CurvedAnimation(
            parent: _ctrl,
            curve:  Interval(start, end, curve: Curves.easeInOut),
          ),
        );
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: AnimatedBuilder(
            animation: anim,
            builder: (_, __) => Opacity(
              opacity: anim.value,
              child: Container(
                width:  7,
                height: 7,
                decoration: BoxDecoration(
                  color: const Color(0xFF23262D).withOpacity(0.55),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}