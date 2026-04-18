import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';
import 'package:medicare/controller/auth_controller.dart';
import 'package:medicare/controller/ui/patient_detail_controller.dart';
import 'package:medicare/helpers/theme/app_style.dart';
import 'package:medicare/helpers/theme/app_themes.dart';
import 'package:medicare/helpers/utils/ui_mixins.dart';
import 'package:medicare/helpers/widgets/responsive.dart';
import 'package:medicare/helpers/widgets/my_breadcrumb.dart';
import 'package:medicare/helpers/widgets/my_breadcrumb_item.dart';
import 'package:medicare/helpers/widgets/my_button.dart';
import 'package:medicare/helpers/widgets/my_container.dart';
import 'package:medicare/helpers/widgets/my_flex.dart';
import 'package:medicare/helpers/widgets/my_flex_item.dart';
import 'package:medicare/helpers/widgets/my_spacing.dart';
import 'package:medicare/helpers/widgets/my_text.dart';
import 'package:medicare/helpers/widgets/my_text_style.dart';
import 'package:medicare/models/appointment_model.dart';
import 'package:medicare/models/medical_record_model.dart';
import 'package:medicare/models/patient_model.dart';
import 'package:medicare/models/pharmacy_model.dart';
import 'package:medicare/models/prescription_model.dart';
import 'package:medicare/models/vitals_model.dart';
import 'package:medicare/route_names.dart';
import 'package:medicare/views/layout/layout.dart';

// ── Color helpers ──────────────────────────────────────────────────────────

Color _recordTypeColor(RecordType type) {
  switch (type) {
    case RecordType.note:
      return const Color(0xFF1976D2);
    case RecordType.diagnosis:
      return const Color(0xFFD32F2F);
    case RecordType.prescription:
      return const Color(0xFF388E3C);
    case RecordType.lab_result:
      return const Color(0xFFF57C00);
  }
}

Color _statusColor(AppointmentStatus status) {
  switch (status) {
    case AppointmentStatus.scheduled:
      return const Color(0xFF1976D2);
    case AppointmentStatus.completed:
      return const Color(0xFF388E3C);
    case AppointmentStatus.cancelled:
      return const Color(0xFFD32F2F);
  }
}

Color _vitalStatusColor(String status) {
  switch (status) {
    case 'normal':
      return const Color(0xFF388E3C);
    case 'elevated':
      return const Color(0xFFF57C00);
    case 'high':
      return const Color(0xFFD32F2F);
    case 'low':
      return const Color(0xFF1976D2);
    case 'critical':
      return const Color(0xFFB71C1C);
    default:
      return const Color(0xFF9E9E9E);
  }
}

Color _labFlagColor(String flag) {
  switch (flag) {
    case 'high':
      return const Color(0xFFD32F2F);
    case 'low':
      return const Color(0xFF1976D2);
    case 'critical':
      return const Color(0xFFB71C1C);
    default:
      return const Color(0xFF388E3C);
  }
}

String _pad(int n) => n.toString().padLeft(2, '0');
String _formatDate(DateTime d) => '${_pad(d.day)}/${_pad(d.month)}/${d.year}';
String _formatDateTime(DateTime d) =>
    '${_pad(d.day)}/${_pad(d.month)}/${d.year}  ${_pad(d.hour)}:${_pad(d.minute)}';

int _age(DateTime dob) {
  final now = DateTime.now();
  int age = now.year - dob.year;
  if (now.month < dob.month ||
      (now.month == dob.month && now.day < dob.day)) age--;
  return age;
}

// ── Screen ─────────────────────────────────────────────────────────────────

