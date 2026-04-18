import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:medicare/controller/ui/doctor_portal_controller.dart';
import 'package:medicare/helpers/theme/admin_theme.dart';
import 'package:medicare/helpers/theme/app_themes.dart';
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

// ── Status helpers ─────────────────────────────────────────────────────────────

Color _statusColor(AppointmentStatus s, ContentTheme ct) {
  switch (s) {
    case AppointmentStatus.scheduled:
      return ct.primary;
    case AppointmentStatus.completed:
      return ct.success;
    case AppointmentStatus.cancelled:
      return ct.danger;
  }
}

String _statusLabel(AppointmentStatus s) {
  switch (s) {
    case AppointmentStatus.scheduled:
      return 'Scheduled';
    case AppointmentStatus.completed:
      return 'Completed';
    case AppointmentStatus.cancelled:
      return 'Cancelled';
  }
}

// ── Screen ─────────────────────────────────────────────────────────────────────

class DoctorPortalScreen extends StatefulWidget {
  const DoctorPortalScreen({super.key});

  @override
  State<DoctorPortalScreen> createState() => _DoctorPortalScreenState();
}

class _DoctorPortalScreenState extends State<DoctorPortalScreen> with UIMixin {
  DoctorPortalController controller = Get.put(DoctorPortalController());

