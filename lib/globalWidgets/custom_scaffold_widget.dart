import 'package:flutter/material.dart';

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
            fontWeight: FontWeight.w700,
            fontFamily: 'Raleway',
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0, // Optional: Set elevation to 0 if you want the app bar flat
        foregroundColor: Colors.black, // Optional: Set the text color to black
        actions: actions, // Use custom actions if provided
        bottom: bottom, // Use custom bottom if provided
      ),
      body: body, // This is the content passed to the body of the Scaffold
      bottomNavigationBar: bottomNavigationBar, // Use bottom navigation bar if provided
    );
  }
}
