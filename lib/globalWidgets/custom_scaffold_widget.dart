import 'package:flutter/material.dart';

// ── Design tokens (matching home screen) ────────────────────────────────────
const _cream = Color(0xFFF7F3EE);
const _espresso = Color(0xFF1C1510);
const _dividerLine = Color(0xFFDDD5C8);
// ─────────────────────────────────────────────────────────────────────────────

class CustomScaffold extends StatelessWidget {
  final Widget body; // This will be the body of the Scaffold (the main content of each screen)
  final bool automaticallyImplyLeading;
  final Widget? customTitle; // Optional custom title widget
  final List<Widget>? actions; // Optional actions for AppBar
  final PreferredSizeWidget? bottom; // Optional bottom widget (for TabBar)
  final Widget? bottomNavigationBar; // Optional bottom navigation bar

  const CustomScaffold({
    super.key,
    required this.body,
    this.automaticallyImplyLeading = false, // Optional parameter to control the leading behavior
    this.customTitle, // Optional custom title
    this.actions, // Optional actions
    this.bottom, // Optional bottom (TabBar)
    this.bottomNavigationBar, // Optional bottom navigation bar
  });

  @override

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: automaticallyImplyLeading,
        title: customTitle ?? const Text(
          'Plot Patrol - Beta',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            fontFamily: 'Raleway',
            color: _espresso,
            letterSpacing: -0.8,
            height: 1.1,
          ),
        ),
        backgroundColor: _cream,
        elevation: 0,
        foregroundColor: _espresso,
        actions: actions,
        bottom: bottom,
      ),
      body: body,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}