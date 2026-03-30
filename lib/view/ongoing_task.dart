import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/home_screen_controller.dart';
import '../Helper/Logger.dart';
import '../globalWidgets/custom_scaffold_widget.dart';
import '../globalWidgets/text_widget.dart';
import 'home_screen.dart';

// ── Design tokens (matching home screen) ────────────────────────────────────
const _cream = Color(0xFFF7F3EE);
const _espresso = Color(0xFF1C1510);
const _sienna = Color(0xFFB85C38);
const _dividerLine = Color(0xFFDDD5C8);
// ─────────────────────────────────────────────────────────────────────────────

class OngoingTaskScreen extends StatefulWidget {
  const OngoingTaskScreen({super.key});

  @override
  State<OngoingTaskScreen> createState() => _OngoingTaskScreenState();
}

class _OngoingTaskScreenState extends State<OngoingTaskScreen> {
  final HomeScreenController homeController = Get.put(HomeScreenController());

  @override
  void initState() {
    super.initState();
    // Ensure role flags (isGigWorker, isPGRAdmin) are populated.
    // GigHomeScreen never calls getDetails(), so we do it here.
    homeController.getDetails();
    logger.i('[OngoingTaskScreen] initState — calling getDetails() to load role flags');
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isGigOrAdmin =
          homeController.isGigWorker.value || homeController.isPGRAdmin.value;
      final taskStatus = isGigOrAdmin ? 'completed' : 'created';
      final screenTitle = isGigOrAdmin ? 'Completed Tasks' : 'Ongoing Tasks';

      logger.i('[OngoingTaskScreen] build — isGigWorker=${homeController.isGigWorker.value}, isPGRAdmin=${homeController.isPGRAdmin.value} → status=$taskStatus, title=$screenTitle');

      return CustomScaffold(
        body: Scaffold(
          backgroundColor: _cream,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: _cream,
            elevation: 0,
            title: Text(
              screenTitle,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: _espresso,
                letterSpacing: -0.8,
                height: 1.0,
              ),
            ),
          ),
          body: Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: SizedBox(
              width: Get.width,
              child: OnGoingTask(
                isVerticalScrollable: true,
                isForStatusScreen: true,
                status: taskStatus,
              ),
            ),
          ),
        ),
      );
    });
  }
}