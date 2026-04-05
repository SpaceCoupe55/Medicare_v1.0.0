import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';
import 'package:medicare/controller/auth_controller.dart';
import 'package:medicare/controller/ui/patient_detail_controller.dart';
import 'package:medicare/helpers/theme/app_style.dart';
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
import 'package:medicare/models/medical_record_model.dart';
import 'package:medicare/models/patient_model.dart';
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

String _pad(int n) => n.toString().padLeft(2, '0');

String _formatDate(DateTime d) => '${_pad(d.day)}/${_pad(d.month)}/${d.year}';

String _formatDateTime(DateTime d) =>
    '${_pad(d.day)}/${_pad(d.month)}/${d.year}  ${_pad(d.hour)}:${_pad(d.minute)}';

int _age(DateTime dob) {
  final now = DateTime.now();
  int age = now.year - dob.year;
  if (now.month < dob.month ||
      (now.month == dob.month && now.day < dob.day)) {
    age--;
  }
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
    _tabController = TabController(length: 3, vsync: this);
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
              // ── Breadcrumb ──────────────────────────────────────────────
              Padding(
                padding: MySpacing.x(flexSpacing),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MyText.titleMedium('Patient Profile',
                        fontSize: 18, fontWeight: 600),
                    MyBreadcrumb(
                      children: [
                        MyBreadcrumbItem(name: 'Patients'),
                        MyBreadcrumbItem(name: patient.name, active: true),
                      ],
                    ),
                  ],
                ),
              ),
              MySpacing.height(flexSpacing),

              // ── Patient header card ─────────────────────────────────────
              Padding(
                padding: MySpacing.x(flexSpacing / 2),
                child: _headerCard(patient, ctrl),
              ),
              MySpacing.height(16),

              // ── Tabs ────────────────────────────────────────────────────
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
          // Avatar
          Container(
            width: 72,
            height: 72,
            decoration:
                BoxDecoration(color: bgColor, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold),
            ),
          ),
          MySpacing.width(20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    MyText.titleMedium(patient.name, fontWeight: 600),
                    MySpacing.width(12),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
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
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
                MySpacing.height(4),
                Row(
                  children: [
                    Icon(LucideIcons.calendar,
                        size: 13, color: theme.hintColor),
                    MySpacing.width(4),
                    MyText.bodySmall(
                        '${_age(patient.birthDate)} yrs  ·  ${patient.gender}',
                        muted: true),
                    MySpacing.width(16),
                    Icon(LucideIcons.droplets,
                        size: 13, color: theme.hintColor),
                    MySpacing.width(4),
                    MyText.bodySmall(patient.bloodGroup.isEmpty
                        ? '—'
                        : patient.bloodGroup,
                        muted: true),
                  ],
                ),
              ],
            ),
          ),
          // Edit button
          MyButton(
            onPressed: () => Get.toNamed(AppRoutes.patientEdit,
                arguments: patient),
            elevation: 0,
            padding: MySpacing.xy(16, 10),
            backgroundColor: contentTheme.primary,
            borderRadiusAll: AppStyle.buttonRadius.medium,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.pencil,
                    size: 14, color: contentTheme.onPrimary),
                MySpacing.width(6),
                MyText.labelSmall('Edit',
                    color: contentTheme.onPrimary, fontWeight: 600),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 1: Overview ────────────────────────────────────────────────────────

  Widget _overviewTab(PatientModel patient, PatientDetailController ctrl) {
    return MyFlex(
      children: [
        // Left: Patient info
        MyFlexItem(
          sizes: 'lg-6',
          child: MyContainer(
            borderRadiusAll: 10,
            paddingAll: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText.labelLarge('Patient Information', fontWeight: 600),
                MySpacing.height(16),
                _infoRow(LucideIcons.user, 'Full Name', patient.name),
                _divider(),
                _infoRow(LucideIcons.calendar,
                    'Date of Birth', _formatDate(patient.birthDate)),
                _divider(),
                _infoRow(LucideIcons.cake,
                    'Age', '${_age(patient.birthDate)} years'),
                _divider(),
                _infoRow(LucideIcons.users,
                    'Gender', patient.gender.isEmpty ? '—' : patient.gender),
                _divider(),
                _infoRow(LucideIcons.droplets,
                    'Blood Type',
                    patient.bloodGroup.isEmpty ? '—' : patient.bloodGroup),
                _divider(),
                _infoRow(LucideIcons.phone,
                    'Phone',
                    patient.mobileNumber.isEmpty ? '—' : patient.mobileNumber),
                _divider(),
                _infoRow(LucideIcons.mail,
                    'Email', patient.email.isEmpty ? '—' : patient.email),
                _divider(),
                _infoRow(LucideIcons.map_pin,
                    'Address',
                    patient.address.isEmpty ? '—' : patient.address),
                _divider(),
                _infoRow(LucideIcons.calendar_plus,
                    'Registered',
                    _formatDate(patient.createdAt)),
              ],
            ),
          ),
        ),

        // Right: Doctor + Stats
        MyFlexItem(
          sizes: 'lg-6',
          child: Column(
            children: [
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
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Color(0xFF5C6BC0),
                              shape: BoxShape.circle,
                            ),
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
                                fontWeight: 600,
                              ),
                              GestureDetector(
                                onTap: () => Get.toNamed(
                                    AppRoutes.doctorDetail,
                                    arguments: patient.assignedDoctorId),
                                child: MyText.bodySmall('View profile',
                                    color: contentTheme.primary),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              MySpacing.height(16),

              // Stats row
              MyContainer(
                borderRadiusAll: 10,
                paddingAll: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MyText.labelLarge('Visit Summary', fontWeight: 600),
                    MySpacing.height(16),
                    Row(
                      children: [
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
                      ],
                    ),
                  ],
                ),
              ),

              MySpacing.height(16),

              // Medical history note
              if (patient.medicalHistory.isNotEmpty)
                MyContainer(
                  borderRadiusAll: 10,
                  paddingAll: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MyText.labelLarge('Medical History Notes',
                          fontWeight: 600),
                      MySpacing.height(12),
                      MyText.bodySmall(patient.medicalHistory, muted: true),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Tab 2: Medical Records ─────────────────────────────────────────────────

  Widget _recordsTab(PatientDetailController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toolbar
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.plus,
                        size: 14, color: contentTheme.onPrimary),
                    MySpacing.width(6),
                    MyText.labelSmall('Add Record',
                        color: contentTheme.onPrimary, fontWeight: 600),
                  ],
                ),
              ),
          ],
        ),
        MySpacing.height(16),

        // Loading
        if (ctrl.loadingRecords)
          const Center(
              child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator()))
        else if (ctrl.records.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: [
                  Icon(LucideIcons.clipboard_x,
                      size: 40, color: theme.hintColor),
                  MySpacing.height(12),
                  MyText.bodyMedium('No medical records yet.', muted: true),
                ],
              ),
            ),
          )
        else
          Column(
            children: ctrl.records
                .map((r) => _recordCard(r, ctrl))
                .toList(),
          ),
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
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Type badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withAlpha(30),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        record.type.label.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                    MySpacing.width(12),
                    Expanded(
                      child: MyText.bodyMedium(record.title, fontWeight: 600),
                    ),
                    Icon(
                      isExpanded
                          ? LucideIcons.chevron_up
                          : LucideIcons.chevron_down,
                      size: 16,
                      color: theme.hintColor,
                    ),
                  ],
                ),
                MySpacing.height(8),
                MyText.bodySmall(
                    isExpanded ? record.content : preview,
                    muted: true),
                MySpacing.height(8),
                Row(
                  children: [
                    Icon(LucideIcons.user_round,
                        size: 12, color: theme.hintColor),
                    MySpacing.width(4),
                    MyText.bodySmall(record.doctorName, muted: true),
                    MySpacing.width(16),
                    Icon(LucideIcons.calendar,
                        size: 12, color: theme.hintColor),
                    MySpacing.width(4),
                    MyText.bodySmall(_formatDate(record.visitDate), muted: true),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Tab 3: Appointments ────────────────────────────────────────────────────

  Widget _appointmentsTab(PatientDetailController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            MyText.labelLarge('Appointments', fontWeight: 600),
            MyButton(
              onPressed: () =>
                  Get.toNamed(AppRoutes.appointmentBook),
              elevation: 0,
              padding: MySpacing.xy(16, 10),
              backgroundColor: contentTheme.primary,
              borderRadiusAll: AppStyle.buttonRadius.medium,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.calendar_plus,
                      size: 14, color: contentTheme.onPrimary),
                  MySpacing.width(6),
                  MyText.labelSmall('Book Appointment',
                      color: contentTheme.onPrimary, fontWeight: 600),
                ],
              ),
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
              child: Column(
                children: [
                  Icon(LucideIcons.calendar_x,
                      size: 40, color: theme.hintColor),
                  MySpacing.height(12),
                  MyText.bodyMedium('No appointments found.', muted: true),
                ],
              ),
            ),
          )
        else
          Column(
            children: ctrl.appointments
                .map((a) => _appointmentRow(a))
                .toList(),
          ),
      ],
    );
  }

  Widget _appointmentRow(AppointmentModel appt) {
    final color = _statusColor(appt.status);
    final label = appt.status.name[0].toUpperCase() +
        appt.status.name.substring(1);

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
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(LucideIcons.calendar, size: 16, color: theme.hintColor),
            MySpacing.width(8),
            Expanded(
              flex: 2,
              child: MyText.bodySmall(_formatDateTime(appt.date),
                  fontWeight: 500),
            ),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Icon(LucideIcons.stethoscope,
                      size: 13, color: theme.hintColor),
                  MySpacing.width(4),
                  Flexible(
                    child: MyText.bodySmall(
                      appt.consultingDoctor.isEmpty
                          ? '—'
                          : appt.consultingDoctor,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Add Record Dialog ──────────────────────────────────────────────────────

  void _showAddRecordDialog(PatientDetailController ctrl) {
    showDialog(
      context: context,
      builder: (_) => _AddRecordDialog(
        patientId: ctrl.patientId,
        onSuccess: () {
          // records stream auto-updates; nothing else needed
        },
      ),
    );
  }

  // ── Small helpers ──────────────────────────────────────────────────────────

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: theme.hintColor),
          MySpacing.width(10),
          SizedBox(
            width: 110,
            child: MyText.bodySmall(label, fontWeight: 600),
          ),
          Expanded(
            child: MyText.bodySmall(value, muted: true,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(height: 1, thickness: 0.5, color: theme.dividerColor);

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          MySpacing.height(8),
          MyText.titleMedium(value, fontWeight: 700, color: color),
          MySpacing.height(2),
          MyText.bodySmall(label, muted: true),
        ],
      ),
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

// ── Add Record Dialog ──────────────────────────────────────────────────────

class _AddRecordDialog extends StatefulWidget {
  final String patientId;
  final VoidCallback onSuccess;

  const _AddRecordDialog({
    required this.patientId,
    required this.onSuccess,
  });

  @override
  State<_AddRecordDialog> createState() => _AddRecordDialogState();
}

class _AddRecordDialogState extends State<_AddRecordDialog> with UIMixin {
  String _type = 'note';
  final _titleTE = TextEditingController();
  final _contentTE = TextEditingController();
  DateTime _visitDate = DateTime.now();
  bool _saving = false;

  static const _typeOptions = [
    ('note', 'Note'),
    ('diagnosis', 'Diagnosis'),
    ('prescription', 'Prescription'),
    ('lab_result', 'Lab Result'),
  ];

  @override
  void dispose() {
    _titleTE.dispose();
    _contentTE.dispose();
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
        const SnackBar(content: Text('Title is required.')),
      );
      return;
    }
    if (_contentTE.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Content is required.')),
      );
      return;
    }

    final auth = AppAuthController.instance;
    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patientId)
          .collection('records')
          .add({
        'patientId': widget.patientId,
        'doctorId': auth.user?.uid ?? '',
        'doctorName': auth.userName,
        'type': _type,
        'title': _titleTE.text.trim(),
        'content': _contentTE.text.trim(),
        'attachmentUrl': null,
        'visitDate': Timestamp.fromDate(_visitDate),
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Medical record added.'),
              backgroundColor: Color(0xFF388E3C)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to save record.'),
              backgroundColor: Colors.red),
        );
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
        width: 480,
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
                  isCollapsed: true,
                ),
                items: _typeOptions
                    .map((t) => DropdownMenuItem(
                        value: t.$1,
                        child: Text(t.$2,
                            style: MyTextStyle.bodySmall())))
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
                  isCollapsed: true,
                ),
              ),
              MySpacing.height(16),

              // Content
              MyText.labelMedium('Content'),
              MySpacing.height(8),
              TextFormField(
                controller: _contentTE,
                style: MyTextStyle.bodySmall(),
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: 'Enter detailed notes, findings or instructions…',
                  hintStyle: MyTextStyle.bodySmall(xMuted: true),
                  border: outlineInputBorder,
                  contentPadding: MySpacing.all(12),
                ),
              ),
              MySpacing.height(16),

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
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.calendar,
                          size: 15, color: theme.hintColor),
                      MySpacing.width(8),
                      MyText.bodySmall(
                        '${_pad(_visitDate.day)}/${_pad(_visitDate.month)}/${_visitDate.year}',
                      ),
                    ],
                  ),
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
          child: const Text('Cancel'),
        ),
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
