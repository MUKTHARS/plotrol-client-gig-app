import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';
import '../controller/add_helpdesk_user_controller.dart';
import '../globalWidgets/text_widget.dart';

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

class AddHelpdeskUserScreen extends StatelessWidget {
  AddHelpdeskUserScreen({super.key});

  final AddHelpdeskUserController controller =
      Get.put(AddHelpdeskUserController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        elevation: 0,
        title: const Text(
          'Add Helpdesk User',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: _espresso,
            letterSpacing: -0.8,
            height: 1.1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const SizedBox(height: 24),

            // Full Name
            _buildLabel('Full Name *'),
            const SizedBox(height: 6),
            _buildTextField(
              controller: controller.nameController,
              hint: 'Enter full name',
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // Mobile Number
            _buildLabel('Mobile Number *'),
            const SizedBox(height: 6),
            _buildTextField(
              controller: controller.mobileController,
              hint: 'Enter mobile number',
              keyboardType: TextInputType.phone,
              maxLength: 15,
            ),
            const SizedBox(height: 16),

            // Email (optional)
            _buildLabel('Email (optional)'),
            const SizedBox(height: 6),
            _buildTextField(
              controller: controller.emailController,
              hint: 'Enter email address',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            // Password
            _buildLabel('Password *'),
            const SizedBox(height: 6),
            Obx(() => Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _dividerLine),
              ),
              child: TextField(
                controller: controller.passwordController,
                obscureText: controller.obscurePassword.value,
                style: const TextStyle(
                  fontSize: 15,
                  color: _espresso,
                  fontWeight: FontWeight.w500,
                ),
                decoration: _inputDecoration('Enter password (min 6 chars)').copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.obscurePassword.value
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: _steel,
                      size: 20,
                    ),
                    onPressed: controller.togglePasswordVisibility,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            )),
            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: RoundedLoadingButton(
                controller: controller.btnController,
                onPressed: controller.createUser,
                color: _espresso,
                borderRadius: 14,
                child: const Text(
                  'Create User',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const Text(
                'The user can log in using their mobile number and password.',
                style: TextStyle(
                  fontSize: 11,
                  color: _steel,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: _espresso,
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int? maxLength,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _dividerLine),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        maxLength: maxLength,
        style: const TextStyle(
          fontSize: 15,
          color: _espresso,
          fontWeight: FontWeight.w500,
        ),
        decoration: _inputDecoration(hint).copyWith(
          counterText: '',
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: 14,
        color: _steel,
        fontWeight: FontWeight.w400,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
    );
  }
}