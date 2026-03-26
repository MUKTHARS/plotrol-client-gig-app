import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../globalWidgets/custom_scaffold_widget.dart';
import '../globalWidgets/text_widget.dart';
import 'home_screen.dart';

class OngoingTaskScreen extends StatelessWidget {
  const OngoingTaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      body: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          title: const ReusableTextWidget(
            text: 'Ongoing Tasks',
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
                status: 'created',
              )),
        ),
      ),
    );
  }
}
