import 'dart:convert';

import 'package:country_currency_pickers/country.dart';
import 'package:country_currency_pickers/utils/utils.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otp_timer_button/otp_timer_button.dart';
import 'package:plotrol/data/repository/autentication/login_repository.dart';
import 'package:plotrol/data/repository/get_properties/get_property_member.dart';
import 'package:plotrol/helper/api_constants.dart';
import 'package:plotrol/helper/const_assets_const.dart';
import 'package:plotrol/helper/utils.dart';
import 'package:plotrol/model/request/autentication_request/autentication_request.dart';
import 'package:plotrol/model/response/autentication_response/autentication_response.dart';
import 'package:plotrol/model/response/individual/individual_response.dart';
import 'package:plotrol/view/gig_views/gig_home_view.dart';
import 'package:plotrol/view/main_screen.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../globalWidgets/flutter_toast.dart';
import '../model/response/employee_response/employee_search_response.dart';

class RequesterLoginController extends GetxController {
  RxString otp = "".obs;
  RxString smsOtp = "".obs;
  RxString resendOtp = "".obs;
  RxBool logInStatus = false.obs;
  RxInt selectedIndex = 0.obs;
  RxInt loginAttempts = 0.obs;
  RxBool showOTPField = false.obs;
  RxBool showNameField = false.obs;
  RxBool isNewRequester = false.obs;
  final RxBool isPasswordVisible = false.obs;
  final RxBool isConfirmPasswordVisible = false.obs;
  RxString password = ''.obs;

  final RoundedLoadingButtonController btnController =
      RoundedLoadingButtonController();

  final RoundedLoadingButtonController introBtnController =
      RoundedLoadingButtonController();

  OtpTimerButtonController otpTimerController = OtpTimerButtonController();

  TextEditingController mobileController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController userNameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  TextEditingController otpController = TextEditingController();

  // WebViewController webViewController = WebViewController();

  LoginRepository loginRepository = LoginRepository();

  GetHouseholdMemberRepository householdMemberRepository =
      GetHouseholdMemberRepository();

  // FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

  Country selectedDialogCountry = CountryPickerUtils.getCountryByIsoCode('IN');

  String? fcmEntryToken;

  var isChecked = false.obs;
  var isEnabled = true.obs;
  RxString mobileNumber = ''.obs;
  RxInt authMode = 0.obs;
  RxBool isScrollView = false.obs;
  RxString userFcmToken = ''.obs;
  RxString contactNo = "".obs;
  RxInt configId = 0.obs;
  RxInt categoryId = 0.obs;
  RxInt subCategoryId = 0.obs;
  RxInt moduleId = 0.obs;
  RxInt tenantId = 0.obs;
  RxInt locationId = 0.obs;
  RxString firstName = ''.obs;
  RxString lastName = ''.obs;
  RxString userProfileImage = ''.obs;
  RxString email = ''.obs;
  bool hasUppercase(String input) => input.contains(RegExp(r'[A-Z]'));
  bool hasLowercase(String input) => input.contains(RegExp(r'[a-z]'));
  bool hasDigit(String input) => input.contains(RegExp(r'\d'));
  bool hasSpecialChar(String input) => input.contains(RegExp(r'[@#$%]'));
  bool hasNoWhitespace(String input) => !input.contains(RegExp(r'\s'));
  bool hasValidLength(String input) => input.length >= 8 && input.length <= 15;

  @override
  void onInit() {
    passwordController.addListener(() {
      password.value = passwordController.text;
    });
    // fcmToken();
    super.onInit();
  }

  /// Terms and conditions CheckBox enable and disable
  void toggleCheckbox(bool? value) {
    if (isEnabled.value) {
      isChecked.value = value!;
    }
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
    update();
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
    update();
  }

  void enableCheckbox(bool value) {
    isEnabled.value = value;
  }

  void resetSelection() {
    isChecked.value = false; // Reset the isChecked value to false
  }

  /// login screen validation using the mobile number and the Terms and conditions checkbox
  void loginScreenValidation(mobile, context) {
    final passwordRegex =
        RegExp(r'^(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[@#$%])(?=\S+$).{8,15}$');
    if (mobileController.text.isEmpty) {
      Toast.showToast('Please Enter the Mobile Number');
      btnController.reset();
    } else if (mobileController.text.length < 10) {
      Toast.showToast('Please Enter a 10 digit valid phone number');
      btnController.reset();
    } else if (nameController.text.trim().isEmpty) {
      Toast.showToast('Please Enter a valid name');
      btnController.reset();
    } else if (passwordController.text.trim().isEmpty) {
      Toast.showToast('Please enter the password for your account');
      btnController.reset();
    } else if (!passwordRegex.hasMatch(passwordController.text)) {
      Toast.showToast(
          'Password must be 8-15 chars, include upper, lower, digit, and @#\$%');
      btnController.reset();
    } else if (confirmPasswordController.text.trim().isEmpty) {
      Toast.showToast('Passwords do not match');
      btnController.reset();
    } else if ((passwordController.text.trim() !=
        confirmPasswordController.text.trim())) {
      Toast.showToast('Passwords do not match');
      btnController.reset();
    }
    // else if (mobileController.text.length > 10) {
    //   Toast.showToast('The Number Should be not digit large');
    //   btnController.reset();
    // }
    // else if (!RegExp(
    //         r'^\s*(?:\+?(\d{1,3}))?[-. (]*(\d{3})[-. )]*(\d{3})[-. ]*(\d{4})(?: *x(\d+))?\s*$')
    //     .hasMatch(mobileController.text)) {
    //   Toast.showToast('Please Enter the Valid Number');
    //   btnController.reset();
    // }
    // else if (!isChecked.value) {
    //   Toast.showToast('Please Accept Our Terms and Conditions');
    //   btnController.reset();
    // }
    else {
      signIn(context);
      btnController.reset();
    }
  }

