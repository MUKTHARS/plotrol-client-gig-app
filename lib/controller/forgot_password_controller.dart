import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:plotrol/helper/api_constants.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';

import '../globalWidgets/flutter_toast.dart';

class ForgotPasswordController extends GetxController {
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  final RoundedLoadingButtonController sendOtpBtnController =
      RoundedLoadingButtonController();
  final RoundedLoadingButtonController resetBtnController =
      RoundedLoadingButtonController();

  RxBool obscureNewPassword = true.obs;
  RxBool obscureConfirmPassword = true.obs;

  /// Step 1 – request OTP for the given mobile/username.
  /// Returns the resolved mobileNumber on success (needed for reset step).
  Future<String?> sendForgotPasswordOtp() async {
    final input = mobileController.text.trim();
    if (input.isEmpty) {
      Toast.showToast('Please enter your mobile number');
      sendOtpBtnController.reset();
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.forgotPassword),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobileNumber': input}),
      );

      final parsed = jsonDecode(response.body);

      if (response.statusCode == 200 && parsed['isSuccessful'] == true) {
        final mobile = parsed['mobileNumber'] as String? ?? input;
        Toast.showToast('OTP sent successfully');
        sendOtpBtnController.reset();
        return mobile;
      } else {
        Toast.showToast(parsed['error'] ?? 'User not found');
        sendOtpBtnController.reset();
        return null;
      }
    } catch (e) {
      Toast.showToast('Network error. Please try again.');
      sendOtpBtnController.reset();
      return null;
    }
  }

  /// Step 2 – verify OTP and set new password.
  Future<bool> resetPassword(String mobileNumber) async {
    final otp = otpController.text.trim();
    final newPass = newPasswordController.text;
    final confirmPass = confirmPasswordController.text;

    if (otp.isEmpty) {
      Toast.showToast('Please enter the OTP');
      resetBtnController.reset();
      return false;
    }
    if (newPass.isEmpty) {
      Toast.showToast('Please enter a new password');
      resetBtnController.reset();
      return false;
    }
    if (newPass != confirmPass) {
      Toast.showToast('Passwords do not match');
      resetBtnController.reset();
      return false;
    }
    if (!RegExp(r'^(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[@#$%])(?=\S+$).{8,15}$')
        .hasMatch(newPass)) {
      Toast.showToast(
          'Password must be 8-15 chars with uppercase, lowercase, digit & special char (@#\$%)');
      resetBtnController.reset();
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.resetPassword),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mobileNumber': mobileNumber,
          'otp': otp,
          'newPassword': newPass,
        }),
      );

      final parsed = jsonDecode(response.body);

      if (response.statusCode == 200 && parsed['isSuccessful'] == true) {
        resetBtnController.reset();
        return true;
      } else {
        Toast.showToast(parsed['error'] ?? 'Failed to reset password');
        resetBtnController.reset();
        return false;
      }
    } catch (e) {
      Toast.showToast('Network error. Please try again.');
      resetBtnController.reset();
      return false;
    }
  }

  @override
  void onClose() {
    mobileController.dispose();
    otpController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
