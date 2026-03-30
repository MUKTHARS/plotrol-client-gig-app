import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plotrol/controller/bottom_navigation_controller.dart';
import 'package:plotrol/view/home_screen.dart';
import 'package:plotrol/view/view_all_orders_screen.dart';
import 'package:plotrol/view/profile.dart';

import 'add_your_properties.dart';

// ── Design tokens (matching home screen) ────────────────────────────────────
const _cream = Color(0xFFF7F3EE);
const _espresso = Color(0xFF1C1510);
const _sienna = Color(0xFFB85C38);
// ─────────────────────────────────────────────────────────────────────────────

class HomeView extends StatelessWidget {
  final int selectedIndex;

  HomeView({super.key, required this.selectedIndex});

  final BottomNavigationController controller =
      Get.put(BottomNavigationController());

  @override
  Widget build(BuildContext context) {

    final List<Widget> widgetOptionsPlotRol = _widgetOptionsNearle();

    return GetX<BottomNavigationController>(initState: (_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (controller.selectedIndex.value != selectedIndex) {
          controller.selectedIndex.value = selectedIndex;
        }
      });
    }, builder: (controller) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(
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
        ),
        body: widgetOptionsPlotRol[controller.selectedIndex.value],
        bottomNavigationBar: BottomNavigationBar(
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(
            fontFamily: 'Raleway',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Raleway',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
          currentIndex: controller.selectedIndex.value,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(
                Icons.home,
                size: 22,
              ),
              label: 'Home',
              backgroundColor: Colors.white,
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.date_range,
                size: 22,
              ),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.add,
                size: 22,
              ),
              label: 'Properties',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.person,
                size: 22,
              ),
              label: 'Profile',
            ),
          ],
          backgroundColor: Colors.white,
          iconSize: 22,
          elevation: 5,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: _sienna,
          unselectedItemColor: _espresso.withOpacity(0.5),
          onTap: controller.onTapped,
        ),
      );
    });
  }

  List<Widget> _widgetOptionsNearle() => <Widget>[
        HomeScreen(),
        ViewAllOrdersScreen(isFromNavigation: true),
        AddYourProperties(),
        Profile(),
      ];
}