import 'package:flutter/material.dart';
import 'package:medicare/controller/ui/setting_controller.dart';
import 'package:medicare/helpers/theme/app_style.dart';
import 'package:medicare/helpers/utils/ui_mixins.dart';
import 'package:medicare/helpers/widgets/my_breadcrumb.dart';
import 'package:medicare/helpers/widgets/my_breadcrumb_item.dart';
import 'package:medicare/helpers/widgets/my_button.dart';
import 'package:medicare/helpers/widgets/my_container.dart';
import 'package:medicare/helpers/widgets/my_flex.dart';
import 'package:medicare/helpers/widgets/my_flex_item.dart';
import 'package:medicare/helpers/widgets/my_spacing.dart';
import 'package:medicare/helpers/widgets/my_text.dart';
import 'package:medicare/helpers/widgets/my_text_style.dart';
import 'package:medicare/helpers/widgets/responsive.dart';
import 'package:medicare/images.dart';
import 'package:medicare/views/layout/layout.dart';
import 'package:get/get.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen>
    with SingleTickerProviderStateMixin, UIMixin {
  late SettingController controller;

  @override
  void initState() {
    controller = Get.put(SettingController());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Layout(
      child: GetBuilder(
        init: controller,
        builder: (controller) {
          return Column(
            children: [
              Padding(
                padding: MySpacing.x(flexSpacing),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MyText.titleMedium("Settings", fontSize: 18, fontWeight: 600),
                    MyBreadcrumb(
                      children: [
                        MyBreadcrumbItem(name: 'Admin'),
                        MyBreadcrumbItem(name: 'Settings', active: true),
                      ],
                    ),
                  ],
                ),
              ),
              MySpacing.height(flexSpacing),
              Padding(
                padding: MySpacing.x(flexSpacing / 2),
                child: MyFlex(
                  children: [
                    // ── Profile ──────────────────────────────────────────────
                    MyFlexItem(
                      sizes: "lg-6",
                      child: MyContainer(
                        borderRadiusAll: 12,
                        paddingAll: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MyText.titleMedium("Profile", fontWeight: 600),
                            MySpacing.height(20),
                            MyContainer.rounded(
                              height: 100,
                              width: 100,
                              paddingAll: 0,
                              clipBehavior: Clip.antiAliasWithSaveLayer,
                              child: Image.asset(
                                Images.avatars[2],
                                fit: BoxFit.cover,
                              ),
                            ),
                            MySpacing.height(20),
                            buildTextField(
                              "First Name",
                              "Enter your first name",
                              controller: controller.firstNameTE,
                            ),
                            MySpacing.height(20),
                            buildTextField(
                              "Last Name",
                              "Enter your last name",
                              controller: controller.lastNameTE,
                            ),
                            MySpacing.height(20),
                            buildTextField(
                              "Email Address",
                              "Email address",
                              controller: controller.emailTE,
                              readOnly: true,
                            ),
                            MySpacing.height(16),
                            MyButton(
                              onPressed: controller.savingProfile
                                  ? null
                                  : controller.saveProfile,
                              elevation: 0,
                              padding: MySpacing.xy(20, 16),
                              backgroundColor: contentTheme.primary,
                              borderRadiusAll: AppStyle.buttonRadius.medium,
                              child: controller.savingProfile
                                  ? SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: contentTheme.onPrimary,
                                      ),
                                    )
                                  : MyText.bodySmall(
                                      'Save Profile',
                                      color: contentTheme.onPrimary,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Change Password ───────────────────────────────────────
                    MyFlexItem(
                      sizes: "lg-6",
                      child: MyContainer(
                        borderRadiusAll: 12,
                        paddingAll: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MyText.titleMedium("Change Password", fontWeight: 600),
                            MySpacing.height(20),
                            buildTextField(
                              "Current Password",
                              "Enter current password",
                              controller: controller.currentPasswordTE,
                              obscureText: !controller.showCurrentPassword,
                              onToggleVisibility: controller.toggleCurrentPassword,
                            ),
                            MySpacing.height(20),
                            buildTextField(
                              "New Password",
                              "Enter new password",
                              controller: controller.newPasswordTE,
                              obscureText: !controller.showNewPassword,
                              onToggleVisibility: controller.toggleNewPassword,
                            ),
                            MySpacing.height(20),
                            buildTextField(
                              "Confirm Password",
                              "Confirm new password",
                              controller: controller.confirmPasswordTE,
                              obscureText: !controller.showConfirmPassword,
                              onToggleVisibility: controller.toggleConfirmPassword,
                            ),
                            MySpacing.height(16),
                            MyButton(
                              onPressed: controller.savingPassword
                                  ? null
                                  : controller.changePassword,
                              elevation: 0,
                              padding: MySpacing.xy(20, 16),
                              backgroundColor: contentTheme.primary,
                              borderRadiusAll: AppStyle.buttonRadius.medium,
                              child: controller.savingPassword
                                  ? SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: contentTheme.onPrimary,
                                      ),
                                    )
                                  : MyText.bodySmall(
                                      'Update Password',
                                      color: contentTheme.onPrimary,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Hospital Settings (admin only) ────────────────────────
                    if (controller.isAdmin)
                      MyFlexItem(
                        sizes: "lg-12",
                        child: MyContainer(
                          borderRadiusAll: 12,
                          paddingAll: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MyText.titleMedium(
                                "Hospital Settings",
                                fontWeight: 600,
                              ),
                              MySpacing.height(4),
                              MyText.bodySmall(
                                "Visible to admin users only. These details are stored in the hospitals collection.",
                                muted: true,
                              ),
                              MySpacing.height(20),
                              MyFlex(
                                children: [
                                  MyFlexItem(
                                    sizes: "lg-6",
                                    child: buildTextField(
                                      "Hospital Name",
                                      "Enter hospital name",
                                      controller: controller.hospitalNameTE,
                                    ),
                                  ),
                                  MyFlexItem(
                                    sizes: "lg-6",
                                    child: buildTextField(
                                      "Contact Number",
                                      "Enter contact number",
                                      controller: controller.hospitalContactTE,
                                    ),
                                  ),
                                ],
                              ),
                              MySpacing.height(16),
                              MyButton(
                                onPressed: controller.savingHospital
                                    ? null
                                    : controller.saveHospital,
                                elevation: 0,
                                padding: MySpacing.xy(20, 16),
                                backgroundColor: contentTheme.primary,
                                borderRadiusAll: AppStyle.buttonRadius.medium,
                                child: controller.savingHospital
                                    ? SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: contentTheme.onPrimary,
                                        ),
                                      )
                                    : MyText.bodySmall(
                                        'Save Hospital Settings',
                                        color: contentTheme.onPrimary,
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget buildTextField(
    String fieldTitle,
    String hintText, {
    TextEditingController? controller,
    bool readOnly = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyText.labelMedium(fieldTitle),
        MySpacing.height(8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          obscureText: obscureText,
          style: MyTextStyle.bodySmall(),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: MyTextStyle.bodySmall(xMuted: true),
            border: outlineInputBorder,
            contentPadding: MySpacing.all(16),
            isCollapsed: true,
            floatingLabelBehavior: FloatingLabelBehavior.never,
            suffixIcon: onToggleVisibility != null
                ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off : Icons.visibility,
                      size: 18,
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
