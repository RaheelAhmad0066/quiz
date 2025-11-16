import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../app_widgets/validation_mixin.dart';
import 'auth_controller.dart';

/// Signup Screen Controller
class SignupController extends GetxController with ValidationMixin {
  final AuthController authController = Get.find<AuthController>();

  // Form Key - regenerated on each init
  late GlobalKey<FormState> formKey;

  // Text Controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Observables
  final obscurePassword = true.obs;
  final obscureConfirmPassword = true.obs;

  @override
  void onInit() {
    super.onInit();
    // Create new form key on each initialization
    formKey = GlobalKey<FormState>();
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  /// Toggle password visibility
  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  /// Toggle confirm password visibility
  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword.value = !obscureConfirmPassword.value;
  }

  /// Handle signup
  void handleSignup() {
    if (formKey.currentState!.validate()) {
      authController.signUpWithEmailPassword(
        emailController.text.trim(),
        nameController.text.trim(),
        passwordController.text,
      );
    }
  }
}

