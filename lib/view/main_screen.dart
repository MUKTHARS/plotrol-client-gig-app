import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plotrol/controller/bottom_navigation_controller.dart';
import 'package:plotrol/view/home_screen.dart';
import 'package:plotrol/view/view_all_orders_screen.dart';
import 'package:plotrol/view/profile.dart';

import 'add_your_properties.dart';

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
            fontWeight: FontWeight.w700, 
            fontFamily: 'Raleway',
            color: Color(0xFF1C1510), // _espresso color
          ),
        ),
        backgroundColor: const Color(0xFFF7F3EE), // _cream color
        elevation: 0,
        foregroundColor: const Color(0xFF1C1510),
      ),
        body: widgetOptionsPlotRol[controller.selectedIndex.value],
        bottomNavigationBar: BottomNavigationBar(
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(
            fontFamily: 'Raleway',
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Raleway',
          ),
          currentIndex: controller.selectedIndex.value,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
                icon: Icon(
                  Icons.home,
                  size: 25,
                ),
                label: 'Home',
                backgroundColor: Colors.white),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.date_range,
                size: 20,
              ),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.add,
                size: 20,
              ),
              label: 'Properties',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.person,
                size: 20,
              ),
              label: 'Profile',
            ),
          ],
          backgroundColor: Colors.white,
          iconSize: 40,
          elevation: 5,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.black,
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