  signIn(context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final date18YearsAgo = DateTime(now.year - 18, now.month, now.day);
    final millisecondsSinceEpoch18Years = date18YearsAgo.millisecondsSinceEpoch;
    signInResult(
      Employee(
          code: mobileController.text.trim(),
          tenantId: 'mz',
          dateOfAppointment: AppUtils().millisecondsSinceEpoch(),
          employeeStatus: "EMPLOYED",
          employeeType: "PERMANENT",
          assignments: [
            Assignment(
              fromDate: AppUtils().millisecondsSinceEpoch(),
              isCurrentAssignment: true,
              department: "OTHER",
              designation: "DESIG_23",
            )
          ],
          jurisdictions: [
            Jurisdiction(
                hierarchy: "MICROPLAN",
                boundary: "MICROPLAN_MO",
                boundaryType: "COUNTRY",
                tenantId: "mz")
          ],
          user: UserRequest(
              dob: millisecondsSinceEpoch18Years,
              mobileNumber: mobileController.text.trim(),
              name: nameController.text.trim(),
              password: passwordController.text.trim(),
              tenantId: ApiConstants.tenantId,
              userName: mobileController.text.trim(),
              roles: [
                Role(
                    code: 'DISTRIBUTOR',
                    name: 'Distributor',
                    tenantId: ApiConstants.tenantId)
              ])),
      context,
    );
  }

  signInResult(Employee data, BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int loginAttempt = prefs.getInt('loginAttempts') ?? loginAttempts.value;
    prefs.setInt('loginAttempts', loginAttempt);
    if (loginAttempt <= 3) {
      EmployeeResponse? result = await loginRepository.createRequester({
        'Employees': [data.toJson()]
      });
      loginAttempts.value = loginAttempts.value + 1;
      if (result?.employees.first.code != null) {
        LoginResponse? loginResult = await loginRepository.signIn(
          LoginRequest(
            username: mobileController.text,
            password: passwordController.text,
            tenantId: ApiConstants.tenantId,
            grant_type: 'password',
            scope: 'read',
            userType: 'EMPLOYEE',
          ),
        );

        if (loginResult?.accessToken != null) {
          firstName = (loginResult?.userRequest?.name ?? ' ').obs;
          // Store access token in SharedPreferences
          prefs.setString('access_token', loginResult!.accessToken!);
          prefs.setString('tenantId', loginResult.userRequest?.tenantId ?? '');
          prefs.setString(
              'userInfo', jsonEncode(loginResult.userRequest?.toJson()));
          prefs.setInt('userId', loginResult.userRequest?.id ?? 0);
          prefs.setString('uuid', loginResult.userRequest?.uuid ?? '');
          prefs.setString('userName', loginResult.userRequest?.userName ?? '');
          prefs.setString('name', loginResult.userRequest?.name ?? '');
          prefs.setString(
              'mobileNumber', loginResult.userRequest?.mobileNumber ?? '');
          prefs.setString('emailId', loginResult.userRequest?.emailId ?? '');
          prefs.setString('type', loginResult.userRequest?.type ?? '');
          prefs.setString('tenantId', loginResult.userRequest?.tenantId ?? '');
          prefs.setString('tenantImage', ImageAssetsConst.profileIcon);
          bool isDistributor =
              AppUtils().checkIsHousehold(loginResult.userRequest?.roles ?? []);
          bool isPGRAdmin =
              AppUtils().checkIsPGRAdmin(loginResult.userRequest?.roles ?? []);

          if (isDistributor && !isPGRAdmin) {
            IndividualsResponse? individualsResponse =
                await loginRepository.getIndividual({
              "Individual": {
                "mobileNumber": loginResult.userRequest?.mobileNumber != null
                    ? [loginResult.userRequest?.mobileNumber]
                    : null
              }
            }, loginResult.userRequest?.toJson());
            // Store user details
            if (individualsResponse != null) {
              final loggedInIndividual = individualsResponse.individuals;
              prefs.setString(
                  'individualId',
                  loggedInIndividual
                          ?.where((i) => i.userUuid != null)
                          .first
                          .id ??
                      '');
              prefs.setString(
                  'userUuid',
                  loggedInIndividual
                          ?.where((i) => i.userUuid != null)
                          .first
                          .userUuid ??
                      '');
              prefs.setString(
                  'defaultBoundaryCode',
                  loggedInIndividual
                          ?.where((i) => i.userUuid != null)
                          .first
                          .address
                          ?.first
                          .locality
                          ?.code ??
                      '');
            }
          } else {
            prefs.setString(
                'userInfo', jsonEncode(loginResult.userRequest?.toJson()));
            prefs.setInt('userId', loginResult.userRequest?.id ?? 0);
            prefs.setString('userUuid', loginResult.userRequest?.uuid ?? '');
            prefs.setString(
                'userName', loginResult.userRequest?.userName ?? '');
            prefs.setString('name', loginResult.userRequest?.name ?? '');
            prefs.setString(
                'mobileNumber', loginResult.userRequest?.mobileNumber ?? '');
            prefs.setString('emailId', loginResult.userRequest?.emailId ?? '');
            prefs.setString('type', loginResult.userRequest?.type ?? '');
            prefs.setString(
                'tenantId', loginResult.userRequest?.tenantId ?? '');
            prefs.setString('tenantImage', ImageAssetsConst.profileIcon);
            // Set values in the application state
          }
          authMode.value = 1; // Assuming 1 means authenticated
          logInStatus.value = true;

          // Navigate to HomeScreen after successful login
          Get.offAll(() => isDistributor && !isPGRAdmin
              ? HomeView(selectedIndex: 0)
              : GigHomeView(selectedIndex: 0));
        } else {
          btnController.reset();
          Toast.showToast(
              'Auto login failed. Please try logging in with the created credentials.');
          // Handle login failure
        }
      } else {
        btnController.reset();
        Toast.showToast(
            'Something went wrong. The mobile number might already be in use');
      }
    } else {
      btnController.reset();
      Toast.showToast(
          'Too many login attempts. Contact admin or clear app data to try again.');
    }

    update();
  }

