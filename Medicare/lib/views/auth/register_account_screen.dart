import 'package:flutter/material.dart';
import 'package:medicare/controller/auth/register_account_controller.dart';
import 'package:medicare/helpers/theme/app_themes.dart';
import 'package:medicare/helpers/utils/ui_mixins.dart';
import 'package:medicare/helpers/widgets/my_button.dart';
import 'package:medicare/helpers/widgets/my_spacing.dart';
import 'package:medicare/helpers/widgets/my_text.dart';
import 'package:medicare/helpers/widgets/my_text_style.dart';
import 'package:medicare/views/layout/auth_layout.dart';
import 'package:get/get.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class RegisterAccountScreen extends StatefulWidget {
  const RegisterAccountScreen({super.key});

  @override
  State<RegisterAccountScreen> createState() => _RegisterAccountScreenState();
}

class _RegisterAccountScreenState extends State<RegisterAccountScreen> with SingleTickerProviderStateMixin, UIMixin {
  late RegisterAccountController controller;

  @override
  void initState() {
    controller = Get.put(RegisterAccountController());
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
                children: [
                  MyText.headlineSmall("Register", fontWeight: 600),
                  MySpacing.height(20),
                  MyText.bodySmall("Welcome! Please activate your account by filling out the details below", muted: true),
                  MySpacing.height(20),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MyText.labelMedium("First Name", fontWeight: 600, muted: true),
                            MySpacing.height(8),
                            TextFormField(
                              validator: controller.basicValidator.getValidation('first_name'),
                              controller: controller.basicValidator.getController('first_name'),
                              keyboardType: TextInputType.emailAddress,
                              style: MyTextStyle.bodySmall(),
                              decoration: InputDecoration(
                                labelText: "First Name",
                                labelStyle: MyTextStyle.bodySmall(xMuted: true),
                                border: outlineInputBorder,
                                prefixIcon: const Icon(LucideIcons.user, size: 20),
                                contentPadding: MySpacing.all(16),
                                isCollapsed: true,
                                floatingLabelBehavior: FloatingLabelBehavior.never,
                              ),
                            ),
                          ],
                        ),
                      ),
                      MySpacing.width(20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MyText.labelMedium("Last Name", fontWeight: 600, muted: true),
                            MySpacing.height(8),
                            TextFormField(
                              validator: controller.basicValidator.getValidation('last_name'),
                              controller: controller.basicValidator.getController('last_name'),
                              keyboardType: TextInputType.emailAddress,
                              style: MyTextStyle.bodySmall(),
                              decoration: InputDecoration(
                                labelText: "Last Name",
                                labelStyle: MyTextStyle.bodySmall(xMuted: true),
                                border: outlineInputBorder,
                                prefixIcon: const Icon(
                                  LucideIcons.user,
                                  size: 20,
                                ),
                                contentPadding: MySpacing.all(16),
                                isCollapsed: true,
                                floatingLabelBehavior: FloatingLabelBehavior.never,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
                      border: outlineInputBorder,
                      prefixIcon: const Icon(
                        LucideIcons.mail,
                        size: 20,
                      ),
                      contentPadding: MySpacing.all(16),
                      isCollapsed: true,
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                    ),
                  ),
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
                        border: outlineInputBorder,
                        prefixIcon: const Icon(
                          LucideIcons.lock,
                          size: 20,
                        ),
                        suffixIcon: InkWell(
                          onTap: controller.onChangeShowPassword,
                          child: Icon(
                            controller.showPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            size: 20,
                          ),
                        ),
                        contentPadding: MySpacing.all(16),
                        isCollapsed: true,
                        floatingLabelBehavior: FloatingLabelBehavior.never),
                  ),
                  MySpacing.height(30),
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
                                  child: CircularProgressIndicator(
                                    color: theme.colorScheme.onPrimary,
                                    strokeWidth: 1.2,
                                  ),
                                )
                              : Container(),
                          if (controller.loading) MySpacing.width(16),
                          MyText.labelMedium(
                            'Register',
                            fontWeight: 600,
                            color: contentTheme.onPrimary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: MyButton.text(
                      onPressed: controller.gotoLogin,
                      elevation: 0,
                      padding: MySpacing.x(16),
                      splashColor: contentTheme.secondary.withOpacity(0.1),
                      child: MyText.labelMedium(
                        'Already have account ?',
                        color: contentTheme.secondary,
                      ),
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
