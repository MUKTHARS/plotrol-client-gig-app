import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../globalWidgets/flutter_toast.dart';
import '../helper/api_constants.dart';
import '../model/request/autentication_request/request_info.dart';
import '../services/base-service.dart';

class AddHelpdeskUserController extends GetxController {
  final RoundedLoadingButtonController btnController =
      RoundedLoadingButtonController();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  RxBool obscurePassword = true.obs;

  @override
  void onClose() {
    nameController.dispose();
    mobileController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  Future<void> createUser() async {
    final name = nameController.text.trim();
    final mobile = mobileController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (name.isEmpty) {
      Toast.showToast('Please enter full name');
      btnController.reset();
      return;
    }
    if (mobile.isEmpty || mobile.length < 10) {
      Toast.showToast('Please enter a valid mobile number');
      btnController.reset();
      return;
    }
    if (password.length < 6) {
      Toast.showToast('Password must be at least 6 characters');
      btnController.reset();
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      final tenantId = prefs.getString('tenantId') ?? ApiConstants.tenantId;
      final userInfoString = prefs.getString('userInfo');
      final Map? userInfo =
          userInfoString != null ? jsonDecode(userInfoString) : null;

      final requestInfo = RequestInfo(authToken: accessToken, userInfo: userInfo);

      final body = <String, dynamic>{
        'name': name,
        'mobileNumber': mobile,
        'password': password,
        'tenantId': tenantId,
      };
      if (email.isNotEmpty) body['emailId'] = email;

      final Map<String, dynamic> response =
          await BaseService().makeRequest(
        url: ApiConstants.createHelpdeskUser,
        body: body,
        method: RequestType.POST,
        requestInfo: requestInfo,
      );

      final statusVal = response['status'];
      final codeVal = response['code'];
      final message = response['message']?.toString() ?? '';

      final bool isSuccess = statusVal == true;
      final int code = codeVal is int
          ? codeVal
          : int.tryParse(codeVal?.toString() ?? '') ?? 0;

      if (isSuccess && code == 200) {
        btnController.success();
        Toast.showToast('User created successfully');
        await Future.delayed(const Duration(milliseconds: 800));
        _clearForm();
        Get.back();
      } else if (code == 409) {
        btnController.reset();
        Toast.showToast(message.isNotEmpty ? message : 'Mobile or email already registered');
      } else {
        btnController.reset();
        Toast.showToast(message.isNotEmpty ? message : 'Failed to create user');
      }
    } catch (e) {
      btnController.reset();
      Toast.showToast('Failed to create user. Please try again.');
    }
  }

  void _clearForm() {
    nameController.clear();
    mobileController.clear();
    emailController.clear();
    passwordController.clear();
  }
}
