import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';
import '../controller/add_helpdesk_user_controller.dart';
import '../globalWidgets/text_widget.dart';

class AddHelpdeskUserScreen extends StatelessWidget {
  AddHelpdeskUserScreen({super.key});

  final AddHelpdeskUserController controller =
      Get.put(AddHelpdeskUserController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const ReusableTextWidget(
          text: 'Add Helpdesk User',
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ReusableTextWidget(
              text: 'Create a new gig worker account',
              fontSize: 14,
              color: Colors.grey,
            ),
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
            Obx(() => TextField(
              controller: controller.passwordController,
              obscureText: controller.obscurePassword.value,
              decoration: _inputDecoration('Enter password (min 6 chars)').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.obscurePassword.value
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: controller.togglePasswordVisibility,
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
                color: Colors.black,
                borderRadius: 10,
                child: const ReusableTextWidget(
                  text: 'Create User',
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Center(
              child: ReusableTextWidget(
                text: 'The user can log in using their mobile number and password.',
                fontSize: 12,
                color: Colors.grey,
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return ReusableTextWidget(
      text: text,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      maxLength: maxLength,
      decoration: _inputDecoration(hint),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: 13,
        fontFamily: 'Raleway',
        color: Colors.grey,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.grey, width: 0.8),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.grey, width: 0.8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.black, width: 1.2),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      counterText: '',
    );
  }
}
