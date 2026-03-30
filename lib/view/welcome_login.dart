import 'package:country_currency_pickers/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plotrol/controller/autentication_controller.dart';
import 'package:plotrol/helper/const_assets_const.dart';
import 'package:plotrol/helper/const_ui_strings.dart';
import 'package:plotrol/view/privacy_and_policy_page.dart';
import 'package:plotrol/view/requester_sign_up.dart';
import 'package:plotrol/view/singup_screen.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';
import 'package:sizer/sizer.dart';
import '../globalWidgets/text_widget.dart';

// ── Design tokens (matching home screen) ────────────────────────────────────
const _cream = Color(0xFFF7F3EE);
const _parchment = Color(0xFFEFE9DF);
const _sand = Color(0xFFE4DAC8);
const _espresso = Color(0xFF1C1510);
const _walnut = Color(0xFF3D2B1F);
const _sienna = Color(0xFFB85C38);
const _siennaLight = Color(0x1AB85C38);
const _steel = Color(0xFF8C8480);
const _dividerLine = Color(0xFFDDD5C8);
// ─────────────────────────────────────────────────────────────────────────────

class WelcomeLogin extends StatelessWidget {
  WelcomeLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(
        child: Sizer(
          builder: (context, orientation, screenType) {
            return Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.w),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 8.h),
                      // Logo with background circle
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _siennaLight,
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(
                          ImageAssetsConst.plotRolLogo,
                          height: 100,
                          width: 100,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      // App Name
                      const Text(
                        ConstUiStrings.plotRol,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: _espresso,
                          letterSpacing: -0.8,
                          height: 1.0,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      // Tagline / Subtitle
                      // Container(
                      //   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      //   decoration: BoxDecoration(
                      //     color: _parchment,
                      //     borderRadius: BorderRadius.circular(20),
                      //   ),
                      //   child: const Text(
                      //     'Property Management Simplified',
                      //     style: TextStyle(
                      //       fontSize: 12,
                      //       fontWeight: FontWeight.w600,
                      //       color: _sienna,
                      //       letterSpacing: 0.3,
                      //     ),
                      //   ),
                      // ),
                      SizedBox(height: 6.h),
                      // Divider
                      Row(
                        children: [
                          Expanded(child: Container(height: 1, color: _dividerLine)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: const Text(
                              'Choose Action',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _steel,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          Expanded(child: Container(height: 1, color: _dividerLine)),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      // Sign Up Button
                      Container(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _espresso,
                            minimumSize: Size(Get.width, 52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            Get.to(() => RequesterSignup());
                          },
                          child: const Text(
                            ConstUiStrings.newUserSignUp,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      // Login Button
                      Container(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _espresso,
                            side: BorderSide(color: _dividerLine, width: 1.5),
                            minimumSize: Size(Get.width, 52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            Get.to(() => LoginScreen());
                          },
                          child: const Text(
                            ConstUiStrings.login,
                            style: TextStyle(
                              color: _espresso,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      // Footer
                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.center,
                      //   children: [
                      //     TextButton(
                      //       onPressed: () {
                      //         Get.to(() => const WebViewApp(
                      //           url: 'https://www.plotrol.com/privacy-policy',
                      //           appBarText: 'Privacy Policy',
                      //         ));
                      //       },
                      //       child: const Text(
                      //         'Privacy Policy',
                      //         style: TextStyle(
                      //           fontSize: 12,
                      //           color: _steel,
                      //           fontWeight: FontWeight.w500,
                      //         ),
                      //       ),
                      //     ),
                      //     Container(width: 1, height: 12, color: _dividerLine),
                      //     TextButton(
                      //       onPressed: () {
                      //         Get.to(() => const WebViewApp(
                      //           url: 'https://www.plotrol.com/terms',
                      //           appBarText: 'Terms & Conditions',
                      //         ));
                      //       },
                      //       child: const Text(
                      //         'Terms & Conditions',
                      //         style: TextStyle(
                      //           fontSize: 12,
                      //           color: _steel,
                      //           fontWeight: FontWeight.w500,
                      //         ),
                      //       ),
                      //     ),
                      //   ],
                      // ),
                      SizedBox(height: 2.h),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}