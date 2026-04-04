import 'package:flutter/material.dart';
import 'package:medicare/controller/auth/login_controller.dart';
import 'package:medicare/helpers/theme/app_themes.dart';
import 'package:medicare/helpers/utils/ui_mixins.dart';
import 'package:medicare/helpers/widgets/my_button.dart';
import 'package:medicare/helpers/widgets/my_spacing.dart';
import 'package:medicare/helpers/widgets/my_text.dart';
import 'package:medicare/helpers/widgets/my_text_style.dart';
import 'package:medicare/views/layout/auth_layout.dart';
import 'package:get/get.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin, UIMixin {
  late LoginController controller;

  @override
  void initState() {
    controller = Get.put(LoginController());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      child: GetBuilder(
        init: controller,
        builder: (controller) {
          return Padding(
            padding: MySpacing.all(24),
            child: Form(
              key: controller.basicValidator.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  MyText.headlineSmall("LogIn", fontWeight: 600),
                  MySpacing.height(20),
                  MyText.bodySmall("Welcome back! Please enter your details.", muted: true),
                  MySpacing.height(20),
                  MyText.labelMedium("Email Address", fontWeight: 600, muted: true),
                  MySpacing.height(8),
                  TextFormField(
                      validator: controller.basicValidator.getValidation('email'),
                      controller: controller.basicValidator.getController('email'),
                      keyboardType: TextInputType.emailAddress,
                      style: MyTextStyle.bodySmall(),
                      decoration: InputDecoration(
                          labelText: "Email Address",
                          labelStyle: MyTextStyle.bodySmall(xMuted: true),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(LucideIcons.mail, size: 20),
                          contentPadding: MySpacing.all(16),
                          isCollapsed: true,
                          floatingLabelBehavior: FloatingLabelBehavior.never)),
                  MySpacing.height(20),
                  MyText.labelMedium("Password", fontWeight: 600, muted: true),
                  MySpacing.height(8),
                  TextFormField(
                    validator: controller.basicValidator.getValidation('password'),
                    controller: controller.basicValidator.getController('password'),
                    keyboardType: TextInputType.visiblePassword,
                    obscureText: !controller.showPassword,
                    style: MyTextStyle.bodySmall(),
                    decoration: InputDecoration(
                        labelText: "Password",
                        labelStyle: MyTextStyle.bodySmall(xMuted: true),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(
                          LucideIcons.lock,
                          size: 20,
                        ),
                        suffixIcon: InkWell(
                          onTap: controller.onChangeShowPassword,
                          child: Icon(
                            controller.showPassword ? LucideIcons.eye : LucideIcons.eye_off,
                            size: 20,
                          ),
                        ),
                        contentPadding: MySpacing.all(16),
                        isCollapsed: true,
                        floatingLabelBehavior: FloatingLabelBehavior.never),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () => controller.onChangeCheckBox(!controller.isChecked),
                        child: Row(
                          children: [
                            Checkbox(
                              onChanged: controller.onChangeCheckBox,
                              value: controller.isChecked,
                              fillColor: WidgetStateProperty.resolveWith((states) {
                                if (!states.contains(WidgetState.selected)) {
                                  return Colors.white;
                                }
                                return null;
                              }),
                              activeColor: theme.colorScheme.primary,
                              overlayColor: WidgetStatePropertyAll(Colors.white),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: getCompactDensity,
                            ),
                            MySpacing.width(8),
                            MyText.labelMedium("Remember Me", fontWeight: 600, muted: true),
                          ],
                        ),
                      ),
                      MyButton.text(
                        onPressed: controller.goToForgotPassword,
                        elevation: 0,
                        padding: MySpacing.xy(8, 0),
                        splashColor: contentTheme.secondary.withOpacity(0.1),
                        child: MyText.labelMedium('Forgot password?', fontWeight: 600, muted: true),
                      ),
                    ],
                  ),
                  MySpacing.height(28),
                  Center(
                    child: MyButton.rounded(
                      onPressed: controller.onLogin,
                      elevation: 0,
                      padding: MySpacing.xy(20, 16),
                      backgroundColor: contentTheme.primary,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          controller.loading
                              ? SizedBox(
                                  height: 14,
                                  width: 14,
                                  child: CircularProgressIndicator(color: theme.colorScheme.onPrimary, strokeWidth: 1.2),
                                )
                              : Container(),
                          if (controller.loading) MySpacing.width(16),
                          MyText.labelMedium('Login',fontWeight: 600, color: contentTheme.onPrimary),
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: MyButton.text(
                      onPressed: controller.gotoRegister,
                      elevation: 0,
                      padding: MySpacing.x(16),
                      splashColor: contentTheme.secondary.withOpacity(0.1),
                      child: MyText.labelMedium('I haven\'t account', color: contentTheme.secondary),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