  // updateHouseDetails() async {
  //   // Set values in the application state
  //   authMode.value = 1; // Assuming 1 means authenticated
  //   logInStatus.value = true;
  //
  //   // Navigate to HomeScreen after successful login
  //   Get.offAll(() => HomeView(selectedIndex: 0));
  //
  // }

  // signInResult(LoginRequest data, context) async {
  //   LoginResponse? result = await loginRepository.signIn(data);
  //   if (result?.status == true) {
  //     authMode.value = result?.details?.authmode ?? 0;
  //     logInStatus.value = result?.status ?? false;
  //     contactNo.value = result?.details?.contactno ?? '';
  //     userFcmToken.value = result?.details?.userfcmtoken ?? '';
  //     configId.value = result?.details?.configid ?? 0;
  //     categoryId.value = result?.details?.categoryid ?? 0;
  //     subCategoryId.value = result?.details?.subcategoryid ?? 0;
  //     tenantId.value = result?.details?.tenantid ?? 0;
  //     moduleId.value = result?.details?.moduleid ?? 0;
  //     locationId.value = result?.details?.locationid ?? 0;
  //     firstName.value = result?.details?.firstname ?? '';
  //     lastName.value = result?.details?.lastname ?? '';
  //     userProfileImage.value = result?.details?.tenantimage ?? '';
  //     SharedPreferences prefs = await SharedPreferences.getInstance();
  //     prefs.setInt('userId', result?.details?.userid ?? 0);
  //     prefs.setString('firstName', result?.details?.firstname ?? '');
  //     prefs.setString('lastName', result?.details?.lastname ?? '');
  //     prefs.setString('tenantImage', result?.details?.tenantimage ?? '');
  //     prefs.setInt('tenantId', result?.details?.tenantid ?? 0);
  //     prefs.setString('EmailId', result?.details?.email ?? '');
  //     resetSelection();
  //   }
  //   if (authMode.value != 1) {
  //     sendSmsOtp(mobileController.text);
  //     btnController.reset();
  //   } else {
  //     otpController.clear();
  //     resendOtp.value = '123456';
  //     logger.i('AuthMode : ${authMode}');
  //     if (authMode.value == 1) {
  //       var snackBar = const SnackBar(
  //         backgroundColor: Colors.black,
  //         content: ReusableTextWidget(
  //           text:
  //               'Please enter your 6 digit verification code provided by PlotRol',
  //           color: Colors.white,
  //         ),
  //       );
  //       ScaffoldMessenger.of(context).showSnackBar(snackBar);
  //     }
  //     Get.to(() => OtpScreen(
  //           otp: resendOtp.value,
  //           authMode: authMode.value,
  //           logInStatus: logInStatus.value,
  //         ));
  //   }
  // }

  // Future<String> profileImageString() async{
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   return prefs.get('tenantImage').toString();
  // }

  fcmToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // firebaseMessaging.getToken().then((token) {
    //   fcmEntryToken = token;
    //   prefs.setString('fcmToken', token!);
    // });
  }

  String? getInitials(String firstName, [String? lastName]) {
    if (firstName.isEmpty) {
      return '';
    }
    if (lastName == null || lastName.isEmpty) {
      int middleIndex = firstName.length ~/ 2;
      return firstName[middleIndex].toUpperCase();
    }
    return '${firstName[0].toUpperCase()} ${lastName[0].toUpperCase()}';
  }
}
