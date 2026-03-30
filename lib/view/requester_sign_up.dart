import 'package:country_currency_pickers/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:otp_timer_button/otp_timer_button.dart';
import 'package:pinput/pinput.dart';
import 'package:plotrol/controller/autentication_controller.dart';
import 'package:plotrol/helper/const_assets_const.dart';
import 'package:plotrol/helper/const_ui_strings.dart';
import 'package:plotrol/view/privacy_and_policy_page.dart';
import 'package:plotrol/widgets/password_validator.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';
import 'package:sizer/sizer.dart';
import '../controller/requester_login_controller.dart';
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

class RequesterSignup extends StatelessWidget {
  RequesterSignup({super.key,});

  final RequesterLoginController authenticationController = Get.put(RequesterLoginController());
  final passwordRegex = RegExp(r'^(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[@#$%])(?=\S+$).{8,15}$');

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: const TextStyle(fontSize: 22, color: _espresso),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: _dividerLine),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        color: _parchment,
        border: Border.all(color: _sienna, width: 1.5),
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        color: _sand,
      ),
    );
    
    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(
        child: GetBuilder<RequesterLoginController>(
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
                                  'SIGN UP DETAILS',
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
                          // Mobile Number Field
                          _buildTextField(
                            controller: controller.mobileController,
                            hintText: ConstUiStrings.enterPhoneNumber,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(10),
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            prefixWidget: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(width: 12),
                                CountryPickerUtils.getDefaultFlagImage(
                                  controller.selectedDialogCountry,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "+${controller.selectedDialogCountry.phoneCode}",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _espresso,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(width: 1, height: 24, color: _dividerLine),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ),
                          SizedBox(height: 2.h),
                          // Name Field
                          _buildTextField(
                            controller: controller.nameController,
                            hintText: ConstUiStrings.enterName,
                            keyboardType: TextInputType.text,
                          ),
                          SizedBox(height: 2.h),
                          // Password Field
                          _buildTextField(
                            controller: controller.passwordController,
                            hintText: ConstUiStrings.enterPassword,
                            obscureText: !controller.isPasswordVisible.value,
                            suffixIcon: IconButton(
                              icon: Icon(
                                controller.isPasswordVisible.value ? Icons.visibility : Icons.visibility_off,
                                color: _steel,
                                size: 20,
                              ),
                              onPressed: () {
                                controller.togglePasswordVisibility();
                              },
                            ),
                          ),
                          SizedBox(height: 2.h),
                          // Confirm Password Field
                          _buildTextField(
                            controller: controller.confirmPasswordController,
                            hintText: ConstUiStrings.confirmPassword,
                            obscureText: !controller.isConfirmPasswordVisible.value,
                            suffixIcon: IconButton(
                              icon: Icon(
                                controller.isConfirmPasswordVisible.value ? Icons.visibility : Icons.visibility_off,
                                color: _steel,
                                size: 20,
                              ),
                              onPressed: () {
                                controller.toggleConfirmPasswordVisibility();
                              },
                            ),
                          ),
                          SizedBox(height: 2.h),
                          // Password Validator Card
                          Obx(() {
                            final pwd = controller.password.value;
                            return Container(
                              decoration: BoxDecoration(
                                color: _parchment,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: _dividerLine),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: _siennaLight,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.info_outline,
                                            size: 16,
                                            color: _sienna,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        const Text(
                                          'Password Requirements',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: _espresso,
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    _buildPasswordRuleItem("At least one digit", controller.hasDigit(pwd)),
                                    _buildPasswordRuleItem("At least one lowercase letter", controller.hasLowercase(pwd)),
                                    _buildPasswordRuleItem("At least one uppercase letter", controller.hasUppercase(pwd)),
                                    _buildPasswordRuleItem("At least one special character (@, #, \$, %)", controller.hasSpecialChar(pwd)),
                                    _buildPasswordRuleItem("No white spaces", controller.hasNoWhitespace(pwd)),
                                    _buildPasswordRuleItem("Length between 8-15 characters", controller.hasValidLength(pwd)),
                                  ],
                                ),
                              ),
                            );
                          }),
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
    List<TextInputFormatter>? inputFormatters,
    Widget? prefixWidget,
    Widget? suffixIcon,
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
        inputFormatters: inputFormatters,
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
          prefixIcon: prefixWidget != null
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: prefixWidget,
                )
              : null,
          suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildPasswordRuleItem(String text, bool isValid) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.circle_outlined,
            size: 14,
            color: isValid ? _sienna : _steel,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                color: isValid ? _walnut : _steel,
                fontWeight: isValid ? FontWeight.w600 : FontWeight.w400,
                decoration: isValid ? TextDecoration.lineThrough : null,
                decorationColor: _steel,
                decorationThickness: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}