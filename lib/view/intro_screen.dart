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

// ── Design tokens (matching home screen) ────────────────────────────────────
const _cream = Color(0xFFF7F3EE);
const _parchment = Color(0xFFEFE9DF);
const _sand = Color(0xFFE4DAC8);
const _espresso = Color(0xFF1C1510);
const _walnut = Color(0xFF3D2B1F);
const _sienna = Color(0xFFB85C38);
const _steel = Color(0xFF8C8480);
// ─────────────────────────────────────────────────────────────────────────────

class OnBoardPage extends StatelessWidget {
  final AuthenticationController authenticationController = Get.put(AuthenticationController());

  OnBoardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return Scaffold(
          backgroundColor: _cream,
          appBar: AppBar(
            title: const Text(''),
            backgroundColor: _cream,
            elevation: 0,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  SizedBox(height: 2.h),
                  // Logo Section
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _siennaLight,
                            shape: BoxShape.circle,
                          ),
                          child: Image.asset(
                            'assets/images/native_splash.png',
                            height: 40,
                            width: 40,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'PLOTROL',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: _espresso,
                            letterSpacing: -0.8,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 3.h),
                  // Swiper Section
                  Container(
                    height: Get.height * 0.42,
                    child: Swiper(
                      allowImplicitScrolling: true,
                      itemBuilder: (BuildContext context, int index) {
                        List<String> lotties = [
                          'assets/images/relaz_lottie.json',
                        ];
                        return Container(
                          padding: const EdgeInsets.all(20),
                          child: Lottie.asset(
                            lotties[index],
                            fit: BoxFit.contain,
                          ),
                        );
                      },
                      itemCount: 1,
                      viewportFraction: 0.85,
                      scale: 0.9,
                      loop: false,
                      onIndexChanged: (value) {
                        authenticationController.selectedIndex.value = value;
                      },
                    ),
                  ),
                  SizedBox(height: 2.h),
                  // Text Content Section
                  Obx(() {
                    int index = authenticationController.selectedIndex.value;
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w),
                      child: Column(
                        children: [
                          Text(
                            ConstUiStrings.getIntroScreenText[index],
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: _espresso,
                              letterSpacing: -0.8,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 1.5.h),
                          Text(
                            ConstUiStrings.getIntroScreenDescription[index],
                            style: const TextStyle(
                              fontSize: 14,
                              color: _steel,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 3,
                          ),
                        ],
                      ),
                    );
                  }),
                  SizedBox(height: 3.h),
                  // Page Indicator
                  Obx(() {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(1, (index) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: authenticationController.selectedIndex.value == index ? 40 : 24,
                          height: 6,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: authenticationController.selectedIndex.value == index
                                ? _sienna
                                : _sand,
                          ),
                        );
                      }),
                    );
                  }),
                  SizedBox(height: 6.h),
                ],
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Container(
              padding: EdgeInsets.fromLTRB(6.w, 0, 6.w, 3.h),
              child: Row(
                children: [
                  Expanded(
                    child: RoundedLoadingButton(
                      color: _espresso,
                      controller: authenticationController.introBtnController,
                      onPressed: () {
                        authenticationController.introBtnController.reset();
                        Get.to(() => WelcomeLogin());
                      },
                      borderRadius: 14,
                      child: const Text(
                        'Get Started',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
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

// Add this missing color constant
const _siennaLight = Color(0x1AB85C38);