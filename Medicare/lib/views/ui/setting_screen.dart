import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';
import 'package:medicare/controller/auth_controller.dart';
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
import 'package:medicare/views/layout/layout.dart';

// ── Avatar helpers (shared with top_bar) ─────────────────────────────────────

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

Color _avatarColor(String name) {
  const palette = [
    Color(0xFF5C6BC0),
    Color(0xFF26A69A),
    Color(0xFFEC407A),
    Color(0xFF8D6E63),
    Color(0xFF7E57C2),
    Color(0xFF26C6DA),
    Color(0xFF66BB6A),
    Color(0xFFF57C00),
  ];
  return palette[name.hashCode.abs() % palette.length];
}

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
      child: GetBuilder<SettingController>(
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
                    // ── Profile info ─────────────────────────────────────────
                    MyFlexItem(
                      sizes: "lg-6",
                      child: MyContainer(
                        borderRadiusAll: 12,
                        paddingAll: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MyText.titleMedium("Personal Info", fontWeight: 600),
                            MySpacing.height(20),

                            // ── Avatar section ────────────────────────────────
                            _buildAvatarSection(controller),
                            MySpacing.height(24),

                            buildTextField("First Name", "Enter your first name",
                                controller: controller.firstNameTE),
                            MySpacing.height(16),
                            buildTextField("Last Name", "Enter your last name",
                                controller: controller.lastNameTE),
                            MySpacing.height(16),
                            buildTextField("Phone", "Enter phone number",
                                controller: controller.phoneTE,
                                keyboardType: TextInputType.phone),
                            MySpacing.height(16),
                            buildTextField("Email Address", "Email address",
                                controller: controller.emailTE,
                                readOnly: true),
                            MySpacing.height(20),
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
                                          color: contentTheme.onPrimary))
                                  : MyText.bodySmall('Save Profile',
                                      color: contentTheme.onPrimary),
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
                            MySpacing.height(8),
                            MyText.bodySmall("Minimum 8 characters.",
                                muted: true),
                            MySpacing.height(20),
                            buildTextField("Current Password",
                                "Enter current password",
                                controller: controller.currentPasswordTE,
                                obscureText: !controller.showCurrentPassword,
                                onToggleVisibility:
                                    controller.toggleCurrentPassword),
                            MySpacing.height(16),
                            buildTextField("New Password", "Enter new password",
                                controller: controller.newPasswordTE,
                                obscureText: !controller.showNewPassword,
                                onToggleVisibility: controller.toggleNewPassword),
                            MySpacing.height(16),
                            buildTextField(
                                "Confirm Password", "Confirm new password",
                                controller: controller.confirmPasswordTE,
                                obscureText: !controller.showConfirmPassword,
                                onToggleVisibility:
                                    controller.toggleConfirmPassword),
                            MySpacing.height(20),
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
                                          color: contentTheme.onPrimary))
                                  : MyText.bodySmall('Update Password',
                                      color: contentTheme.onPrimary),
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
                              MyText.titleMedium("Hospital Settings",
                                  fontWeight: 600),
                              MySpacing.height(4),
                              MyText.bodySmall(
                                  "Visible to admin users only.",
                                  muted: true),
                              MySpacing.height(20),
                              MyFlex(
                                children: [
                                  MyFlexItem(
                                    sizes: "lg-6",
                                    child: buildTextField("Hospital Name",
                                        "Enter hospital name",
                                        controller: controller.hospitalNameTE),
                                  ),
                                  MyFlexItem(
                                    sizes: "lg-6",
                                    child: buildTextField("Contact Number",
                                        "Enter contact number",
                                        controller:
                                            controller.hospitalContactTE),
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
                                            color: contentTheme.onPrimary))
                                    : MyText.bodySmall('Save Hospital Settings',
                                        color: contentTheme.onPrimary),
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

  // ── Avatar section ────────────────────────────────────────────────────────

  Widget _buildAvatarSection(SettingController ctrl) {
    final authCtrl = AppAuthController.instance;
    final name = authCtrl.userName;
    final avatarUrl = authCtrl.userAvatarUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyText.labelMedium("Profile Photo", fontWeight: 600, muted: true),
        MySpacing.height(12),
        Row(
          children: [
            // Current avatar
            Stack(
              children: [
                _buildAvatarDisplay(name, avatarUrl, 80),
                if (ctrl.savingAvatar)
                  Positioned.fill(
                    child: ClipOval(
                      child: Container(
                        color: Colors.black45,
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            value: ctrl.uploadProgress,
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            MySpacing.width(20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyButton(
                  onPressed: ctrl.savingAvatar ? null : ctrl.pickAndUploadAvatar,
                  elevation: 0,
                  padding: MySpacing.xy(16, 10),
                  backgroundColor: contentTheme.primary,
                  borderRadiusAll: AppStyle.buttonRadius.medium,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.upload,
                          size: 14, color: contentTheme.onPrimary),
                      MySpacing.width(6),
                      MyText.labelSmall('Change photo',
                          color: contentTheme.onPrimary, fontWeight: 600),
                    ],
                  ),
                ),
                if (ctrl.uploadProgress != null) ...[
                  MySpacing.height(8),
                  SizedBox(
                    width: 140,
                    child: LinearProgressIndicator(
                      value: ctrl.uploadProgress,
                      backgroundColor:
                          contentTheme.primary.withAlpha(30),
                      color: contentTheme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  MySpacing.height(4),
                  MyText.bodySmall(
                    '${((ctrl.uploadProgress ?? 0) * 100).toInt()}%',
                    muted: true,
                  ),
                ] else ...[
                  MySpacing.height(6),
                  MyText.bodySmall('JPG, PNG or WebP — max 5 MB',
                      muted: true),
                ],
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvatarDisplay(String name, String? avatarUrl, double size) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          avatarUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initialsCircle(name, size),
        ),
      );
    }
    return _initialsCircle(name, size);
  }

  Widget _initialsCircle(String name, double size) {
    return Container(
      width: size,
      height: size,
      decoration:
          BoxDecoration(color: _avatarColor(name), shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        _initials(name),
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.36,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ── Text field builder ────────────────────────────────────────────────────

  Widget buildTextField(
    String fieldTitle,
    String hintText, {
    TextEditingController? controller,
    bool readOnly = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType? keyboardType,
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
          keyboardType: keyboardType,
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
