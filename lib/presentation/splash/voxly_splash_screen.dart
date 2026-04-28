import 'dart:async';

import 'package:flutter/material.dart';

import '../../features/learning/presentation/screens/home_screen.dart';

class VoxlySplashScreen extends StatefulWidget {
  const VoxlySplashScreen({super.key});

  @override
  State<VoxlySplashScreen> createState() => _VoxlySplashScreenState();
}

class _VoxlySplashScreenState extends State<VoxlySplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  bool _showGradient = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    final CurvedAnimation curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(curved);
    _scaleAnimation = Tween<double>(begin: 0.92, end: 1).animate(curved);

    _startAnimationAndNavigate();
  }

  Future<void> _startAnimationAndNavigate() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

    unawaited(_controller.forward());

    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() {
      _showGradient = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 350),
        transitionsBuilder: (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 380),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child:
                _showGradient
                    ? Container(
                      key: const ValueKey<String>('gradient-background'),
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/splash/background.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                    : const ColoredBox(
                      key: ValueKey<String>('black-background'),
                      color: Colors.black,
                    ),
          ),
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Image.asset('assets/icon/app_icon.png', width: 140),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