class PatientDetailScreen extends StatefulWidget {
  const PatientDetailScreen({super.key});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen>
    with SingleTickerProviderStateMixin, UIMixin {
  late PatientDetailController controller;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    controller = Get.put(PatientDetailController());
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        controller.onTabChanged(_tabController.index);
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Layout(
      child: GetBuilder<PatientDetailController>(
        init: controller,
        builder: (ctrl) {
          if (ctrl.loadingPatient) {
            return const Center(
                child: Padding(
                    padding: EdgeInsets.all(48),
                    child: CircularProgressIndicator()));
          }
          if (ctrl.errorMessage != null || ctrl.patient == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: MyText.bodyMedium(
                    ctrl.errorMessage ?? 'Patient not found.',
                    muted: true),
              ),
            );
          }

          final patient = ctrl.patient!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: MySpacing.x(flexSpacing),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MyText.titleMedium('Patient Profile',
                        fontSize: 18, fontWeight: 600),
                    MyBreadcrumb(children: [
                      MyBreadcrumbItem(name: 'Patients'),
                      MyBreadcrumbItem(name: patient.name, active: true),
                    ]),
                  ],
                ),
              ),
              MySpacing.height(flexSpacing),

              Padding(
                padding: MySpacing.x(flexSpacing / 2),
                child: _headerCard(patient, ctrl),
              ),
              MySpacing.height(16),

              Padding(
                padding: MySpacing.x(flexSpacing / 2),
                child: MyContainer(
                  borderRadiusAll: 12,
                  paddingAll: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        tabs: const [
                          Tab(text: 'Overview'),
                          Tab(text: 'Medical Records'),
                          Tab(text: 'Vitals'),
                          Tab(text: 'Appointments'),
                        ],
                      ),
                      const Divider(height: 1, thickness: 1),
                      Padding(
                        padding: MySpacing.all(20),
                        child: IndexedStack(
                          index: _tabController.index,
                          children: [
                            _overviewTab(patient, ctrl),
                            _recordsTab(ctrl),
                            _vitalsTab(ctrl),
                            _appointmentsTab(ctrl),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              MySpacing.height(flexSpacing),
            ],
          );
        },
      ),
    );
  }

  // ── Header card ────────────────────────────────────────────────────────────

  Widget _headerCard(PatientModel patient, PatientDetailController ctrl) {
    final initials = _initials(patient.name);
    final bgColor = _avatarColor(patient.name);
    final isActive = patient.status.toLowerCase() == 'active';

    return MyContainer(
      borderRadiusAll: 12,
      paddingAll: 20,
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(initials,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold)),
          ),
          MySpacing.width(20),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                MyText.titleMedium(patient.name, fontWeight: 600),
                MySpacing.width(12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF388E3C).withAlpha(30)
                        : Colors.grey.withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    patient.status.toUpperCase(),
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isActive
                            ? const Color(0xFF388E3C)
                            : Colors.grey[600]),
                  ),
                ),
              ]),
              MySpacing.height(4),
              Row(children: [
                Icon(LucideIcons.calendar, size: 13, color: theme.hintColor),
                MySpacing.width(4),
                MyText.bodySmall(
                    '${_age(patient.birthDate)} yrs  ·  ${patient.gender}',
                    muted: true),
                MySpacing.width(16),
                Icon(LucideIcons.droplets, size: 13, color: theme.hintColor),
                MySpacing.width(4),
                MyText.bodySmall(
                    patient.bloodGroup.isEmpty ? '—' : patient.bloodGroup,
                    muted: true),
              ]),
            ]),
          ),
          MyButton(
            onPressed: () =>
                Get.toNamed(AppRoutes.patientEdit, arguments: patient),
            elevation: 0,
            padding: MySpacing.xy(16, 10),
            backgroundColor: contentTheme.primary,
            borderRadiusAll: AppStyle.buttonRadius.medium,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(LucideIcons.pencil, size: 14, color: contentTheme.onPrimary),
              MySpacing.width(6),
              MyText.labelSmall('Edit',
                  color: contentTheme.onPrimary, fontWeight: 600),
            ]),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 1 — Overview
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _overviewTab(PatientModel patient, PatientDetailController ctrl) {
    return MyFlex(
      children: [
        // Left: Patient info
        MyFlexItem(
          sizes: 'lg-6',
          child: Column(children: [
            MyContainer(
              borderRadiusAll: 10,
              paddingAll: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText.labelLarge('Patient Information', fontWeight: 600),
                  MySpacing.height(16),
                  _infoRow(LucideIcons.user, 'Full Name', patient.name),
                  _divider(),
                  _infoRow(LucideIcons.calendar, 'Date of Birth',
                      _formatDate(patient.birthDate)),
                  _divider(),
                  _infoRow(LucideIcons.cake, 'Age',
                      '${_age(patient.birthDate)} years'),
                  _divider(),
                  _infoRow(LucideIcons.users, 'Gender',
                      patient.gender.isEmpty ? '—' : patient.gender),
                  _divider(),
                  _infoRow(LucideIcons.droplets, 'Blood Type',
                      patient.bloodGroup.isEmpty ? '—' : patient.bloodGroup),
                  _divider(),
                  _infoRow(LucideIcons.phone, 'Phone',
                      patient.mobileNumber.isEmpty ? '—' : patient.mobileNumber),
                  _divider(),
                  _infoRow(LucideIcons.mail, 'Email',
                      patient.email.isEmpty ? '—' : patient.email),
                  _divider(),
                  _infoRow(LucideIcons.map_pin, 'Address',
                      patient.address.isEmpty ? '—' : patient.address),
                  _divider(),
                  _infoRow(LucideIcons.calendar_plus, 'Registered',
                      _formatDate(patient.createdAt)),
                ],
              ),
            ),

            MySpacing.height(16),

            // Emergency contact
            if (patient.emergencyContact.isNotEmpty ||
                patient.emergencyPhone.isNotEmpty)
              MyContainer(
                borderRadiusAll: 10,
                paddingAll: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(LucideIcons.phone_call,
                          size: 14, color: contentTheme.danger),
                      MySpacing.width(6),
                      MyText.labelLarge('Emergency Contact', fontWeight: 600),
                    ]),
                    MySpacing.height(12),
                    _infoRow(LucideIcons.user, 'Name',
                        patient.emergencyContact.isEmpty
                            ? '—'
                            : patient.emergencyContact),
                    _divider(),
                    _infoRow(LucideIcons.phone, 'Phone',
                        patient.emergencyPhone.isEmpty
                            ? '—'
                            : patient.emergencyPhone),
                  ],
                ),
              ),
          ]),
        ),

        // Right: Doctor + stats + allergies + conditions
        MyFlexItem(
          sizes: 'lg-6',
          child: Column(children: [
            // Assigned doctor
            MyContainer(
              borderRadiusAll: 10,
              paddingAll: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText.labelLarge('Assigned Doctor', fontWeight: 600),
                  MySpacing.height(16),
                  if (ctrl.loadingDoctor)
                    const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                  else if (patient.assignedDoctorId.isEmpty)
                    MyText.bodySmall('No doctor assigned.', muted: true)
                  else
                    Row(children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                            color: Color(0xFF5C6BC0), shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: const Icon(LucideIcons.stethoscope,
                            size: 18, color: Colors.white),
                      ),
                      MySpacing.width(12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MyText.bodyMedium(
                              ctrl.assignedDoctorName ??
                                  patient.assignedDoctorId,
                              fontWeight: 600),
                          GestureDetector(
                            onTap: () => Get.toNamed(AppRoutes.doctorDetail,
                                arguments: patient.assignedDoctorId),
                            child: MyText.bodySmall('View profile',
                                color: contentTheme.primary),
                          ),
                        ],
                      ),
                    ]),
                ],
              ),
            ),

            MySpacing.height(16),

            // Visit stats
            MyContainer(
              borderRadiusAll: 10,
              paddingAll: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText.labelLarge('Visit Summary', fontWeight: 600),
                  MySpacing.height(16),
                  Row(children: [
                    Expanded(
                      child: _statCard(
                        icon: LucideIcons.clipboard_list,
                        label: 'Total Records',
                        value: ctrl.totalVisits.toString(),
                        color: contentTheme.primary,
                      ),
                    ),
                    MySpacing.width(16),
                    Expanded(
                      child: _statCard(
                        icon: LucideIcons.calendar_check,
                        label: 'Last Visit',
                        value: ctrl.lastVisitDate != null
                            ? _formatDate(ctrl.lastVisitDate!)
                            : '—',
                        color: const Color(0xFF26A69A),
                      ),
                    ),
                  ]),
                ],
              ),
            ),

            MySpacing.height(16),

            // Allergies
            MyContainer(
              borderRadiusAll: 10,
              paddingAll: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(LucideIcons.triangle_alert,
                        size: 14, color: contentTheme.danger),
                    MySpacing.width(6),
                    MyText.labelLarge('Allergies', fontWeight: 600),
                  ]),
                  MySpacing.height(12),
                  patient.allergies.isEmpty
                      ? MyText.bodySmall('No known allergies.', muted: true)
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: patient.allergies
                              .map((a) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: contentTheme.danger.withAlpha(20),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color:
                                              contentTheme.danger.withAlpha(80)),
                                    ),
                                    child: MyText.bodySmall(a,
                                        color: contentTheme.danger,
                                        fontWeight: 600,
                                        fontSize: 11),
                                  ))
                              .toList(),
                        ),
                ],
              ),
            ),

            MySpacing.height(16),

            // Chronic conditions
            MyContainer(
              borderRadiusAll: 10,
              paddingAll: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(LucideIcons.heart_pulse,
                        size: 14, color: const Color(0xFF7B1FA2)),
                    MySpacing.width(6),
                    MyText.labelLarge('Chronic Conditions', fontWeight: 600),
                  ]),
                  MySpacing.height(12),
                  patient.chronicConditions.isEmpty
                      ? MyText.bodySmall('No chronic conditions recorded.',
                          muted: true)
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: patient.chronicConditions
                              .map((c) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF7B1FA2)
                                          .withAlpha(20),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: const Color(0xFF7B1FA2)
                                              .withAlpha(80)),
                                    ),
                                    child: MyText.bodySmall(c,
                                        color: const Color(0xFF7B1FA2),
                                        fontWeight: 600,
                                        fontSize: 11),
                                  ))
                              .toList(),
                        ),
                ],
              ),
            ),

            if (patient.medicalHistory.isNotEmpty) ...[
              MySpacing.height(16),
              MyContainer(
                borderRadiusAll: 10,
                paddingAll: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MyText.labelLarge('Medical History Notes', fontWeight: 600),
                    MySpacing.height(12),
                    MyText.bodySmall(patient.medicalHistory, muted: true),
                  ],
                ),
              ),
            ],
          ]),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 2 — Medical Records
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _recordsTab(PatientDetailController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            MyText.labelLarge('Medical Records', fontWeight: 600),
            if (ctrl.canAddRecord)
              MyButton(
                onPressed: () => _showAddRecordDialog(ctrl),
                elevation: 0,
                padding: MySpacing.xy(16, 10),
                backgroundColor: contentTheme.primary,
                borderRadiusAll: AppStyle.buttonRadius.medium,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(LucideIcons.plus, size: 14, color: contentTheme.onPrimary),
                  MySpacing.width(6),
                  MyText.labelSmall('Add Record',
                      color: contentTheme.onPrimary, fontWeight: 600),
                ]),
              ),
          ],
        ),
        MySpacing.height(16),
        if (ctrl.loadingRecords)
          const Center(
              child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator()))
        else if (ctrl.records.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(children: [
                Icon(LucideIcons.clipboard_x, size: 40, color: theme.hintColor),
                MySpacing.height(12),
                MyText.bodyMedium('No medical records yet.', muted: true),
              ]),
            ),
          )
        else
          Column(
              children: ctrl.records.map((r) => _recordCard(r, ctrl)).toList()),
      ],
    );
  }

  Widget _recordCard(MedicalRecordModel record, PatientDetailController ctrl) {
    final isExpanded = ctrl.expandedRecordId == record.id;
    final color = _recordTypeColor(record.type);
    final preview = record.content.length > 120
        ? '${record.content.substring(0, 120)}…'
        : record.content;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => ctrl.toggleExpanded(record.id),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: color, width: 4)),
            borderRadius: BorderRadius.circular(10),
            color: theme.cardColor,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 4,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(record.type.label.toUpperCase(),
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: color)),
                  ),
                  // Fulfillment badge for prescriptions
                  if (record.type == RecordType.prescription) ...[
                    MySpacing.width(6),
                    Builder(builder: (_) {
                      final rxStatus = ctrl.rxStatusByRecordId[record.id];
                      final isFulfilled =
                          rxStatus == PrescriptionStatus.fulfilled;
                      final badgeColor = isFulfilled
                          ? contentTheme.success
                          : contentTheme.warning;
                      final badgeLabel =
                          rxStatus == null ? 'Pending' : (isFulfilled ? 'Dispensed' : 'Pending');
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: badgeColor.withAlpha(80)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isFulfilled
                                  ? LucideIcons.circle_check
                                  : LucideIcons.clock,
                              size: 10,
                              color: badgeColor,
                            ),
                            const SizedBox(width: 3),
                            Text(badgeLabel,
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: badgeColor)),
                          ],
                        ),
                      );
                    }),
                  ],
                  MySpacing.width(12),
                  Expanded(
                      child:
                          MyText.bodyMedium(record.title, fontWeight: 600)),
                  Icon(
                      isExpanded
                          ? LucideIcons.chevron_up
                          : LucideIcons.chevron_down,
                      size: 16,
                      color: theme.hintColor),
                ]),
                MySpacing.height(8),
                MyText.bodySmall(isExpanded ? record.content : preview,
                    muted: true),

                // Structured prescription items
                if (isExpanded &&
                    record.type == RecordType.prescription &&
                    record.prescriptionItems.isNotEmpty) ...[
                  MySpacing.height(12),
                  _prescriptionTable(record.prescriptionItems),
                ],

                // Structured lab items
                if (isExpanded &&
                    record.type == RecordType.lab_result &&
                    record.labItems.isNotEmpty) ...[
                  MySpacing.height(12),
                  _labTable(record.labItems),
                ],

                MySpacing.height(8),
                Row(children: [
                  Icon(LucideIcons.user_round, size: 12, color: theme.hintColor),
                  MySpacing.width(4),
                  MyText.bodySmall(record.doctorName, muted: true),
                  MySpacing.width(16),
                  Icon(LucideIcons.calendar, size: 12, color: theme.hintColor),
                  MySpacing.width(4),
                  MyText.bodySmall(_formatDate(record.visitDate), muted: true),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _prescriptionTable(List<Map<String, dynamic>> items) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF388E3C).withAlpha(60)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF388E3C).withAlpha(20),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(children: [
              const SizedBox(
                  width: 130,
                  child: Text('Medicine',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold))),
              const SizedBox(
                  width: 80,
                  child: Text('Dosage',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold))),
              const SizedBox(
                  width: 110,
                  child: Text('Frequency',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold))),
              const Expanded(
                  child: Text('Duration',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold))),
            ]),
          ),
          ...items.map((item) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                      top: BorderSide(
                          color: const Color(0xFF388E3C).withAlpha(30))),
                ),
                child: Row(children: [
                  SizedBox(
                      width: 130,
                      child: MyText.bodySmall(
                          item['name'] as String? ?? '—',
                          fontWeight: 600)),
                  SizedBox(
                      width: 80,
                      child: MyText.bodySmall(
                          item['dosage'] as String? ?? '—',
                          muted: true)),
                  SizedBox(
                      width: 110,
                      child: MyText.bodySmall(
                          item['frequency'] as String? ?? '—',
                          muted: true)),
                  Expanded(
                      child: MyText.bodySmall(
                          item['duration'] as String? ?? '—',
                          muted: true)),
                ]),
              )),
        ],
      ),
    );
  }

  Widget _labTable(List<Map<String, dynamic>> items) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFF57C00).withAlpha(60)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF57C00).withAlpha(20),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(children: [
              const Expanded(
                  flex: 3,
                  child: Text('Test',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold))),
              const Expanded(
                  flex: 2,
                  child: Text('Result',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold))),
              const Expanded(
                  flex: 2,
                  child: Text('Reference',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold))),
              const SizedBox(
                  width: 70,
                  child: Text('Flag',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center)),
            ]),
          ),
          ...items.map((item) {
            final flag = item['flag'] as String? ?? 'normal';
            final flagColor = _labFlagColor(flag);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                    top: BorderSide(
                        color: const Color(0xFFF57C00).withAlpha(30))),
              ),
              child: Row(children: [
                Expanded(
                    flex: 3,
                    child: MyText.bodySmall(item['testName'] as String? ?? '—',
                        fontWeight: 600)),
                Expanded(
                    flex: 2,
                    child: MyText.bodySmall(
                        '${item['result'] ?? '—'} ${item['unit'] ?? ''}',
                        muted: true)),
                Expanded(
                    flex: 2,
                    child: MyText.bodySmall(
                        item['referenceRange'] as String? ?? '—',
                        muted: true)),
                SizedBox(
                  width: 70,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: flagColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        flag[0].toUpperCase() + flag.substring(1),
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: flagColor),
                      ),
                    ),
                  ),
                ),
              ]),
            );
          }),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 3 — Vitals
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _vitalsTab(PatientDetailController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            MyText.labelLarge('Vitals', fontWeight: 600),
            if (ctrl.canAddRecord)
              MyButton(
                onPressed: () => _showAddVitalsDialog(ctrl),
                elevation: 0,
                padding: MySpacing.xy(16, 10),
                backgroundColor: contentTheme.primary,
                borderRadiusAll: AppStyle.buttonRadius.medium,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(LucideIcons.plus,
                      size: 14, color: contentTheme.onPrimary),
                  MySpacing.width(6),
                  MyText.labelSmall('Record Vitals',
                      color: contentTheme.onPrimary, fontWeight: 600),
                ]),
              ),
          ],
        ),
        MySpacing.height(16),
        if (ctrl.loadingVitals)
          const Center(
              child:
                  Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
        else if (ctrl.latestVitals == null)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(children: [
                Icon(LucideIcons.heart_pulse,
                    size: 40, color: theme.hintColor),
                MySpacing.height(12),
                MyText.bodyMedium('No vitals recorded yet.', muted: true),
                if (ctrl.canAddRecord) ...[
                  MySpacing.height(12),
                  MyText.bodySmall('Press "Record Vitals" to add the first reading.',
                      muted: true),
                ]
              ]),
            ),
          )
        else ...[
          // Latest reading label
          Row(children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                  color: Color(0xFF388E3C), shape: BoxShape.circle),
            ),
            MySpacing.width(8),
            MyText.labelMedium('Latest Reading', fontWeight: 600, muted: true),
            MySpacing.width(8),
            MyText.bodySmall(
                _formatDateTime(ctrl.latestVitals!.recordedAt),
                muted: true,
                fontSize: 11),
          ]),
          MySpacing.height(12),

          // Vitals grid
          _vitalsGrid(ctrl.latestVitals!),

          if (ctrl.vitalsHistory.length > 1) ...[
            MySpacing.height(24),
            MyText.labelMedium('History', fontWeight: 600, muted: true),
            MySpacing.height(8),
            // History table header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: contentTheme.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                SizedBox(
                    width: 130,
                    child: MyText.labelSmall('Date',
                        color: contentTheme.primary, fontWeight: 600)),
                const Expanded(
                    child: Text('BP',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold))),
                const Expanded(
                    child: Text('Temp',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold))),
                const Expanded(
                    child: Text('Pulse',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold))),
                const Expanded(
                    child: Text('SpO2',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold))),
                SizedBox(
                    width: 90,
                    child: MyText.labelSmall('By',
                        color: contentTheme.primary,
                        fontWeight: 600,
                        textAlign: TextAlign.end)),
              ]),
            ),
            MySpacing.height(4),
            ...ctrl.vitalsHistory.skip(1).map((v) => _vitalsHistoryRow(v)),
          ],
        ],
      ],
    );
  }

  Widget _vitalsGrid(VitalsModel v) {
    return MyFlex(
      children: [
        MyFlexItem(
            sizes: 'lg-3 md-6',
            child: _vitalCard(
                'Blood Pressure',
                v.bpDisplay,
                'mmHg',
                v.bpStatus,
                LucideIcons.heart_pulse,
                const Color(0xFFD32F2F))),
        MyFlexItem(
            sizes: 'lg-3 md-6',
            child: _vitalCard(
                'Temperature',
                v.temperature != null
                    ? '${v.temperature!.toStringAsFixed(1)}°C'
                    : '—',
                '',
                v.tempStatus,
                LucideIcons.thermometer,
                const Color(0xFFF57C00))),
        MyFlexItem(
            sizes: 'lg-3 md-6',
            child: _vitalCard(
                'Pulse',
                v.pulse != null ? '${v.pulse}' : '—',
                'bpm',
                v.pulseStatus,
                LucideIcons.activity,
                const Color(0xFFEC407A))),
        MyFlexItem(
            sizes: 'lg-3 md-6',
            child: _vitalCard(
                'SpO2',
                v.spO2 != null ? '${v.spO2}%' : '—',
                '',
                v.spO2Status,
                LucideIcons.droplets,
                const Color(0xFF1976D2))),
        MyFlexItem(
            sizes: 'lg-4 md-6',
            child: _vitalCard(
                'Weight',
                v.weight != null ? '${v.weight!.toStringAsFixed(1)}' : '—',
                'kg',
                'normal',
                LucideIcons.gauge,
                const Color(0xFF26A69A))),
        MyFlexItem(
            sizes: 'lg-4 md-6',
            child: _vitalCard(
                'Height',
                v.height != null ? '${v.height!.toStringAsFixed(0)}' : '—',
                'cm',
                'normal',
                LucideIcons.ruler,
                const Color(0xFF66BB6A))),
        MyFlexItem(
            sizes: 'lg-4 md-6',
            child: _vitalCard(
                'Resp. Rate',
                v.respiratoryRate != null ? '${v.respiratoryRate}' : '—',
                'br/min',
                v.rrStatus,
                LucideIcons.wind,
                const Color(0xFF5C6BC0))),
      ],
    );
  }

  Widget _vitalCard(String label, String value, String unit, String status,
      IconData icon, Color color) {
    final statusColor = _vitalStatusColor(status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 18, color: color),
            if (status != 'unknown' && status != 'normal')
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status[0].toUpperCase() + status.substring(1),
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: statusColor),
                ),
              ),
          ],
        ),
        MySpacing.height(10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            if (unit.isNotEmpty) ...[
              MySpacing.width(3),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: MyText.bodySmall(unit, muted: true, fontSize: 11),
              ),
            ],
          ],
        ),
        MySpacing.height(4),
        MyText.bodySmall(label, muted: true, fontSize: 11),
      ]),
    );
  }

  Widget _vitalsHistoryRow(VitalsModel v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: theme.cardColor,
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(children: [
          SizedBox(
              width: 130,
              child: MyText.bodySmall(_formatDateTime(v.recordedAt),
                  muted: true, fontSize: 11)),
          Expanded(child: MyText.bodySmall(v.bpDisplay, fontSize: 12)),
          Expanded(
              child: MyText.bodySmall(
                  v.temperature != null
                      ? '${v.temperature!.toStringAsFixed(1)}°C'
                      : '—',
                  fontSize: 12)),
          Expanded(
              child: MyText.bodySmall(
                  v.pulse != null ? '${v.pulse} bpm' : '—',
                  fontSize: 12)),
          Expanded(
              child: MyText.bodySmall(
                  v.spO2 != null ? '${v.spO2}%' : '—',
                  fontSize: 12)),
          SizedBox(
              width: 90,
              child: MyText.bodySmall(v.recordedBy,
                  muted: true, fontSize: 10, textAlign: TextAlign.end)),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 4 — Appointments
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _appointmentsTab(PatientDetailController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            MyText.labelLarge('Appointments', fontWeight: 600),
            MyButton(
              onPressed: () => Get.toNamed(AppRoutes.appointmentBook),
              elevation: 0,
              padding: MySpacing.xy(16, 10),
              backgroundColor: contentTheme.primary,
              borderRadiusAll: AppStyle.buttonRadius.medium,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(LucideIcons.calendar_plus,
                    size: 14, color: contentTheme.onPrimary),
                MySpacing.width(6),
                MyText.labelSmall('Book Appointment',
                    color: contentTheme.onPrimary, fontWeight: 600),
              ]),
            ),
          ],
        ),
        MySpacing.height(16),
        if (ctrl.loadingAppointments)
          const Center(
              child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator()))
        else if (ctrl.appointments.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(children: [
                Icon(LucideIcons.calendar_x, size: 40, color: theme.hintColor),
                MySpacing.height(12),
                MyText.bodyMedium('No appointments found.', muted: true),
              ]),
            ),
          )
        else
          Column(
              children:
                  ctrl.appointments.map((a) => _appointmentRow(a)).toList()),
      ],
    );
  }

  Widget _appointmentRow(AppointmentModel appt) {
    final color = _statusColor(appt.status);
    final label =
        appt.status.name[0].toUpperCase() + appt.status.name.substring(1);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: theme.cardColor,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 4,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(children: [
          Icon(LucideIcons.calendar, size: 16, color: theme.hintColor),
          MySpacing.width(8),
          Expanded(
              flex: 2,
              child: MyText.bodySmall(_formatDateTime(appt.date),
                  fontWeight: 500)),
          Expanded(
            flex: 2,
            child: Row(children: [
              Icon(LucideIcons.stethoscope, size: 13, color: theme.hintColor),
              MySpacing.width(4),
              Flexible(
                  child: MyText.bodySmall(
                      appt.consultingDoctor.isEmpty
                          ? '—'
                          : appt.consultingDoctor,
                      overflow: TextOverflow.ellipsis)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ),
        ]),
      ),
    );
  }

  // ── Dialogs ────────────────────────────────────────────────────────────────

  void _showAddRecordDialog(PatientDetailController ctrl) {
    showDialog(
      context: context,
      builder: (_) => _AddRecordDialog(patientId: ctrl.patientId),
    );
  }

  void _showAddVitalsDialog(PatientDetailController ctrl) {
    showDialog(
      context: context,
      builder: (_) => _AddVitalsDialog(patientId: ctrl.patientId),
    );
  }

  // ── Small helpers ──────────────────────────────────────────────────────────

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(icon, size: 14, color: theme.hintColor),
        MySpacing.width(10),
        SizedBox(
            width: 110,
            child: MyText.bodySmall(label, fontWeight: 600)),
        Expanded(
            child: MyText.bodySmall(value,
                muted: true, overflow: TextOverflow.ellipsis)),
      ]),
    );
  }

  Widget _divider() =>
      Divider(height: 1, thickness: 0.5, color: theme.dividerColor);

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 20, color: color),
        MySpacing.height(8),
        MyText.titleMedium(value, fontWeight: 700, color: color),
        MySpacing.height(2),
        MyText.bodySmall(label, muted: true),
      ]),
    );
  }
}

