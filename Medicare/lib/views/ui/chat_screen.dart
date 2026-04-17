import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';
import 'package:medicare/controller/ui/sms_controller.dart';
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
import 'package:medicare/models/sms_log_model.dart';
import 'package:medicare/views/layout/layout.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin, UIMixin {
  late SmsController controller;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    controller = Get.put(SmsController());
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (!_tabController.indexIsChanging) return;
        controller.setRecipientMode(
          _tabController.index == 0
              ? RecipientMode.individual
              : RecipientMode.bulk,
        );
        setState(() {}); // rebuild IndexedStack
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
      child: GetBuilder<SmsController>(
        init: controller,
        builder: (c) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: MySpacing.x(flexSpacing),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Icon(LucideIcons.message_square_text,
                        size: 20, color: contentTheme.primary),
                    MySpacing.width(8),
                    MyText.titleMedium('SMS / Messaging',
                        fontSize: 18, fontWeight: 600),
                  ]),
                  MyBreadcrumb(children: [
                    MyBreadcrumbItem(name: 'Operations'),
                    MyBreadcrumbItem(name: 'SMS / Messaging', active: true),
                  ]),
                ],
              ),
            ),
            MySpacing.height(flexSpacing),

            // ── Gateway notice ───────────────────────────────────────────────
            Padding(
              padding: MySpacing.x(flexSpacing),
              child: Container(
                padding: MySpacing.xy(16, 10),
                decoration: BoxDecoration(
                  color: contentTheme.warning.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: contentTheme.warning.withAlpha(80)),
                ),
                child: Row(children: [
                  Icon(LucideIcons.triangle_alert,
                      size: 16, color: contentTheme.warning),
                  MySpacing.width(10),
                  Expanded(
                    child: MyText.bodySmall(
                      'SMS powered by mNotify · Sender ID: SkillUp',
                      color: contentTheme.warning,
                    ),
                  ),
                ]),
              ),
            ),
            MySpacing.height(flexSpacing),

            // ── Two-panel layout ─────────────────────────────────────────────
            Padding(
              padding: MySpacing.x(flexSpacing / 2),
              child: MyFlex(
                children: [
                  // ── LEFT: Recipient panel ──────────────────────────────────
                  MyFlexItem(sizes: 'lg-4 md-12', child: _recipientPanel(c)),
                  // ── RIGHT: Composer + Log ──────────────────────────────────
                  MyFlexItem(
                      sizes: 'lg-8 md-12',
                      child: Column(children: [
                        _composerPanel(c),
                        MySpacing.height(16),
                        _logPanel(c),
                      ])),
                ],
              ),
            ),
            MySpacing.height(flexSpacing),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LEFT PANEL — Recipient selection
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _recipientPanel(SmsController c) {
    return MyContainer(
      paddingAll: 0,
      borderRadiusAll: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab bar
          TabBar(
            controller: _tabController,
            labelColor: contentTheme.primary,
            unselectedLabelColor: contentTheme.secondary,
            indicatorColor: contentTheme.primary,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Individual'),
              Tab(text: 'Bulk / Group'),
            ],
          ),
          const Divider(height: 1),
          Padding(
            padding: MySpacing.all(16),
            // IndexedStack instead of TabBarView — works in unbounded scroll contexts
            child: IndexedStack(
              index: _tabController.index,
              children: [
                _individualTab(c),
                _bulkTab(c),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Individual tab ──────────────────────────────────────────────────────────

  Widget _individualTab(SmsController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyText.labelMedium('Search patient', fontWeight: 600, muted: true),
        MySpacing.height(8),
        TextFormField(
          controller: c.patientSearchTE,
          onChanged: c.onPatientSearchChanged,
          style: MyTextStyle.bodySmall(),
          decoration: InputDecoration(
            hintText: 'Name or phone number…',
            hintStyle: MyTextStyle.bodySmall(muted: true),
            prefixIcon: const Icon(LucideIcons.search, size: 16),
            suffixIcon: c.selectedPatient != null
                ? IconButton(
                    icon: const Icon(LucideIcons.x, size: 14),
                    onPressed: c.clearPatient,
                    splashRadius: 14,
                  )
                : null,
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            isDense: true,
            isCollapsed: true,
            contentPadding: MySpacing.all(14),
          ),
        ),

        // Search results
        if (c.searchingPatients)
          Padding(
            padding: MySpacing.y(12),
            child: const Center(
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))),
          )
        else if (c.patientResults.isNotEmpty) ...[
          MySpacing.height(8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: MyContainer.bordered(
              paddingAll: 0,
              borderRadiusAll: 8,
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: c.patientResults.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: contentTheme.secondary.withAlpha(40)),
                itemBuilder: (_, i) {
                  final p = c.patientResults[i];
                  return InkWell(
                    onTap: () => c.selectPatient(p),
                    child: Padding(
                      padding: MySpacing.xy(12, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MyText.bodySmall(p.name, fontWeight: 600),
                          MyText.bodySmall(p.mobileNumber, muted: true, fontSize: 11),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],

        // Selected patient card
        if (c.selectedPatient != null) ...[
          MySpacing.height(16),
          Container(
            padding: MySpacing.all(12),
            decoration: BoxDecoration(
              color: contentTheme.primary.withAlpha(18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: contentTheme.primary.withAlpha(60)),
            ),
            child: Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: contentTheme.primary.withAlpha(40),
                    shape: BoxShape.circle),
                child: Icon(LucideIcons.user,
                    size: 18, color: contentTheme.primary),
              ),
              MySpacing.width(10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MyText.labelMedium(c.selectedPatient!.name,
                          fontWeight: 700),
                      MyText.bodySmall(c.selectedPatient!.mobileNumber,
                          muted: true, fontSize: 11),
                    ]),
              ),
              Container(
                padding: MySpacing.xy(6, 3),
                decoration: BoxDecoration(
                  color: contentTheme.success.withAlpha(30),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: MyText.bodySmall('Selected',
                    color: contentTheme.success, fontWeight: 600, fontSize: 10),
              ),
            ]),
          ),
        ],

        if (c.selectedPatient == null && c.patientResults.isEmpty &&
            !c.searchingPatients) ...[
          MySpacing.height(24),
          Center(
            child: Column(children: [
              Icon(LucideIcons.user_search,
                  size: 32, color: contentTheme.secondary.withAlpha(100)),
              MySpacing.height(8),
              MyText.bodySmall('Search for a patient above',
                  muted: true, textAlign: TextAlign.center),
            ]),
          ),
        ],
      ],
    );
  }

  // ── Bulk tab ────────────────────────────────────────────────────────────────

  Widget _bulkTab(SmsController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter chips
        MyText.labelMedium('Filter by', fontWeight: 600, muted: true),
        MySpacing.height(8),
        Wrap(
          spacing: 8,
          children: [
            _filterChip('All Patients', BulkFilter.all, c),
            _filterChip('By Doctor', BulkFilter.byDoctor, c),
            _filterChip('Date Range', BulkFilter.byDateRange, c),
          ],
        ),

        // By doctor dropdown
        if (c.bulkFilter == BulkFilter.byDoctor) ...[
          MySpacing.height(12),
          DropdownButtonFormField<String>(
            value: c.selectedDoctorId,
            decoration: InputDecoration(
              hintText: 'Select doctor',
              hintStyle: MyTextStyle.bodySmall(muted: true),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: MySpacing.all(14),
              isDense: true,
              isCollapsed: true,
              prefixIcon: const Icon(LucideIcons.stethoscope, size: 16),
            ),
            items: c.doctors
                .map((d) => DropdownMenuItem(
                    value: d.id, child: MyText.bodySmall(d.doctorName)))
                .toList(),
            onChanged: c.setSelectedDoctor,
          ),
        ],

        // By date range picker
        if (c.bulkFilter == BulkFilter.byDateRange) ...[
          MySpacing.height(12),
          InkWell(
            onTap: () => c.setDateRange(context),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: MySpacing.all(14),
              decoration: BoxDecoration(
                border: Border.all(
                    color: contentTheme.secondary.withAlpha(80)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                Icon(LucideIcons.calendar, size: 16, color: contentTheme.secondary),
                MySpacing.width(10),
                MyText.bodySmall(
                  c.dateFrom != null && c.dateTo != null
                      ? '${c.dateFrom!.day}/${c.dateFrom!.month}/${c.dateFrom!.year}  →  ${c.dateTo!.day}/${c.dateTo!.month}/${c.dateTo!.year}'
                      : 'Pick date range…',
                  muted: c.dateFrom == null,
                ),
              ]),
            ),
          ),
        ],

        MySpacing.height(16),

        // Select all toggle + count
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Checkbox(
                value: c.selectAll,
                onChanged: c.toggleSelectAll,
                activeColor: contentTheme.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              MySpacing.width(4),
              MyText.bodySmall('Select all', fontWeight: 600),
            ]),
            if (c.loadingBulk)
              const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
            else
              Container(
                padding: MySpacing.xy(8, 4),
                decoration: BoxDecoration(
                    color: contentTheme.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(6)),
                child: MyText.bodySmall(
                  '${c.selectAll ? c.bulkPatients.length : 0} selected',
                  color: contentTheme.primary,
                  fontWeight: 600,
                ),
              ),
          ],
        ),

        // Patient list preview
        if (c.bulkPatients.isNotEmpty && c.selectAll) ...[
          const Divider(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: c.bulkPatients.length,
              itemBuilder: (_, i) {
                final p = c.bulkPatients[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    Icon(LucideIcons.circle_dot,
                        size: 8, color: contentTheme.success),
                    MySpacing.width(8),
                    Expanded(
                        child: MyText.bodySmall(p.name,
                            overflow: TextOverflow.ellipsis)),
                    MyText.bodySmall(p.mobileNumber,
                        muted: true, fontSize: 10),
                  ]),
                );
              },
            ),
          ),
        ] else if (!c.loadingBulk && c.bulkPatients.isEmpty)
          Padding(
            padding: MySpacing.y(16),
            child: Center(
              child: MyText.bodySmall('No patients match this filter.',
                  muted: true),
            ),
          ),
      ],
    );
  }

  Widget _filterChip(String label, BulkFilter filter, SmsController c) {
    final selected = c.bulkFilter == filter;
    return GestureDetector(
      onTap: () => c.setBulkFilter(filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: MySpacing.xy(12, 6),
        decoration: BoxDecoration(
          color: selected
              ? contentTheme.primary
              : contentTheme.secondary.withAlpha(20),
          borderRadius: BorderRadius.circular(20),
        ),
        child: MyText.bodySmall(
          label,
          fontWeight: 600,
          color: selected ? contentTheme.onPrimary : null,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RIGHT PANEL — Composer
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _composerPanel(SmsController c) {
    return MyContainer(
      paddingAll: 20,
      borderRadiusAll: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MyText.titleMedium('Compose Message', fontWeight: 600),
              // Refresh log button
              IconButton(
                icon: Icon(LucideIcons.refresh_cw,
                    size: 16, color: contentTheme.secondary),
                tooltip: 'Refresh log',
                onPressed: () => c.send(),
                splashRadius: 18,
              ),
            ],
          ),
          MySpacing.height(16),

          // ── Message type toggle ───────────────────────────────────────────
          MyText.labelMedium('Message type', fontWeight: 600, muted: true),
          MySpacing.height(8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _typeChip('Standard SMS', MessageType.standard, c),
            _typeChip('Appt Reminder', MessageType.appointmentReminder, c),
            _typeChip('Custom Template', MessageType.custom, c),
          ]),

          MySpacing.height(16),

          // ── Appointment reminder fields ──────────────────────────────────
          if (c.messageType == MessageType.appointmentReminder) ...[
            Row(children: [
              Expanded(
                child: _reminderField(
                  label: 'Date',
                  controller: c.reminderDateTE,
                  icon: LucideIcons.calendar,
                  readOnly: true,
                  onTap: () => c.pickReminderDate(context),
                ),
              ),
              MySpacing.width(12),
              Expanded(
                child: _reminderField(
                  label: 'Time',
                  controller: c.reminderTimeTE,
                  icon: LucideIcons.clock,
                  readOnly: true,
                  onTap: () => c.pickReminderTime(context),
                ),
              ),
            ]),
            MySpacing.height(12),
            _reminderField(
              label: 'Doctor name',
              controller: c.reminderDoctorTE,
              icon: LucideIcons.stethoscope,
              onChanged: c.onReminderDoctorChanged,
            ),
            MySpacing.height(12),
          ],

          // ── Custom template picker ────────────────────────────────────────
          if (c.messageType == MessageType.custom) ...[
            if (c.templates.isEmpty)
              MyText.bodySmall('No saved templates yet.', muted: true)
            else
              DropdownButtonFormField<String>(
                value: c.selectedTemplate?.id,
                decoration: InputDecoration(
                  hintText: 'Select a template…',
                  hintStyle: MyTextStyle.bodySmall(muted: true),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding: MySpacing.all(14),
                  isDense: true,
                  isCollapsed: true,
                  prefixIcon:
                      const Icon(LucideIcons.layout_template, size: 16),
                ),
                items: c.templates
                    .map((t) => DropdownMenuItem(
                        value: t.id, child: MyText.bodySmall(t.title)))
                    .toList(),
                onChanged: (id) {
                  final t =
                      c.templates.firstWhereOrNull((t) => t.id == id);
                  if (t != null) c.selectTemplate(t);
                },
              ),
            MySpacing.height(12),
          ],

          // ── Textarea ─────────────────────────────────────────────────────
          TextFormField(
            controller: c.messageTE,
            maxLines: 6,
            style: MyTextStyle.bodySmall(),
            decoration: InputDecoration(
              hintText: 'Type your message here…',
              hintStyle: MyTextStyle.bodySmall(muted: true),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: MySpacing.all(14),
              isDense: true,
              isCollapsed: true,
            ),
          ),

          MySpacing.height(8),

          // ── Char counter ─────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (c.smsPartCount > 1)
                MyText.bodySmall(
                  'Sends as ${c.smsPartCount} SMS messages',
                  color: contentTheme.warning,
                  fontSize: 11,
                )
              else
                const SizedBox.shrink(),
              MyText.bodySmall(
                '${c.charCount} / 160',
                muted: c.charCount <= 160,
                color: c.charCount > 160 ? contentTheme.warning : null,
                fontSize: 11,
              ),
            ],
          ),

          MySpacing.height(16),

          // ── Save as template row (custom mode) ────────────────────────────
          if (c.messageType == MessageType.custom) ...[
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: c.templateTitleTE,
                  style: MyTextStyle.bodySmall(),
                  decoration: InputDecoration(
                    hintText: 'Template title…',
                    hintStyle: MyTextStyle.bodySmall(muted: true),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: MySpacing.all(12),
                    isDense: true,
                    isCollapsed: true,
                  ),
                ),
              ),
              MySpacing.width(8),
              MyButton(
                onPressed: c.savingTemplate ? null : c.saveAsTemplate,
                elevation: 0,
                padding: MySpacing.xy(12, 12),
                backgroundColor: contentTheme.secondary.withAlpha(30),
                borderRadiusAll: 10,
                child: c.savingTemplate
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(LucideIcons.save,
                            size: 14, color: contentTheme.onBackground),
                        MySpacing.width(6),
                        MyText.labelSmall('Save template',
                            fontWeight: 600),
                      ]),
              ),
            ]),
            MySpacing.height(16),
          ],

          // ── Result banner ─────────────────────────────────────────────────
          if (c.sendResult != null) ...[
            _resultBanner(c.sendResult!),
            MySpacing.height(12),
          ],

          // ── Send button ───────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: MyButton(
              onPressed: c.sending ? null : c.send,
              elevation: 0,
              padding: MySpacing.xy(20, 14),
              backgroundColor: contentTheme.primary,
              borderRadiusAll: 10,
              child: c.sending
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: contentTheme.onPrimary))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.send,
                            size: 16, color: contentTheme.onPrimary),
                        MySpacing.width(8),
                        MyText.labelMedium('Send Message',
                            color: contentTheme.onPrimary, fontWeight: 600),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeChip(String label, MessageType type, SmsController c) {
    final selected = c.messageType == type;
    return GestureDetector(
      onTap: () => c.setMessageType(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: MySpacing.xy(12, 6),
        decoration: BoxDecoration(
          color: selected
              ? contentTheme.primary
              : contentTheme.secondary.withAlpha(20),
          borderRadius: BorderRadius.circular(20),
        ),
        child: MyText.bodySmall(label,
            fontWeight: 600,
            color: selected ? contentTheme.onPrimary : null),
      ),
    );
  }

  Widget _reminderField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool readOnly = false,
    VoidCallback? onTap,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyText.labelSmall(label, fontWeight: 600, muted: true),
        MySpacing.height(6),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          onChanged: onChanged,
          style: MyTextStyle.bodySmall(),
          decoration: InputDecoration(
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: MySpacing.all(12),
            isDense: true,
            isCollapsed: true,
            prefixIcon: Icon(icon, size: 14),
          ),
        ),
      ],
    );
  }

  Widget _resultBanner(String result) {
    final isSuccess = result.startsWith('success:');
    final msg = result.substring(result.indexOf(':') + 1);
    final color = isSuccess ? contentTheme.success : contentTheme.danger;
    final icon =
        isSuccess ? LucideIcons.circle_check : LucideIcons.circle_alert;
    return Container(
      padding: MySpacing.xy(14, 10),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(children: [
        Icon(icon, size: 16, color: color),
        MySpacing.width(8),
        Expanded(child: MyText.bodySmall(msg, color: color, fontWeight: 600)),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SMS LOG PANEL
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _logPanel(SmsController c) {
    return MyContainer(
      paddingAll: 20,
      borderRadiusAll: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Icon(LucideIcons.history,
                    size: 16, color: contentTheme.primary),
                MySpacing.width(8),
                MyText.titleMedium('SMS Log', fontWeight: 600),
              ]),
              IconButton(
                icon: Icon(LucideIcons.refresh_cw,
                    size: 14, color: contentTheme.secondary),
                tooltip: 'Reload log',
                onPressed: c.loadingLog ? null : () => c.send(),
                splashRadius: 16,
              ),
            ],
          ),
          MySpacing.height(12),
          if (c.loadingLog)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator()))
          else if (c.smsLog.isEmpty)
            Padding(
              padding: MySpacing.y(24),
              child: Center(
                child: Column(children: [
                  Icon(LucideIcons.message_square_off,
                      size: 32,
                      color: contentTheme.secondary.withAlpha(100)),
                  MySpacing.height(8),
                  MyText.bodySmall('No messages sent yet.', muted: true),
                ]),
              ),
            )
          else
            _logTable(c),
        ],
      ),
    );
  }

  Widget _logTable(SmsController c) {
    return Column(
      children: [
        // Header row
        Container(
          padding: MySpacing.xy(12, 8),
          decoration: BoxDecoration(
            color: contentTheme.primary.withAlpha(30),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            SizedBox(
                width: 130,
                child: MyText.labelSmall('Date Sent',
                    color: contentTheme.primary, fontWeight: 600)),
            Expanded(
                child: MyText.labelSmall('Message Preview',
                    color: contentTheme.primary, fontWeight: 600)),
            SizedBox(
                width: 70,
                child: MyText.labelSmall('Recipients',
                    color: contentTheme.primary,
                    fontWeight: 600,
                    textAlign: TextAlign.center)),
            SizedBox(
                width: 80,
                child: MyText.labelSmall('Status',
                    color: contentTheme.primary,
                    fontWeight: 600,
                    textAlign: TextAlign.center)),
          ]),
        ),
        MySpacing.height(4),
        ...c.smsLog.map((log) => _logRow(log, c)),
      ],
    );
  }

  Widget _logRow(SmsLogModel log, SmsController c) {
    final expanded = c.expandedLogIds.contains(log.id);
    final dt = log.sentAt;
    final dateStr =
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    Color statusColor;
    switch (log.status) {
      case 'sent':
        statusColor = contentTheme.success;
        break;
      case 'failed':
        statusColor = contentTheme.danger;
        break;
      default:
        statusColor = contentTheme.warning;
    }

    return Column(
      children: [
        InkWell(
          onTap: () => c.toggleLogRow(log.id),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: MySpacing.xy(12, 10),
            child: Row(children: [
              SizedBox(
                  width: 130,
                  child: MyText.bodySmall(dateStr, fontSize: 11, muted: true)),
              Expanded(
                child: MyText.bodySmall(
                  log.message,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  fontSize: 12,
                ),
              ),
              SizedBox(
                width: 70,
                child: MyText.bodySmall(
                  '${log.recipientCount}',
                  textAlign: TextAlign.center,
                  fontWeight: 600,
                ),
              ),
              SizedBox(
                width: 80,
                child: Center(
                  child: Container(
                    padding: MySpacing.xy(8, 3),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: MyText.bodySmall(
                      log.status[0].toUpperCase() +
                          log.status.substring(1),
                      color: statusColor,
                      fontWeight: 600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              Icon(
                expanded ? LucideIcons.chevron_up : LucideIcons.chevron_down,
                size: 14,
                color: contentTheme.secondary,
              ),
            ]),
          ),
        ),

        // Expanded detail
        if (expanded)
          Container(
            margin: MySpacing.only(left: 12, right: 12, bottom: 8),
            padding: MySpacing.all(12),
            decoration: BoxDecoration(
              color: contentTheme.primary.withAlpha(8),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: contentTheme.primary.withAlpha(30)),
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText.labelSmall('Full message',
                      fontWeight: 600, muted: true),
                  MySpacing.height(6),
                  MyText.bodySmall(log.message),
                  MySpacing.height(12),
                  MyText.labelSmall('Recipients (${log.recipients.length})',
                      fontWeight: 600, muted: true),
                  MySpacing.height(6),
                  ...log.recipients.take(20).map((r) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(children: [
                          Icon(LucideIcons.user,
                              size: 11,
                              color: contentTheme.secondary),
                          MySpacing.width(6),
                          MyText.bodySmall('${r.name}  ·  ${r.phone}',
                              fontSize: 11),
                        ]),
                      )),
                  if (log.recipients.length > 20)
                    MyText.bodySmall(
                        '…and ${log.recipients.length - 20} more',
                        muted: true,
                        fontSize: 11),
                ]),
          ),
        Divider(height: 1, color: contentTheme.secondary.withAlpha(30)),
      ],
    );
  }
}
