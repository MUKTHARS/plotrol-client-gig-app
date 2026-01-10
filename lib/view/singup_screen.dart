import 'package:country_currency_pickers/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plotrol/controller/autentication_controller.dart';
import 'package:plotrol/helper/const_assets_const.dart';
import 'package:plotrol/helper/const_ui_strings.dart';
import 'package:plotrol/view/privacy_and_policy_page.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';
import 'package:sizer/sizer.dart';
import '../globalWidgets/text_widget.dart';

class LoginScreen extends StatelessWidget {
   LoginScreen({super.key,});

  final AuthenticationController authenticationController = Get.put(AuthenticationController());


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: GetBuilder<AuthenticationController>(
        builder: (controller) {
          return Sizer(
            builder: (context, orientation, screenType) {
              return Center(
                child: Padding(
                  padding:  EdgeInsets.only(
                    left: 2.h,
                    right: 2.h,
                    bottom: 2.h,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 10.h,
                        ),
                        const ReusableTextWidget(
                          text: ConstUiStrings.plotRol,
                          fontWeight: FontWeight.bold,
                          fontSize: 26,
                        ),
                        SizedBox(
                          height: 2.h,
                        ),
                        Image.asset(
                            ImageAssetsConst.plotRolLogo,
                            height: 120,
                            width: 120,
                        ),
                        SizedBox(
                          height: 4.h,
                        ),
                        const ReusableTextWidget(
                          text: ConstUiStrings.logInToContinue,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        SizedBox(
                          height: 3.h,
                        ),
                        TextFormField(
                            controller: controller.mobileController,
                            onTap: () {
                              controller.isScrollView.value = true;
                            },
                            onTapOutside: (event) {
                              FocusScope.of(context).unfocus();
                            },
                            onEditingComplete: () {
                              FocusScope.of(context).unfocus();
                            },
                            keyboardType: TextInputType.text,
                            onChanged: (text) {
                              // if (text.length == 10) {
                              //   FocusScope.of(context).unfocus();
                              // }
                            },
                            // inputFormatters: [
                            //   LengthLimitingTextInputFormatter(10),
                            //   FilteringTextInputFormatter.digitsOnly,
                            // ],
                            decoration: InputDecoration(
                              hintText: ConstUiStrings.enterUserName,
                              hintStyle: const TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 15,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: const BorderSide(
                                  color: Colors.grey,
                                  width: 0,
                                ),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.black,
                                  // Set the color you want when the field is focused
                                  width: 1.0, // Set the width of the border side
                                ),
                              ),
                              // prefixIcon: SizedBox(
                              //   width: Get.width * 0.3,
                              //   height: Get.height * 0.04,
                              //   child: Row(
                              //     children: [
                              //       const SizedBox(
                              //         width: 25,
                              //       ),
                              //       InkWell(
                              //         child: CountryPickerUtils
                              //             .getDefaultFlagImage(
                              //             controller.selectedDialogCountry),
                              //         // onTap: _openCountryPickerDialog,
                              //       ),
                              //       const SizedBox(
                              //         width: 8,
                              //       ),
                              //       Text(
                              //           "+${controller.selectedDialogCountry
                              //               .phoneCode}"),
                              //     ],
                              //   ),
                              // ),
                            )
                        ),
                        SizedBox(
                          height: 1.h,
                        ),
                        TextFormField(
                            controller: controller.otpController,
                            onTap: () {
                              controller.isScrollView.value = true;
                            },
                            onTapOutside: (event) {
                              FocusScope.of(context).unfocus();
                            },
                            onEditingComplete: () {
                              FocusScope.of(context).unfocus();
                            },
                            keyboardType: TextInputType.text,
                            onChanged: (text) {
                              // if (text.length == 10) {
                              //   FocusScope.of(context).unfocus();
                              // }
                            },
                            // inputFormatters: [
                            //   LengthLimitingTextInputFormatter(10),
                            //   FilteringTextInputFormatter.digitsOnly,
                            // ],
                            decoration: InputDecoration(
                              hintText: ConstUiStrings.enterPassword,
                              hintStyle: const TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 15,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: const BorderSide(
                                  color: Colors.grey,
                                  width: 0,
                                ),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.black,
                                  // Set the color you want when the field is focused
                                  width: 1.0, // Set the width of the border side
                                ),
                              ),
                              // prefixIcon: SizedBox(
                              //   width: Get.width * 0.3,
                              //   height: Get.height * 0.04,
                              //   child: Row(
                              //     children: [
                              //       const SizedBox(
                              //         width: 25,
                              //       ),
                              //       InkWell(
                              //         child: CountryPickerUtils
                              //             .getDefaultFlagImage(
                              //             controller.selectedDialogCountry),
                              //         // onTap: _openCountryPickerDialog,
                              //       ),
                              //       const SizedBox(
                              //         width: 8,
                              //       ),
                              //       Text(
                              //           "+${controller.selectedDialogCountry
                              //               .phoneCode}"),
                              //     ],
                              //   ),
                              // ),
                            )
                        ),
                        SizedBox(
                          height: 1.h,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Obx(
                                  () =>
                                  Checkbox(
                                    activeColor: Colors.black,
                                    checkColor: Colors.white,
                                    value: controller.isChecked.value,
                                    onChanged: controller.isEnabled.value
                                        ? controller.toggleCheckbox
                                        : null,
                                  ),
                            ),
                            const ReusableTextWidget(
                              text: ConstUiStrings.termsAndPrivacy,
                            ),
                            // GestureDetector(
                            //   onTap: (){
                            //    Get.to(() => WebViewApp(
                            //        url: 'https://www.plotrol.com/privacy',
                            //        appBarText: 'Privacy Policy',
                            //      ),
                            //    );
                            //   },
                            //   child: ReusableTextWidget(
                            //     text: ConstUiStrings.privacyPolicy,
                            //     isUnderText: TextDecoration.underline,
                            //   ),
                            // )
                          ],
                        ),
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
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 2.h,
                  right: 2.h,
                  bottom: 2.h,
                ),
                child: RoundedLoadingButton(
                  width: Get.width,
                  color: Colors.black,
                  controller: authenticationController.btnController,
                  onPressed: () {
                    authenticationController.loginScreenValidation(
                        authenticationController.mobileController.text,
                        context
                    );
                  },
                  borderRadius: 10,
                  child: const ReusableTextWidget(
                    text: ConstUiStrings.continueText,
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// class WebView extends StatelessWidget {
//
//    WebViewController controller = WebViewController();
//
//    WebView({super.key, required this.controller});
//
//   @override
//   Widget build(BuildContext context) {
//     return ;
//   }
// }