// ── Avatar helpers ─────────────────────────────────────────────────────────

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

Color _avatarColor(String name) {
  const palette = [
    Color(0xFF5C6BC0), Color(0xFF26A69A), Color(0xFFEC407A),
    Color(0xFF8D6E63), Color(0xFF7E57C2), Color(0xFF26C6DA),
    Color(0xFF66BB6A), Color(0xFFF57C00),
  ];
  return palette[name.hashCode.abs() % palette.length];
}

// ═══════════════════════════════════════════════════════════════════════════
// Add Record Dialog
// ═══════════════════════════════════════════════════════════════════════════

class _MedicineRow {
  final name = TextEditingController();
  final dosage = TextEditingController();
  final frequency = TextEditingController();
  final duration = TextEditingController();
  final instructions = TextEditingController();

  void dispose() {
    name.dispose();
    dosage.dispose();
    frequency.dispose();
    duration.dispose();
    instructions.dispose();
  }

  Map<String, dynamic> toMap() => {
        'name': name.text.trim(),
        'dosage': dosage.text.trim(),
        'frequency': frequency.text.trim(),
        'duration': duration.text.trim(),
        'instructions': instructions.text.trim(),
      };
}

class _LabRow {
  final testName = TextEditingController();
  final result = TextEditingController();
  final unit = TextEditingController();
  final referenceRange = TextEditingController();
  String flag = 'normal';

