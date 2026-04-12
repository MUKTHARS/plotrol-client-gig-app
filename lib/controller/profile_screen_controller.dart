import 'package:get/get.dart';
import 'package:plotrol/controller/bottom_navigation_controller.dart';
import 'package:plotrol/controller/home_screen_controller.dart';
import 'package:plotrol/controller/requester_login_controller.dart';
import 'package:plotrol/view/intro_screen.dart';
import 'package:plotrol/view/singup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helper/api_constants.dart';
import 'autentication_controller.dart';

class ProfileScreenController extends GetxController {

  final AuthenticationController _authenticationController = Get.put(AuthenticationController());
  final RequesterLoginController _requesterLoginController = Get.put(RequesterLoginController());

  void logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _authenticationController.authMode.value = 0;
    _authenticationController.logInStatus.value = false;
    _authenticationController.mobileController.clear();
    _authenticationController.otpController.clear();
    _requesterLoginController.authMode.value = 0;
    _requesterLoginController.logInStatus.value = false;
    _requesterLoginController.mobileController.clear();
    _requesterLoginController.otpController.clear();
    _requesterLoginController.nameController.clear();
    _requesterLoginController.passwordController.clear();

    Get.delete<BottomNavigationController>();
    // Delete HomeScreenController so the next user's login starts with a clean
    // state — without this, getPropertiesDetails retains the previous user's data.
    Get.delete<HomeScreenController>();
    Get.offAll(() => OnBoardPage());
    update();
  }

}