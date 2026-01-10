import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:plotrol/view/welcome_login.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';
import 'package:sizer/sizer.dart';
import '../controller/autentication_controller.dart';
import '../globalWidgets/text_widget.dart';
import '../helper/const_ui_strings.dart';

class OnBoardPage extends StatelessWidget {
  final AuthenticationController authenticationController = Get.put(AuthenticationController());

  OnBoardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context,orientation,deviceType) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text(''),
            backgroundColor: Colors.white,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/native_splash.png',
                      height: 40,
                      width: 40,
                    ),
                    const SizedBox(width: 5,),
                    const ReusableTextWidget(
                      text: 'PLOTROL',
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ],
                ),
                SizedBox(height: 5.h),
                Column(
                  children: [
                    SizedBox(
                      height: Get.height * 0.4,
                      child: Swiper(
                        allowImplicitScrolling: true,
                        itemBuilder: (BuildContext context, int index) {
                          List<String> lotties = [
                            // 'assets/images/labour_lottie.json',
                            // 'assets/images/grass_clean.json',
                            'assets/images/relaz_lottie.json',
                          ];
                          return Lottie.asset(lotties[index]);
                        },
                        itemCount: 1,  // Set the number of items to 3
                        viewportFraction: 0.8,
                        scale: 0.9,
                        loop: false,
                        onIndexChanged: (value) {
                          authenticationController.selectedIndex.value = value;
                        },
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Obx(() {
                      int index = authenticationController.selectedIndex.value;
                      return Column(
                        children: [
                          ReusableTextWidget(
                              text: ConstUiStrings.getIntroScreenText[index],
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,

                          ),
                          SizedBox(height: 1.h),
                          ReusableTextWidget(
                            text: ConstUiStrings.getIntroScreenDescription[index],
                            fontSize: 12.sp,
                            textAlign: TextAlign.center,
                            maxLines: 3,
                          ),
                        ],
                      );
                    }),
                  ],
                ),
                SizedBox(height: 2.h),
                Obx(() {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(1, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        width: authenticationController.selectedIndex.value == index ? 70 : 30,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(10),
                          color: authenticationController.selectedIndex.value == index
                              ? Colors.black
                              : Colors.grey,
                        ),
                      );
                    }),
                  );
                },
                ),
                SizedBox(height: 4.h,),
              ],
            ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: EdgeInsets.only(left: 2.h, right: 2.h, bottom: 1.h),
              child: Row(
                children: [
                  Expanded(
                    child: RoundedLoadingButton(
                      color: Colors.black,
                      controller: authenticationController.introBtnController,
                      onPressed: () {
                        authenticationController.introBtnController.reset();
                        Get.to(() => WelcomeLogin());
                      },
                      borderRadius: 10,
                      child: const ReusableTextWidget(
                        text: 'Get Started',
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}



