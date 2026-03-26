import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/home_screen_controller.dart';
import '../Helper/Logger.dart';
import '../globalWidgets/custom_scaffold_widget.dart';
import '../globalWidgets/text_widget.dart';
import 'home_screen.dart';

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
          backgroundColor: Colors.white,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.white,
            title: ReusableTextWidget(
              text: screenTitle,
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(10),
            child: SizedBox(
                width: Get.width,
                child: OnGoingTask(
                  isVerticalScrollable: true,
                  isForStatusScreen: true,
                  status: taskStatus,
                )),
          ),
        ),
      );
    });
  }
}
