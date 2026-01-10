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

class WelcomeLogin extends StatelessWidget {
  WelcomeLogin({super.key});

  // final AuthenticationController authenticationController = Get.put(AuthenticationController());


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Sizer(
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
                      text: ConstUiStrings.newUserChooseAction,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    SizedBox(
                      height: 3.h,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: 2.h,
                              right: 2.h,
                              bottom: 2.h,
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                minimumSize: Size(Get.width, 50), // Adjust height as needed
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () {
                                Get.to(() => RequesterSignup());
                              },
                              child: const ReusableTextWidget(
                                text: ConstUiStrings.newUserSignUp,
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),

                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: 2.h,
                              right: 2.h,
                              bottom: 2.h,
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                minimumSize: Size(Get.width, 50), // Adjust height as needed
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () {
                                // authenticationController.loginScreenValidation(
                                //     authenticationController.mobileController.text,
                                //     context
                                // );
                                Get.to(() => LoginScreen());
                              },
                              child: const ReusableTextWidget(
                                text: ConstUiStrings.login,
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        ),
      ),
      bottomNavigationBar:  SizedBox.shrink(),
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
