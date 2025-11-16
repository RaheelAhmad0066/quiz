import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../app_widgets/validation_mixin.dart';
import 'auth_controller.dart';

/// Login Screen Controller
class LoginController extends GetxController with ValidationMixin {
  final AuthController authController = Get.find<AuthController>();

  // Form Key - regenerated on each init
  late GlobalKey<FormState> formKey;

  // Text Controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Observables
  final obscurePassword = true.obs;

  @override
  void onInit() {
    super.onInit();
    // Create new form key on each initialization
    formKey = GlobalKey<FormState>();
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  /// Toggle password visibility
  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  /// Handle login
  void handleLogin() {
    if (formKey.currentState!.validate()) {
      authController.signInWithEmailPassword(
        emailController.text.trim(),
        passwordController.text,
      );
    }
  }
}

