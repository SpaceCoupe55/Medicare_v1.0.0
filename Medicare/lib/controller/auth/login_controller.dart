import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:medicare/helpers/widgets/my_form_validator.dart';
import 'package:medicare/helpers/widgets/my_validators.dart';
import 'package:medicare/services/auth_service.dart';
import 'package:get/get.dart';
import 'package:medicare/views/my_controller.dart';

class LoginController extends MyController {
  MyFormValidator basicValidator = MyFormValidator();

  bool showPassword = false, loading = false, isChecked = false;

  final AuthService _authService = AuthService();

  @override
  void onInit() {
    basicValidator.addField(
      'email',
      required: true,
      label: "Email",
      validators: [MyEmailValidator()],
      controller: TextEditingController(),
    );
    basicValidator.addField(
      'password',
      required: true,
      label: "Password",
      validators: [MyLengthValidator(min: 6, max: 50)],
      controller: TextEditingController(),
    );
    super.onInit();
  }

  void onChangeCheckBox(bool? value) {
    isChecked = value ?? isChecked;
    update();
  }

  void onChangeShowPassword() {
    showPassword = !showPassword;
    update();
  }

  Future<void> onLogin() async {
    if (!basicValidator.validateForm()) return;

    loading = true;
    update();

    try {
      final email = basicValidator.getController('email')!.text.trim();
      final password = basicValidator.getController('password')!.text;

      await _authService.signInWithEmail(email, password);

      // AppAuthController will fetch the Firestore profile via userStream.
      // Navigate immediately — the middleware uses FirebaseAuth.currentUser.
      final nextUrl =
          Uri.parse(Get.currentRoute).queryParameters['next'] ?? '/dashboard';
      Get.offAllNamed(nextUrl);
    } on FirebaseAuthException catch (e) {
      basicValidator.addErrors({'email': _mapFirebaseError(e.code)});
      basicValidator.validateForm();
      basicValidator.clearErrors();
    } finally {
      loading = false;
      update();
    }
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'invalid-email':
        return 'No account found for this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect password. Please try again.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      default:
        return 'Login failed. Please try again.';
    }
  }

  void goToForgotPassword() {
    Get.toNamed('/auth/forgot_password');
  }

  void gotoRegister() {
    Get.offAndToNamed('/auth/register_account');
  }
}