  @override
  Widget build(BuildContext context) {
    return Layout(
      child: GetBuilder<DoctorPortalController>(
        init: controller,
        tag: 'doctor_portal_controller',
        builder: (ctrl) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────────────────────
              Padding(
                padding: MySpacing.x(flexSpacing),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MyText.titleMedium('My Portal', fontSize: 18, fontWeight: 600),
                    MyBreadcrumb(
                      children: [
                        MyBreadcrumbItem(name: 'Doctor'),
                        MyBreadcrumbItem(name: 'My Portal', active: true),
                      ],
                    ),
                  ],
                ),
              ),
              MySpacing.height(flexSpacing),

              if (ctrl.loadingProfile)
                const Center(child: CircularProgressIndicator())
              else if (ctrl.profileError != null)
                _buildProfileError(ctrl.profileError!)
              else ...[
                // ── Profile banner ─────────────────────────────────────────
                _buildProfileBanner(ctrl),
                MySpacing.height(flexSpacing),

                // ── Stats row ──────────────────────────────────────────────
                Padding(
                  padding: MySpacing.x(flexSpacing),
                  child: _buildStatsRow(ctrl),
                ),
                MySpacing.height(flexSpacing),

                // ── Appointments columns ───────────────────────────────────
                Padding(
                  padding: MySpacing.x(flexSpacing),
                  child: MyFlex(
                    children: [
                      MyFlexItem(
                        sizes: 'lg-6',
                        child: _buildAppointmentSection(
                          title: "Today's Appointments",
                          icon: LucideIcons.calendar_check,
                          appointments: ctrl.todayAppointments,
                          loading: ctrl.loadingAppointments,
                          emptyMessage: 'No appointments scheduled for today.',
                          ctrl: ctrl,
                          showActions: true,
                        ),
                      ),
                      MyFlexItem(
                        sizes: 'lg-6',
                        child: _buildAppointmentSection(
                          title: 'Upcoming (next 14 days)',
                          icon: LucideIcons.calendar_clock,
                          appointments: ctrl.upcomingAppointments,
                          loading: ctrl.loadingAppointments,
                          emptyMessage: 'No upcoming appointments.',
                          ctrl: ctrl,
                          showActions: false,
                        ),
                      ),
                    ],
                  ),
                ),
                MySpacing.height(flexSpacing),
              ],
            ],
          );
        },
      ),
    );
  }

  // ── Profile banner ──────────────────────────────────────────────────────────

  Widget _buildProfileBanner(DoctorPortalController ctrl) {
    final doc = ctrl.myProfile!;
    return Padding(
      padding: MySpacing.x(flexSpacing),
      child: MyContainer(
        paddingAll: 20,
        borderRadiusAll: 12,
        child: Row(
          children: [
            MyContainer(
              paddingAll: 0,
              borderRadiusAll: 50,
              clipBehavior: Clip.antiAliasWithSaveLayer,
              child: doc.avatarUrl.isNotEmpty
                  ? Image.network(doc.avatarUrl,
                      width: 64, height: 64, fit: BoxFit.cover)
                  : Container(
                      width: 64,
                      height: 64,
                      color: contentTheme.primary.withAlpha(30),
                      child: Icon(LucideIcons.user_round,
                          size: 32, color: contentTheme.primary),
                    ),
            ),
            MySpacing.width(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText.titleLarge(doc.doctorName, fontWeight: 700),
                  MySpacing.height(4),
                  Row(
                    children: [
                      Icon(LucideIcons.stethoscope,
                          size: 14, color: contentTheme.primary),
                      MySpacing.width(6),
                      MyText.bodySmall(doc.specialization, muted: true),
                      MySpacing.width(16),
                      Icon(LucideIcons.graduation_cap,
                          size: 14, color: theme.hintColor),
                      MySpacing.width(6),
                      MyText.bodySmall(doc.degree, muted: true),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Stats row ───────────────────────────────────────────────────────────────

  Widget _buildStatsRow(DoctorPortalController ctrl) {
    return MyFlex(
      children: [
        MyFlexItem(
          sizes: 'lg-4',
          child: _statCard(
            icon: LucideIcons.calendar_days,
            label: "Today's Patients",
            value: ctrl.todayCount.toString(),
            color: contentTheme.primary,
          ),
        ),
        MyFlexItem(
          sizes: 'lg-4',
          child: _statCard(
            icon: LucideIcons.clock,
            label: 'Pending Today',
            value: ctrl.pendingCount.toString(),
            color: contentTheme.warning,
          ),
        ),
        MyFlexItem(
          sizes: 'lg-4',
          child: _statCard(
            icon: LucideIcons.calendar_clock,
            label: 'Upcoming (14 days)',
            value: ctrl.upcomingCount.toString(),
            color: contentTheme.info,
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return MyContainer(
      paddingAll: 20,
      borderRadiusAll: 12,
      child: Row(
        children: [
          MyContainer(
            paddingAll: 10,
            borderRadiusAll: 10,
            color: color.withAlpha(25),
            child: Icon(icon, size: 22, color: color),
          ),
          MySpacing.width(14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MyText.headlineSmall(value, fontWeight: 700),
              MyText.bodySmall(label, muted: true),
            ],
          ),
        ],
      ),
    );
  }

  // ── Appointment section ─────────────────────────────────────────────────────

  Widget _buildAppointmentSection({
    required String title,
    required IconData icon,
    required List<AppointmentModel> appointments,
    required bool loading,
    required String emptyMessage,
    required DoctorPortalController ctrl,
    required bool showActions,
  }) {
    return MyContainer(
      paddingAll: 20,
      borderRadiusAll: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: contentTheme.primary),
              MySpacing.width(8),
              MyText.titleMedium(title, fontWeight: 700),
            ],
          ),
          MySpacing.height(16),
          if (loading)
            const Center(child: CircularProgressIndicator())
          else if (appointments.isEmpty)
            Center(
              child: Padding(
                padding: MySpacing.y(24),
                child: Column(
                  children: [
                    Icon(LucideIcons.calendar_x,
                        size: 40, color: theme.hintColor),
                    MySpacing.height(8),
                    MyText.bodySmall(emptyMessage, muted: true),
                  ],
                ),
              ),
            )
          else
            Column(
              children: appointments
                  .map((a) => _apptCard(a, ctrl, showActions))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _apptCard(
      AppointmentModel appt, DoctorPortalController ctrl, bool showActions) {
    final statusColor = _statusColor(appt.status, contentTheme);
    final timeStr = DateFormat('h:mm a').format(appt.time);
    final dateStr = showActions
        ? timeStr
        : DateFormat('MMM d · h:mm a').format(appt.date);

    return Container(
      margin: MySpacing.bottom(10),
      padding: MySpacing.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MyText.bodyMedium(appt.name, fontWeight: 600),
                    MySpacing.height(2),
                    Row(
                      children: [
                        Icon(LucideIcons.clock,
                            size: 12, color: theme.hintColor),
                        MySpacing.width(4),
                        MyText.bodySmall(dateStr, muted: true),
                        if (appt.treatment.isNotEmpty) ...[
                          MySpacing.width(10),
                          Icon(LucideIcons.notepad_text,
                              size: 12, color: theme.hintColor),
                          MySpacing.width(4),
                          Flexible(
                            child: MyText.bodySmall(
                              appt.treatment,
                              muted: true,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Status chip
              Container(
                padding: MySpacing.xy(8, 4),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: MyText(
                  _statusLabel(appt.status),
                  style: MyTextStyle.bodySmall(
                    color: statusColor,
                    fontWeight: 600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          if (showActions && appt.patientId.isNotEmpty) ...[
            MySpacing.height(10),
            Row(
              children: [
                MyButton.outlined(
                  onPressed: () => ctrl.goToPatient(appt.patientId),
                  padding: MySpacing.xy(10, 6),
                  borderColor: contentTheme.primary,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.file_pen,
                          size: 13, color: contentTheme.primary),
                      MySpacing.width(5),
                      MyText(
                        'Write Note',
                        style: MyTextStyle.bodySmall(
                            color: contentTheme.primary, fontWeight: 600),
                      ),
                    ],
                  ),
                ),
                if (appt.status == AppointmentStatus.scheduled) ...[
                  MySpacing.width(8),
                  MyButton(
                    onPressed: () => ctrl.markCompleted(appt),
                    padding: MySpacing.xy(10, 6),
                    backgroundColor: contentTheme.success,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.circle_check,
                            size: 13, color: contentTheme.onSuccess),
                        MySpacing.width(5),
                        MyText(
                          'Mark Done',
                          style: MyTextStyle.bodySmall(
                              color: contentTheme.onSuccess, fontWeight: 600),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Profile error ───────────────────────────────────────────────────────────

  Widget _buildProfileError(String message) {
    return Padding(
      padding: MySpacing.x(flexSpacing),
      child: MyContainer(
        paddingAll: 32,
        borderRadiusAll: 12,
        child: Center(
          child: Column(
            children: [
              Icon(LucideIcons.user_x, size: 48, color: contentTheme.danger),
              MySpacing.height(12),
              MyText.bodyLarge('Doctor profile not linked', fontWeight: 600),
              MySpacing.height(8),
              MyText.bodyMedium(
                message,
                muted: true,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
