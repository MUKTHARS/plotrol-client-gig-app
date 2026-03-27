import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plotrol/controller/autentication_controller.dart';
import 'package:plotrol/controller/profile_screen_controller.dart';
import 'package:plotrol/view/privacy_and_policy_page.dart';
import 'package:plotrol/view/profile_information.dart';
import 'package:sizer/sizer.dart';
import '../controller/create_account_controller.dart';
import '../controller/home_screen_controller.dart';
import '../globalWidgets/text_widget.dart';
import '../helper/const_assets_const.dart';
import 'add_helpdesk_user_screen.dart';

class Profile extends StatelessWidget {
  Profile({super.key});

  final CreateAccountController createAccountController = Get.put(CreateAccountController());

  final AuthenticationController authenticationController = Get.put(AuthenticationController());

  final HomeScreenController homeScreenController = Get.put(HomeScreenController());

  final HomeScreenController controller = Get.put(HomeScreenController());

  final ProfileScreenController profileScreenController = Get.put(ProfileScreenController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        title: const ReusableTextWidget(
          text: 'Profile',
          fontSize: 21,
          fontWeight: FontWeight.w700,
        ),
      ),
      body: Sizer(
        builder: (context, orientation, deviceType) {
          return GetBuilder<HomeScreenController>(
            initState: (_) {
              homeScreenController.getDetails();
              homeScreenController.getTenantApiFunction();
            },
            builder: (controller) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 10,),
                      Row(
                        children: [
                          CircleAvatar(
                            minRadius: 50,
                            maxRadius: 50,
                            backgroundColor: Colors.grey.withOpacity(0.4),
                            child: (controller.tenantProfileImage.value.isNotEmpty || createAccountController.profileImage != null) ?
                            ClipOval(
                              child: controller.tenantProfileImage.value.isNotEmpty ? Image.network(
                                fit: BoxFit.cover,
                                width: 100,
                                height: 100,
                                controller.tenantProfileImage.value,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.network(
                                      ImageAssetsConst.sampleRoomPage,
                                      width: 120,
                                      height: 140,
                                      fit: BoxFit.fill,
                                    );
                                  }
                              ) : Image.file(
                                width: 100,
                                height : 100,
                                File(createAccountController.profileImage?.path ?? ''),
                                fit: BoxFit.cover,
                              ),
                            ) :
                            const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10,),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ReusableTextWidget(
                                    text: controller.tenantFirstName.value.isNotEmpty ?
                                    '${controller.tenantFirstName.value}${controller.tenantLastName.value}' :
                                    '${createAccountController.firstName.value}${createAccountController.lastName.value}',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    maxLines: 2,
                                  ),
                                  ReusableTextWidget(
                                    text: controller.tenantEmail.value.isNotEmpty ? controller.tenantEmail.value :
                                    createAccountController.emailController.text,
                                    fontSize: 16,
                                    maxLines: 2,
                                  ),
                                ],
                              ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20,),
                      ListTile(
                        leading: const Icon(Icons.person, color: Colors.black),
                        title: const ReusableTextWidget(
                          text: 'Profile Information',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        onTap: () {
                          Get.to(() => ProfileInformationScreen());
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.feedback, color: Colors.black),
                        title: const ReusableTextWidget(
                          text: "FAQ's",
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        onTap: () {
                          Get.to(() =>
                             const WebViewApp(
                             url: 'https://www.plotrol.com/faq',
                             appBarText: "FAQ's",
                           )
                          );
                        },
                      ),

                      // Payment History
                      // ListTile(
                      //   leading: Icon(Icons.payment, color: Colors.black),
                      //   title: const ReusableTextWidget(
                      //     text: 'PaymentHistory',
                      //     fontSize: 16,
                      //     fontWeight: FontWeight.w600,
                      //   ),
                      //   onTap: () {
                      //     // Handle payment history action
                      //   },
                      // ),

                      // Settings
                      // ListTile(
                      //   leading: Icon(Icons.settings, color: Colors.black),
                      //   title:  ReusableTextWidget(
                      //     text: 'Settings',
                      //     fontSize: 16,
                      //     fontWeight: FontWeight.w600,
                      //   ),
                      //   onTap: () {
                      //     // Handle settings action
                      //   },
                      // ),

                      // Add Users (admin only)
                      if (controller.isPGRAdmin.value)
                        ListTile(
                          leading: const Icon(Icons.person_add, color: Colors.black),
                          title: const ReusableTextWidget(
                            text: 'Add Users',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          onTap: () {
                            Get.to(() => AddHelpdeskUserScreen());
                          },
                        ),

                      // Logout
                      ListTile(
                        leading: Icon(Icons.logout, color: Colors.black),
                          title:  ReusableTextWidget(
                            text: 'Logout',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          onTap: () {
                            profileScreenController.logout();
                            },
                       ),
                    ],
                  ),
                ),
              );
            }
          );
        },
      )
    );
  }
}
