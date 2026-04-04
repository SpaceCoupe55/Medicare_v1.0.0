import 'package:flutter/material.dart';
import 'package:medicare/controller/auth/forgot_password_controller.dart';
import 'package:medicare/helpers/theme/app_themes.dart';
import 'package:medicare/helpers/utils/ui_mixins.dart';
import 'package:medicare/helpers/widgets/my_button.dart';
import 'package:medicare/helpers/widgets/my_spacing.dart';
import 'package:medicare/helpers/widgets/my_text.dart';
import 'package:medicare/helpers/widgets/my_text_style.dart';
import 'package:get/get.dart';
import 'package:medicare/views/layout/auth_layout.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> with SingleTickerProviderStateMixin, UIMixin {
  late ForgotPasswordController controller;

  @override
  void initState() {
    controller = Get.put(ForgotPasswordController());
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MyText.headlineSmall(
                      "Forgot Password",
                      fontWeight: 600,
                    ),
                    MySpacing.height(20),
                    MyText.bodySmall("Enter your email to receive instructions for recovering your password.",  muted: true),
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
                        hintText: "Email Address",
                        hintStyle: MyTextStyle.bodySmall(xMuted: true),
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
                            MyText.bodySmall(
                              'Forgot Password',
                              color: contentTheme.onPrimary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Center(
                      child: MyButton.text(
                        onPressed: controller.gotoLogIn,
                        elevation: 0,
                        padding: MySpacing.x(16),
                        splashColor: contentTheme.secondary.withOpacity(0.1),
                        child: MyText.labelMedium(
                          'Back To Log In',
                          color: contentTheme.secondary,
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
