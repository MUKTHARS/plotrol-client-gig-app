import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plotrol/controller/forgot_password_controller.dart';
import 'package:plotrol/view/singup_screen.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';
import 'package:sizer/sizer.dart';

import '../globalWidgets/text_widget.dart';
import '../helper/const_ui_strings.dart';

class ResetPasswordScreen extends StatelessWidget {
  final String mobileNumber;

  const ResetPasswordScreen({super.key, required this.mobileNumber});

  @override
  Widget build(BuildContext context) {
    final ForgotPasswordController controller = Get.find<ForgotPasswordController>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Obx(() => Sizer(
          builder: (context, orientation, screenType) {
            return Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 2.h),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 4.h),
                      const ReusableTextWidget(
                        text: ConstUiStrings.plotRol,
                        fontWeight: FontWeight.bold,
                        fontSize: 26,
                      ),
                      SizedBox(height: 3.h),
                      const ReusableTextWidget(
                        text: 'Reset Password',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      SizedBox(height: 1.h),
                      const ReusableTextWidget(
                        text: 'Enter the OTP sent to your mobile and choose a new password.',
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 3.h),

                      // OTP field
                      TextFormField(
                        controller: controller.otpController,
                        keyboardType: TextInputType.number,
                        onTapOutside: (_) => FocusScope.of(context).unfocus(),
                        decoration: InputDecoration(
                          hintText: 'Enter OTP',
                          hintStyle: const TextStyle(fontFamily: 'Raleway', fontSize: 15),
                          prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: const BorderSide(color: Colors.black, width: 1.0),
                          ),
                        ),
                      ),
                      SizedBox(height: 2.h),

                      // New password field
                      TextFormField(
                        controller: controller.newPasswordController,
                        obscureText: controller.obscureNewPassword.value,
                        onTapOutside: (_) => FocusScope.of(context).unfocus(),
                        decoration: InputDecoration(
                          hintText: 'New Password',
                          hintStyle: const TextStyle(fontFamily: 'Raleway', fontSize: 15),
                          prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                          suffixIcon: IconButton(
                            icon: Icon(
                              controller.obscureNewPassword.value
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () => controller.obscureNewPassword.toggle(),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: const BorderSide(color: Colors.black, width: 1.0),
                          ),
                        ),
                      ),
                      SizedBox(height: 2.h),

                      // Confirm password field
                      TextFormField(
                        controller: controller.confirmPasswordController,
                        obscureText: controller.obscureConfirmPassword.value,
                        onTapOutside: (_) => FocusScope.of(context).unfocus(),
                        decoration: InputDecoration(
                          hintText: ConstUiStrings.confirmPassword,
                          hintStyle: const TextStyle(fontFamily: 'Raleway', fontSize: 15),
                          prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                          suffixIcon: IconButton(
                            icon: Icon(
                              controller.obscureConfirmPassword.value
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () => controller.obscureConfirmPassword.toggle(),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: const BorderSide(color: Colors.black, width: 1.0),
                          ),
                        ),
                      ),
                      SizedBox(height: 1.h),

                      // Password hint
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: ReusableTextWidget(
                          text: 'Must be 8-15 chars with uppercase, lowercase, digit & special char (@#\$%)',
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 4.h),

                      RoundedLoadingButton(
                        width: Get.width,
                        color: Colors.black,
                        controller: controller.resetBtnController,
                        onPressed: () async {
                          FocusScope.of(context).unfocus();
                          final success = await controller.resetPassword(mobileNumber);
                          if (success) {
                            Get.snackbar(
                              'Success',
                              'Password reset successfully. Please log in.',
                              backgroundColor: Colors.green,
                              colorText: Colors.white,
                              snackPosition: SnackPosition.BOTTOM,
                            );
                            Get.offAll(() => LoginScreen());
                          }
                        },
                        borderRadius: 10,
                        child: const ReusableTextWidget(
                          text: 'Reset Password',
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        )),
      ),
    );
  }
}
