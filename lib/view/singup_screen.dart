import 'package:country_currency_pickers/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plotrol/controller/autentication_controller.dart';
import 'package:plotrol/helper/const_assets_const.dart';
import 'package:plotrol/helper/const_ui_strings.dart';
import 'package:plotrol/view/forgot_password_screen.dart';
import 'package:plotrol/view/privacy_and_policy_page.dart';
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

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key,});

  final AuthenticationController authenticationController = Get.put(AuthenticationController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(
        child: GetBuilder<AuthenticationController>(
          builder: (controller) {
            return Sizer(
              builder: (context, orientation, screenType) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6.w),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: 6.h),
                          // Logo with background circle
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _siennaLight,
                              shape: BoxShape.circle,
                            ),
                            child: Image.asset(
                              ImageAssetsConst.plotRolLogo,
                              height: 80,
                              width: 80,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          // App Name
                          const Text(
                            ConstUiStrings.plotRol,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: _espresso,
                              letterSpacing: -0.8,
                              height: 1.0,
                            ),
                          ),
                          SizedBox(height: 1.h),
                          // Tagline
                          SizedBox(height: 4.h),
                          // Divider
                          Row(
                            children: [
                              Expanded(child: Container(height: 1, color: _dividerLine)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: const Text(
                                  'LOGIN DETAILS',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: _steel,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                              Expanded(child: Container(height: 1, color: _dividerLine)),
                            ],
                          ),
                          SizedBox(height: 3.h),
                          // Username/Email Field
                          _buildTextField(
                            controller: controller.mobileController,
                            hintText: ConstUiStrings.enterUserName,
                            keyboardType: TextInputType.text,
                          ),
                          SizedBox(height: 2.h),
                          // Password Field
                          _buildTextField(
                            controller: controller.otpController,
                            hintText: ConstUiStrings.enterPassword,
                            keyboardType: TextInputType.text,
                            obscureText: true,
                            showPasswordToggle: true,
                            onTogglePassword: () {
                              // You can add password visibility toggle logic here
                              // controller.togglePasswordVisibility();
                            },
                          ),
                          SizedBox(height: 1.h),
                          // Forgot Password
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () => Get.to(() => ForgotPasswordScreen()),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _sienna,
                                    decoration: TextDecoration.underline,
                                    decorationColor: _sienna,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 2.h),
                          // Terms & Privacy Checkbox
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Obx(
                                () => Checkbox(
                                  activeColor: _sienna,
                                  checkColor: Colors.white,
                                  value: controller.isChecked.value,
                                  onChanged: controller.isEnabled.value
                                      ? controller.toggleCheckbox
                                      : null,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              const Text(
                                'I agree to the ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _steel,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Get.to(() => const WebViewApp(
                                    url: 'https://www.plotrol.com/privacy-policy',
                                    appBarText: 'Privacy Policy',
                                  ));
                                },
                                child: const Text(
                                  'Privacy Policy',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _espresso,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                              const Text(
                                ' & ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _steel,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Get.to(() => const WebViewApp(
                                    url: 'https://www.plotrol.com/terms',
                                    appBarText: 'Terms & Conditions',
                                  ));
                                },
                                child: const Text(
                                  'Terms',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _espresso,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: EdgeInsets.fromLTRB(6.w, 0, 6.w, 3.h),
          child: RoundedLoadingButton(
            width: Get.width,
            color: _espresso,
            controller: authenticationController.btnController,
            onPressed: () {
              authenticationController.loginScreenValidation(
                authenticationController.mobileController.text,
                context
              );
            },
            borderRadius: 14,
            child: const Text(
              ConstUiStrings.continueText,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    bool showPasswordToggle = false,
    VoidCallback? onTogglePassword,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _dividerLine),
      ),
      child: TextFormField(
        controller: controller,
        onTap: () {
          // Handle scroll if needed
        },
        onTapOutside: (event) {
          FocusScope.of(Get.context!).unfocus();
        },
        onEditingComplete: () {
          FocusScope.of(Get.context!).unfocus();
        },
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: const TextStyle(
          fontSize: 15,
          color: _espresso,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            fontSize: 14,
            color: _steel,
            fontWeight: FontWeight.w400,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _sienna, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}