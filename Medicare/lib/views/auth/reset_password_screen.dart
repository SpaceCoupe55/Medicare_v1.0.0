import 'package:medicare/controller/auth/reset_password_controller.dart';
import 'package:medicare/helpers/theme/app_themes.dart';
import 'package:medicare/helpers/utils/ui_mixins.dart';
import 'package:medicare/helpers/widgets/my_button.dart';
import 'package:medicare/helpers/widgets/my_spacing.dart';
import 'package:medicare/helpers/widgets/my_text.dart';
import 'package:medicare/helpers/widgets/my_text_style.dart';
import 'package:medicare/views/layout/auth_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> with UIMixin {
  late ResetPasswordController controller;

  @override
  void initState() {
    controller = Get.put(ResetPasswordController());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      child: GetBuilder(
        init: controller,
        tag: 'reset_password_controller',
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
                    MyText.headlineSmall("Reset Password", fontWeight: 600),
                    MySpacing.height(20),
                    MyText.bodySmall("Please choose a password thai hasn't been used before. Must be at least 10 character", muted: true),
                    MySpacing.height(20),
                    MyText.labelMedium("Password", fontWeight: 600,muted: true),
                    MySpacing.height(8),
                    TextFormField(
                      validator: controller.basicValidator.getValidation('password'),
                      controller: controller.basicValidator.getController('password'),
                      style: MyTextStyle.bodySmall(),
                      decoration: InputDecoration(
                          labelText: "Password",
                          labelStyle: MyTextStyle.bodySmall(xMuted: true),
                          border: outlineInputBorder,
                          suffixIcon: InkWell(
                            onTap: () => controller.onChangeShowPassword(),
                            child: Icon(controller.showPassword ? LucideIcons.eye_off : LucideIcons.eye, size: 20),
                          ),
                          contentPadding: MySpacing.all(16),
                          isCollapsed: true,
                          floatingLabelBehavior: FloatingLabelBehavior.never),
                      obscureText: controller.showPassword,
                    ),
                    MySpacing.height(20),
                    MyText.labelMedium("Confirm Password", fontWeight: 600,muted: true),
                    MySpacing.height(8),
                    TextFormField(
                      validator: controller.basicValidator.getValidation('confirm_password'),
                      controller: controller.basicValidator.getController('confirm_password'),
                      style: MyTextStyle.bodySmall(),
                      decoration: InputDecoration(
                          labelText: "Confirm Password",
                          labelStyle: MyTextStyle.bodySmall(xMuted: true),
                          border: outlineInputBorder,
                          suffixIcon: InkWell(
                            onTap: () => controller.onConfirmPassword(),
                            child: Icon(controller.confirmPassword ? LucideIcons.eye_off : LucideIcons.eye, size: 20),
                          ),
                          contentPadding: MySpacing.all(16),
                          isCollapsed: true,
                          floatingLabelBehavior: FloatingLabelBehavior.never),
                      obscureText: controller.confirmPassword,
                    ),
                    MySpacing.height(20),
                    Center(
                      child: MyButton.rounded(
                        onPressed: controller.onResetPassword,
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
                                    child: CircularProgressIndicator(
                                      color: theme.colorScheme.onPrimary,
                                      strokeWidth: 1.2,
                                    ),
                                  )
                                : Container(),
                            if (controller.loading) MySpacing.width(16),
                            MyText.labelMedium(
                              'Reset Password',fontWeight: 600,
                              color: contentTheme.onPrimary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )),
          );
        },
      ),
    );
  }
}
