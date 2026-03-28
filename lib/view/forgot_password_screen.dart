import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plotrol/controller/forgot_password_controller.dart';
import 'package:plotrol/view/reset_password_screen.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';
import 'package:sizer/sizer.dart';

import '../globalWidgets/text_widget.dart';
import '../helper/const_ui_strings.dart';

class ForgotPasswordScreen extends StatelessWidget {
  ForgotPasswordScreen({super.key});

  final ForgotPasswordController controller =
      Get.put(ForgotPasswordController());

  @override
  Widget build(BuildContext context) {
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
        child: Sizer(
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
                        text: 'Forgot Password',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      SizedBox(height: 1.h),
                      const ReusableTextWidget(
                        text: 'Enter your registered mobile number. We\'ll send an OTP to reset your password.',
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 3.h),
                      TextFormField(
                        controller: controller.mobileController,
                        keyboardType: TextInputType.phone,
                        onTapOutside: (_) => FocusScope.of(context).unfocus(),
                        onEditingComplete: () => FocusScope.of(context).unfocus(),
                        decoration: InputDecoration(
                          hintText: 'Mobile Number',
                          hintStyle: const TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 15,
                          ),
                          prefixIcon: const Icon(Icons.person_outline, color: Colors.grey),
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
                      SizedBox(height: 4.h),
                      RoundedLoadingButton(
                        width: Get.width,
                        color: Colors.black,
                        controller: controller.sendOtpBtnController,
                        onPressed: () async {
                          FocusScope.of(context).unfocus();
                          final mobile = await controller.sendForgotPasswordOtp();
                          if (mobile != null) {
                            Get.to(() => ResetPasswordScreen(mobileNumber: mobile));
                          }
                        },
                        borderRadius: 10,
                        child: const ReusableTextWidget(
                          text: 'Send OTP',
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
        ),
      ),
    );
  }
}