  void dispose() {
    testName.dispose();
    result.dispose();
    unit.dispose();
    referenceRange.dispose();
  }

  Map<String, dynamic> toMap() => {
        'testName': testName.text.trim(),
        'result': result.text.trim(),
        'unit': unit.text.trim(),
        'referenceRange': referenceRange.text.trim(),
        'flag': flag,
      };
}

class _AddRecordDialog extends StatefulWidget {
  final String patientId;
  const _AddRecordDialog({required this.patientId});

  @override
  State<_AddRecordDialog> createState() => _AddRecordDialogState();
}

class _AddRecordDialogState extends State<_AddRecordDialog> with UIMixin {
  String _type = 'note';
  final _titleTE = TextEditingController();
  final _contentTE = TextEditingController();
  DateTime _visitDate = DateTime.now();
  bool _saving = false;

  final List<_MedicineRow> _medicines = [_MedicineRow()];
  final List<_LabRow> _labTests = [_LabRow()];

  // Pharmacy stock for prescription autocomplete
  List<PharmacyModel> _pharmacyItems = [];

  @override
  void initState() {
    super.initState();
    _loadPharmacy();
  }

  Future<void> _loadPharmacy() async {
    final user = AppAuthController.instance.user;
    if (user == null) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('pharmacy')
          .where('hospitalId', isEqualTo: user.hospitalId)
          .orderBy('name')
          .get();
      if (mounted) {
        setState(() {
          _pharmacyItems = snap.docs.map(PharmacyModel.fromFirestore).toList();
        });
      }
    } catch (_) {}
  }

  static const _typeOptions = [
    ('note', 'Note'),
    ('diagnosis', 'Diagnosis'),
    ('prescription', 'Prescription'),
    ('lab_result', 'Lab Result'),
  ];

  static const _freqOptions = [
    'Once daily', 'Twice daily', 'Three times daily',
    'Four times daily', 'Every 6 hours', 'Every 8 hours',
    'At bedtime', 'As needed',
  ];

  @override
  void dispose() {
    _titleTE.dispose();
    _contentTE.dispose();
    for (final r in _medicines) r.dispose();
    for (final r in _labTests) r.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _visitDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _visitDate = picked);
  }

  Future<void> _submit() async {
    if (_titleTE.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Title is required.')));
      return;
    }

    final auth = AppAuthController.instance;
    setState(() => _saving = true);

    final prescriptionItems = _type == 'prescription'
        ? _medicines
            .map((m) => m.toMap())
            .where((m) => (m['name'] as String).isNotEmpty)
            .toList()
        : <Map<String, dynamic>>[];

    final labItems = _type == 'lab_result'
        ? _labTests
            .map((l) => l.toMap())
            .where((l) => (l['testName'] as String).isNotEmpty)
            .toList()
        : <Map<String, dynamic>>[];

    try {
      final recordRef = FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patientId)
          .collection('records')
          .doc();

      final recordData = {
        'patientId': widget.patientId,
        'doctorId': auth.user?.uid ?? '',
        'doctorName': auth.userName,
        'type': _type,
        'title': _titleTE.text.trim(),
        'content': _contentTE.text.trim(),
        'attachmentUrl': null,
        'visitDate': Timestamp.fromDate(_visitDate),
        'createdAt': FieldValue.serverTimestamp(),
        'prescriptionItems': prescriptionItems,
        'labItems': labItems,
      };

      final batch = FirebaseFirestore.instance.batch();
      batch.set(recordRef, recordData);

      // Dual-write to top-level prescriptions collection so pharmacy can query
      if (_type == 'prescription' && prescriptionItems.isNotEmpty) {
        final patientDoc = await FirebaseFirestore.instance
            .collection('patients')
            .doc(widget.patientId)
            .get();
        final patientName =
            patientDoc.data()?['name'] as String? ?? 'Unknown Patient';

        final rxRef =
            FirebaseFirestore.instance.collection('prescriptions').doc();
        batch.set(rxRef, {
          'patientId': widget.patientId,
          'patientName': patientName,
          'doctorId': auth.user?.uid ?? '',
          'doctorName': auth.userName,
          'recordId': recordRef.id,
          'items': prescriptionItems,
          'status': 'pending',
          'saleId': null,
          'fulfilledBy': null,
          'fulfilledAt': null,
          'hospitalId': auth.user?.hospitalId ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Medical record added.'),
            backgroundColor: Color(0xFF388E3C)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Failed to save record.'),
            backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Medical Record',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      actionsPadding: const EdgeInsets.all(16),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Record type
              MyText.labelMedium('Record Type'),
              MySpacing.height(8),
              DropdownButtonFormField<String>(
                value: _type,
                decoration: InputDecoration(
                    border: outlineInputBorder,
                    contentPadding: MySpacing.xy(12, 12),
                    isCollapsed: true),
                items: _typeOptions
                    .map((t) => DropdownMenuItem(
                        value: t.$1,
                        child: Text(t.$2, style: MyTextStyle.bodySmall())))
                    .toList(),
                onChanged: (v) => setState(() => _type = v ?? 'note'),
              ),
              MySpacing.height(16),

              // Title
              MyText.labelMedium('Title'),
              MySpacing.height(8),
              TextFormField(
                controller: _titleTE,
                style: MyTextStyle.bodySmall(),
                decoration: InputDecoration(
                    hintText: 'e.g. Annual checkup findings',
                    hintStyle: MyTextStyle.bodySmall(xMuted: true),
                    border: outlineInputBorder,
                    contentPadding: MySpacing.all(12),
                    isCollapsed: true),
              ),
              MySpacing.height(16),

              // Notes / content
              MyText.labelMedium('Notes / Summary'),
              MySpacing.height(8),
              TextFormField(
                controller: _contentTE,
                style: MyTextStyle.bodySmall(),
                maxLines: 4,
                decoration: InputDecoration(
                    hintText: 'Enter notes, findings or observations…',
                    hintStyle: MyTextStyle.bodySmall(xMuted: true),
                    border: outlineInputBorder,
                    contentPadding: MySpacing.all(12)),
              ),
              MySpacing.height(16),

              // Prescription items
              if (_type == 'prescription') ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MyText.labelMedium('Medicines', fontWeight: 600),
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => _medicines.add(_MedicineRow())),
                      icon: const Icon(LucideIcons.plus, size: 14),
                      label: const Text('Add', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                MySpacing.height(8),
                ..._medicines.asMap().entries.map((e) {
                  final i = e.key;
                  final row = e.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withAlpha(80)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(children: [
                        Row(children: [
                          Expanded(
                            flex: 3,
                            child: Autocomplete<String>(
                              initialValue: TextEditingValue(text: row.name.text),
                              optionsBuilder: (tv) {
                                if (_pharmacyItems.isEmpty) return const [];
                                final q = tv.text.toLowerCase();
                                if (q.isEmpty) {
                                  return _pharmacyItems.map((p) => p.name).take(8);
                                }
                                return _pharmacyItems
                                    .where((p) => p.name.toLowerCase().contains(q))
                                    .map((p) => p.name)
                                    .take(8);
                              },
                              onSelected: (s) => row.name.text = s,
                              fieldViewBuilder: (ctx, ctrl, focusNode, _) {
                                ctrl.addListener(() => row.name.text = ctrl.text);
                                return TextFormField(
                                  controller: ctrl,
                                  focusNode: focusNode,
                                  style: MyTextStyle.bodySmall(),
                                  decoration: InputDecoration(
                                    labelText: 'Medicine name',
                                    border: outlineInputBorder,
                                    contentPadding: MySpacing.all(10),
                                    isCollapsed: true,
                                    isDense: true,
                                  ),
                                );
                              },
                            ),
                          ),
                          MySpacing.width(8),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: row.dosage,
                              style: MyTextStyle.bodySmall(),
                              decoration: InputDecoration(
                                  labelText: 'Dosage',
                                  border: outlineInputBorder,
                                  contentPadding: MySpacing.all(10),
                                  isCollapsed: true,
                                  isDense: true),
                            ),
                          ),
                          if (_medicines.length > 1) ...[
                            MySpacing.width(4),
                            IconButton(
                              icon: const Icon(LucideIcons.trash_2,
                                  size: 14, color: Colors.red),
                              onPressed: () =>
                                  setState(() => _medicines.removeAt(i)),
                              splashRadius: 14,
                            ),
                          ],
                        ]),
                        MySpacing.height(8),
                        Row(children: [
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<String>(
                              value: _freqOptions.contains(row.frequency.text)
                                  ? row.frequency.text
                                  : null,
                              hint: Text('Frequency',
                                  style: MyTextStyle.bodySmall(xMuted: true)),
                              decoration: InputDecoration(
                                  border: outlineInputBorder,
                                  contentPadding: MySpacing.xy(10, 10),
                                  isCollapsed: true,
                                  isDense: true),
                              items: _freqOptions
                                  .map((f) => DropdownMenuItem(
                                      value: f,
                                      child: Text(f,
                                          style: MyTextStyle.bodySmall())))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => row.frequency.text = v ?? ''),
                            ),
                          ),
                          MySpacing.width(8),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: row.duration,
                              style: MyTextStyle.bodySmall(),
                              decoration: InputDecoration(
                                  labelText: 'Duration',
                                  hintText: 'e.g. 5 days',
                                  border: outlineInputBorder,
                                  contentPadding: MySpacing.all(10),
                                  isCollapsed: true,
                                  isDense: true),
                            ),
                          ),
                        ]),
                        MySpacing.height(8),
                        TextFormField(
                          controller: row.instructions,
                          style: MyTextStyle.bodySmall(),
                          decoration: InputDecoration(
                              labelText: 'Instructions (optional)',
                              hintText: 'e.g. After meals',
                              border: outlineInputBorder,
                              contentPadding: MySpacing.all(10),
                              isCollapsed: true,
                              isDense: true),
                        ),
                      ]),
                    ),
                  );
                }),
                MySpacing.height(8),
              ],

              // Lab result items
              if (_type == 'lab_result') ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MyText.labelMedium('Test Results', fontWeight: 600),
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => _labTests.add(_LabRow())),
                      icon: const Icon(LucideIcons.plus, size: 14),
                      label: const Text('Add', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                MySpacing.height(8),
                ..._labTests.asMap().entries.map((e) {
                  final i = e.key;
                  final row = e.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withAlpha(80)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(children: [
                        Row(children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: row.testName,
                              style: MyTextStyle.bodySmall(),
                              decoration: InputDecoration(
                                  labelText: 'Test name',
                                  border: outlineInputBorder,
                                  contentPadding: MySpacing.all(10),
                                  isCollapsed: true,
                                  isDense: true),
                            ),
                          ),
                          MySpacing.width(8),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: row.result,
                              style: MyTextStyle.bodySmall(),
                              decoration: InputDecoration(
                                  labelText: 'Result',
                                  border: outlineInputBorder,
                                  contentPadding: MySpacing.all(10),
                                  isCollapsed: true,
                                  isDense: true),
                            ),
                          ),
                          MySpacing.width(8),
                          SizedBox(
                            width: 60,
                            child: TextFormField(
                              controller: row.unit,
                              style: MyTextStyle.bodySmall(),
                              decoration: InputDecoration(
                                  labelText: 'Unit',
                                  border: outlineInputBorder,
                                  contentPadding: MySpacing.all(10),
                                  isCollapsed: true,
                                  isDense: true),
                            ),
                          ),
                          if (_labTests.length > 1) ...[
                            MySpacing.width(4),
                            IconButton(
                              icon: const Icon(LucideIcons.trash_2,
                                  size: 14, color: Colors.red),
                              onPressed: () =>
                                  setState(() => _labTests.removeAt(i)),
                              splashRadius: 14,
                            ),
                          ],
                        ]),
                        MySpacing.height(8),
                        Row(children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: row.referenceRange,
                              style: MyTextStyle.bodySmall(),
                              decoration: InputDecoration(
                                  labelText: 'Reference range',
                                  hintText: 'e.g. 4.0–11.0',
                                  border: outlineInputBorder,
                                  contentPadding: MySpacing.all(10),
                                  isCollapsed: true,
                                  isDense: true),
                            ),
                          ),
                          MySpacing.width(8),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: row.flag,
                              decoration: InputDecoration(
                                  border: outlineInputBorder,
                                  contentPadding: MySpacing.xy(10, 10),
                                  isCollapsed: true,
                                  isDense: true),
                              items: ['normal', 'high', 'low', 'critical']
                                  .map((f) => DropdownMenuItem(
                                      value: f,
                                      child: Text(
                                          f[0].toUpperCase() + f.substring(1),
                                          style: MyTextStyle.bodySmall())))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => row.flag = v ?? 'normal'),
                            ),
                          ),
                        ]),
                      ]),
                    ),
                  );
                }),
                MySpacing.height(8),
              ],

              // Visit date
              MyText.labelMedium('Visit Date'),
              MySpacing.height(8),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: MySpacing.xy(12, 10),
                  decoration: BoxDecoration(
                      border: Border.all(color: theme.dividerColor),
                      borderRadius: BorderRadius.circular(6)),
                  child: Row(children: [
                    Icon(LucideIcons.calendar,
                        size: 15, color: theme.hintColor),
                    MySpacing.width(8),
                    MyText.bodySmall(
                        '${_pad(_visitDate.day)}/${_pad(_visitDate.month)}/${_visitDate.year}'),
                  ]),
                ),
              ),
              MySpacing.height(8),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Save Record'),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Add Vitals Dialog
