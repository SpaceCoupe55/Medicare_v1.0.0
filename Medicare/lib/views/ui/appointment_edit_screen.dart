import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';
import 'package:medicare/app_constant.dart';
import 'package:medicare/controller/ui/appointment_edit_controller.dart';
import 'package:medicare/helpers/extention/date_time_extention.dart';
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
import 'package:medicare/models/appointment_model.dart';
import 'package:medicare/views/layout/layout.dart';

class AppointmentEditScreen extends StatefulWidget {
  const AppointmentEditScreen({super.key});

  @override
  State<AppointmentEditScreen> createState() => _AppointmentEditScreenState();
}

class _AppointmentEditScreenState extends State<AppointmentEditScreen>
    with UIMixin {
  late AppointmentEditController controller;

  @override
  void initState() {
    controller = Get.put(AppointmentEditController());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Layout(
      child: GetBuilder(
        init: controller,
        tag: 'admin_appointment_edit_controller',
        builder: (controller) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: MySpacing.x(flexSpacing),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MyText.titleMedium('Edit Appointment',
                        fontSize: 18, fontWeight: 600),
                    MyBreadcrumb(
                      children: [
                        MyBreadcrumbItem(name: 'Operations'),
                        MyBreadcrumbItem(name: 'Appointments'),
                        MyBreadcrumbItem(name: 'Edit', active: true),
                      ],
                    ),
                  ],
                ),
              ),
              MySpacing.height(flexSpacing),
              Padding(
                padding: MySpacing.x(flexSpacing),
                child: MyContainer(
                  paddingAll: 24,
                  borderRadiusAll: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (controller.loading)
                        const Center(
                            child: Padding(
                                padding: EdgeInsets.all(40),
                                child: CircularProgressIndicator()))
                      else ...[
                        if (controller.errorMessage != null) ...[
                          Container(
                            padding: MySpacing.all(12),
                            decoration: BoxDecoration(
                              color: contentTheme.danger.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: MyText.bodySmall(controller.errorMessage!,
                                color: contentTheme.danger),
                          ),
                          MySpacing.height(16),
                        ],
                        MyText.bodyMedium('Patient Details', fontWeight: 600),
                        MySpacing.height(20),
                        _patientDetails(controller),
                        MySpacing.height(20),
                        MyText.bodyMedium('Appointment Details',
                            fontWeight: 600),
                        MySpacing.height(20),
                        _appointmentDetail(controller),
                        MySpacing.height(20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            MyButton(
                              onPressed: controller.saving
                                  ? null
                                  : controller.submit,
                              elevation: 0,
                              borderRadiusAll: 12,
                              backgroundColor: contentTheme.primary,
                              child: controller.saving
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: contentTheme.onPrimary),
                                    )
                                  : MyText.labelMedium('Save Changes',
                                      fontWeight: 600,
                                      color: contentTheme.onPrimary),
                            ),
                            MySpacing.width(12),
                            MyButton.outlined(
                              onPressed: () => Get.back(),
                              borderRadiusAll: 12,
                              borderColor:
                                  contentTheme.secondary.withAlpha(80),
                              backgroundColor: contentTheme.secondary,
                              elevation: 0,
                              child:
                                  MyText.labelMedium('Cancel', fontWeight: 600),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _patientDetails(AppointmentEditController c) {
    return MyFlex(
      contentPadding: false,
      children: [
        MyFlexItem(
          sizes: 'lg-6 md-6',
          child: Column(
            children: [
              _field('First Name', 'First Name', LucideIcons.user_round,
                  c.firstNameTE),
              MySpacing.height(20),
              _field('Last Name', 'Last Name', LucideIcons.user_round,
                  c.lastNameTE),
              MySpacing.height(20),
              _field('Address', 'Address', LucideIcons.map_pin, c.addressTE),
            ],
          ),
        ),
        MyFlexItem(
          sizes: 'lg-6 md-6',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _field('Mobile Number', 'Mobile Number', LucideIcons.phone_call,
                  c.mobileNumberTE),
              MySpacing.height(20),
              _field('Email Address', 'Email Address', LucideIcons.mail,
                  c.emailTE),
            ],
          ),
        ),
      ],
    );
  }

  Widget _appointmentDetail(AppointmentEditController c) {
    return MyFlex(contentPadding: false, children: [
      MyFlexItem(
        sizes: 'lg-4 md-6',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MyText.labelMedium('Date of appointment',
                fontWeight: 600, muted: true),
            MySpacing.height(8),
            TextFormField(
              onTap: c.pickDate,
              readOnly: true,
              controller: TextEditingController(
                  text: c.selectedDate != null
                      ? dateFormatter.format(c.selectedDate!)
                      : ''),
              style: MyTextStyle.bodySmall(),
              decoration: InputDecoration(
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                hintText: 'Date of appointment',
                hintStyle: MyTextStyle.bodySmall(fontWeight: 600, muted: true),
                isCollapsed: true,
                isDense: true,
                prefixIcon: const Icon(LucideIcons.calendar),
                contentPadding: MySpacing.all(16),
              ),
            ),
          ],
        ),
      ),
      MyFlexItem(
        sizes: 'lg-4 md-6',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MyText.labelMedium('From', fontWeight: 600, muted: true),
            MySpacing.height(8),
            TextFormField(
              onTap: c.fromPickTime,
              readOnly: true,
              controller: TextEditingController(
                  text: c.fromSelectedTime != null
                      ? timeFormatter
                          .format(DateTime.now().applied(c.fromSelectedTime!))
                      : ''),
              style: MyTextStyle.bodySmall(),
              decoration: InputDecoration(
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                hintText: 'From',
                hintStyle: MyTextStyle.bodySmall(fontWeight: 600, muted: true),
                isCollapsed: true,
                isDense: true,
                prefixIcon: const Icon(LucideIcons.clock_3),
                contentPadding: MySpacing.all(16),
              ),
            ),
          ],
        ),
      ),
      MyFlexItem(
        sizes: 'lg-4 md-6',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MyText.labelMedium('To', fontWeight: 600, muted: true),
            MySpacing.height(8),
            TextFormField(
              onTap: c.toPickTime,
              readOnly: true,
              controller: TextEditingController(
                  text: c.toSelectedTime != null
                      ? timeFormatter
                          .format(DateTime.now().applied(c.toSelectedTime!))
                      : ''),
              style: MyTextStyle.bodySmall(),
              decoration: InputDecoration(
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                hintText: 'To',
                hintStyle: MyTextStyle.bodySmall(fontWeight: 600, muted: true),
                isCollapsed: true,
                isDense: true,
                prefixIcon: const Icon(LucideIcons.clock_3),
                contentPadding: MySpacing.all(16),
              ),
            ),
          ],
        ),
      ),
      MyFlexItem(
        sizes: 'lg-6 md-6',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MyText.labelMedium('Consulting Doctor',
                fontWeight: 600, muted: true),
            MySpacing.height(8),
            c.loadingDoctors
                ? const SizedBox(
                    height: 48,
                    child: Center(
                        child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))))
                : c.availableDoctors.isEmpty
                    ? MyText.bodySmall('No doctors available', muted: true)
                    : DropdownButtonFormField<String>(
                        value: c.availableDoctors
                                .any((d) =>
                                    d.doctorName == c.selectedConsultingDoctor)
                            ? c.selectedConsultingDoctor
                            : null,
                        decoration: InputDecoration(
                          hintText: 'Select doctor',
                          hintStyle: MyTextStyle.bodySmall(xMuted: true),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          contentPadding: MySpacing.all(12),
                          isCollapsed: true,
                          isDense: true,
                          prefixIcon:
                              const Icon(LucideIcons.user_plus, size: 16),
                          floatingLabelBehavior: FloatingLabelBehavior.never,
                        ),
                        dropdownColor: contentTheme.background,
                        onChanged: (v) => c.onSelectedConsultingDoctor(v!),
                        items: c.availableDoctors
                            .map((d) => DropdownMenuItem<String>(
                                  value: d.doctorName,
                                  child: MyText.bodySmall(d.doctorName,
                                      fontWeight: 600),
                                ))
                            .toList(),
                      ),
          ],
        ),
      ),
      MyFlexItem(
        sizes: 'lg-3 md-6',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MyText.labelMedium('Status', fontWeight: 600, muted: true),
            MySpacing.height(8),
            DropdownButtonFormField<AppointmentStatus>(
              value: c.selectedStatus,
              decoration: InputDecoration(
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: MySpacing.all(12),
                isCollapsed: true,
                isDense: true,
                prefixIcon:
                    const Icon(LucideIcons.circle_check_big, size: 16),
                floatingLabelBehavior: FloatingLabelBehavior.never,
              ),
              dropdownColor: contentTheme.background,
              onChanged: (v) => c.onSelectedStatus(v!),
              items: AppointmentStatus.values
                  .map((s) => DropdownMenuItem<AppointmentStatus>(
                        value: s,
                        child: MyText.bodySmall(
                            s.name[0].toUpperCase() + s.name.substring(1),
                            fontWeight: 600),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
      MyFlexItem(
        sizes: 'lg-3 md-6',
        child: _field('Notes / Treatment', 'Treatment detail',
            LucideIcons.heart_pulse, c.treatmentTE),
      ),
    ]);
  }

  Widget _field(String title, String hint, IconData icon,
      TextEditingController te) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyText.labelMedium(title, fontWeight: 600, muted: true),
        MySpacing.height(8),
        TextFormField(
          controller: te,
          style: MyTextStyle.bodySmall(),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            hintText: hint,
            hintStyle: MyTextStyle.bodySmall(fontWeight: 600, muted: true),
            isCollapsed: true,
            isDense: true,
            prefixIcon: Icon(icon, size: 16),
            contentPadding: MySpacing.all(16),
          ),
        ),
      ],
    );
  }
}
