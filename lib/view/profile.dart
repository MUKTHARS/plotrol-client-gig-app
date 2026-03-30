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
      backgroundColor: _cream,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: _cream,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: _espresso,
            letterSpacing: -0.8,
            height: 1.0,
          ),
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // Profile Card
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: _dividerLine),
                          boxShadow: [
                            BoxShadow(
                              color: _espresso.withOpacity(0.06),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              // Avatar
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _sand,
                                  border: Border.all(color: _sienna, width: 2),
                                ),
                                child: ClipOval(
                                  child: (controller.tenantProfileImage.value.isNotEmpty || 
                                          createAccountController.profileImage != null)
                                      ? (controller.tenantProfileImage.value.isNotEmpty
                                          ? Image.network(
                                              controller.tenantProfileImage.value,
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return _buildInitialsAvatar(controller);
                                              },
                                            )
                                          : Image.file(
                                              File(createAccountController.profileImage?.path ?? ''),
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                            ))
                                      : _buildInitialsAvatar(controller),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // User Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      controller.tenantFirstName.value.isNotEmpty
                                          ? '${controller.tenantFirstName.value} ${controller.tenantLastName.value}'
                                          : '${createAccountController.firstName.value} ${createAccountController.lastName.value}',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: _espresso,
                                        letterSpacing: -0.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      controller.tenantEmail.value.isNotEmpty 
                                          ? controller.tenantEmail.value
                                          : createAccountController.emailController.text,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: _steel,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Menu Items Container
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: _dividerLine),
                          boxShadow: [
                            BoxShadow(
                              color: _espresso.withOpacity(0.06),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildMenuItem(
                              icon: Icons.person_outline,
                              title: 'Profile Information',
                              onTap: () {
                                Get.to(() => ProfileInformationScreen());
                              },
                            ),
                            const Divider(height: 1, color: _dividerLine),
                            _buildMenuItem(
                              icon: Icons.help_outline,
                              title: "FAQ's",
                              onTap: () {
                                Get.to(() => const WebViewApp(
                                  url: 'https://www.plotrol.com/faq',
                                  appBarText: "FAQ's",
                                ));
                              },
                            ),
                            // Add Users (admin only)
                            if (controller.isPGRAdmin.value) ...[
                              const Divider(height: 1, color: _dividerLine),
                              _buildMenuItem(
                                icon: Icons.person_add_alt_1_outlined,
                                title: 'Add Users',
                                onTap: () {
                                  Get.to(() => AddHelpdeskUserScreen());
                                },
                              ),
                            ],
                            const Divider(height: 1, color: _dividerLine),
                            _buildMenuItem(
                              icon: Icons.logout_outlined,
                              title: 'Logout',
                              onTap: () {
                                profileScreenController.logout();
                              },
                              isDestructive: true,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Version Info
                      Center(
                        child: Text(
                          'Version 1.0.0',
                          style: TextStyle(
                            fontSize: 11,
                            color: _steel.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          );
        },
      ),
    );
  }

  Widget _buildInitialsAvatar(HomeScreenController controller) {
    final initials = authenticationController.getInitials(
      controller.name.value ?? '', 
      controller.lastName.value
    ) ?? 'U';
    
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: _sienna,
          fontSize: 28,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _siennaLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isDestructive ? Colors.red : _sienna,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDestructive ? Colors.red : _walnut,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: _steel,
            ),
          ],
        ),
      ),
    );
  }
}