// ═══════════════════════════════════════════════════════════════════════════

class _AddVitalsDialog extends StatefulWidget {
  final String patientId;
  const _AddVitalsDialog({required this.patientId});

  @override
  State<_AddVitalsDialog> createState() => _AddVitalsDialogState();
}

class _AddVitalsDialogState extends State<_AddVitalsDialog> with UIMixin {
  final _systolicTE = TextEditingController();
  final _diastolicTE = TextEditingController();
  final _tempTE = TextEditingController();
  final _pulseTE = TextEditingController();
  final _spO2TE = TextEditingController();
  final _weightTE = TextEditingController();
  final _heightTE = TextEditingController();
  final _rrTE = TextEditingController();
  final _notesTE = TextEditingController();
  DateTime _recordedAt = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [
      _systolicTE, _diastolicTE, _tempTE, _pulseTE, _spO2TE,
      _weightTE, _heightTE, _rrTE, _notesTE
    ]) c.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _recordedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _recordedAt = picked);
  }

  Future<void> _submit() async {
    final systolic = double.tryParse(_systolicTE.text);
    final diastolic = double.tryParse(_diastolicTE.text);
    final temp = double.tryParse(_tempTE.text);
    final pulse = int.tryParse(_pulseTE.text);
    final spO2 = int.tryParse(_spO2TE.text);
    final weight = double.tryParse(_weightTE.text);
    final height = double.tryParse(_heightTE.text);
    final rr = int.tryParse(_rrTE.text);

    if (systolic == null && temp == null && pulse == null && spO2 == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Enter at least one vital sign.')));
      return;
    }

    final auth = AppAuthController.instance;
    setState(() => _saving = true);

    try {
      final data = <String, dynamic>{
        'patientId': widget.patientId,
        'recordedBy': auth.userName,
        'recordedById': auth.user?.uid ?? '',
        'notes': _notesTE.text.trim(),
        'recordedAt': Timestamp.fromDate(_recordedAt),
      };
      if (systolic != null) data['systolicBP'] = systolic;
      if (diastolic != null) data['diastolicBP'] = diastolic;
      if (temp != null) data['temperature'] = temp;
      if (pulse != null) data['pulse'] = pulse;
      if (spO2 != null) data['spO2'] = spO2;
      if (weight != null) data['weight'] = weight;
      if (height != null) data['height'] = height;
      if (rr != null) data['respiratoryRate'] = rr;

      await FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patientId)
          .collection('vitals')
          .add(data);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Vitals recorded.'),
            backgroundColor: Color(0xFF388E3C)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Failed to save vitals.'),
            backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _numField(String label, TextEditingController te,
      {String? hint, bool decimal = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      TextFormField(
        controller: te,
        keyboardType:
            TextInputType.numberWithOptions(decimal: decimal),
        inputFormatters: [
          FilteringTextInputFormatter.allow(
              decimal ? RegExp(r'[0-9.]') : RegExp(r'[0-9]'))
        ],
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          isCollapsed: true,
          isDense: true,
        ),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Record Vitals',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      actionsPadding: const EdgeInsets.all(16),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('All fields are optional — fill what was measured.',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 16),

              // Blood pressure row
              const Text('Blood Pressure (mmHg)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(
                    child: _numField('Systolic', _systolicTE, hint: '120')),
                const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 20),
                    child: Text('/',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold))),
                Expanded(
                    child:
                        _numField('Diastolic', _diastolicTE, hint: '80')),
              ]),
              const SizedBox(height: 14),

              // Row: Temp + Pulse
              Row(children: [
                Expanded(
                    child: _numField('Temperature (°C)', _tempTE,
                        hint: '37.0', decimal: true)),
                const SizedBox(width: 12),
                Expanded(
                    child:
                        _numField('Pulse (bpm)', _pulseTE, hint: '72')),
              ]),
              const SizedBox(height: 14),

              // Row: SpO2 + RR
              Row(children: [
                Expanded(
                    child: _numField('SpO2 (%)', _spO2TE, hint: '98')),
                const SizedBox(width: 12),
                Expanded(
                    child: _numField('Resp. Rate (br/min)', _rrTE,
                        hint: '16')),
              ]),
              const SizedBox(height: 14),

              // Row: Weight + Height
              Row(children: [
                Expanded(
                    child: _numField('Weight (kg)', _weightTE,
                        hint: '70.0', decimal: true)),
                const SizedBox(width: 12),
                Expanded(
                    child: _numField('Height (cm)', _heightTE,
                        hint: '170', decimal: true)),
              ]),
              const SizedBox(height: 14),

              // Notes
              const Text('Notes (optional)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _notesTE,
                maxLines: 2,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Any observations…',
                  hintStyle:
                      const TextStyle(fontSize: 12, color: Colors.grey),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 14),

              // Date
              const Text('Date Recorded',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withAlpha(80)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    const Icon(LucideIcons.calendar,
                        size: 15, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                        '${_pad(_recordedAt.day)}/${_pad(_recordedAt.month)}/${_recordedAt.year}',
                        style: const TextStyle(fontSize: 13)),
                  ]),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Save Vitals'),
        ),
      ],
    );
  }
}
