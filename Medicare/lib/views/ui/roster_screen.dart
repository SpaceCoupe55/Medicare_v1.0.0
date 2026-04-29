import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';
import 'package:medicare/controller/ui/roster_controller.dart';
import 'package:medicare/helpers/utils/ui_mixins.dart';
import 'package:medicare/helpers/widgets/my_breadcrumb.dart';
import 'package:medicare/helpers/widgets/my_breadcrumb_item.dart';
import 'package:medicare/helpers/widgets/my_button.dart';
import 'package:medicare/helpers/widgets/my_container.dart';
import 'package:medicare/helpers/widgets/my_spacing.dart';
import 'package:medicare/helpers/widgets/my_text.dart';
import 'package:medicare/helpers/widgets/responsive.dart';
import 'package:medicare/models/shift_model.dart';
import 'package:medicare/models/user_model.dart';
import 'package:medicare/views/layout/layout.dart';

class RosterScreen extends StatefulWidget {
  const RosterScreen({super.key});

  @override
  State<RosterScreen> createState() => _RosterScreenState();
}

class _RosterScreenState extends State<RosterScreen> with UIMixin {
  final RosterController ctrl = Get.put(RosterController());

  static const double _staffColW = 200;
  static const double _dayColW   = 148;
  static const double _rowH      = 72;
  static const double _headerH   = 52;

  @override
  Widget build(BuildContext context) {
    return Layout(
      child: GetBuilder<RosterController>(
        init: ctrl,
        builder: (c) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Page header ────────────────────────────────────────────────
            Padding(
              padding: MySpacing.x(flexSpacing),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MyText.titleMedium('Staff Roster',
                      fontSize: 18, fontWeight: 600),
                  Row(children: [
                    MyBreadcrumb(children: [
                      MyBreadcrumbItem(name: 'Operations'),
                      MyBreadcrumbItem(name: 'Roster', active: true),
                    ]),
                    MySpacing.width(16),
                    MyButton(
                      onPressed: () =>
                          _showAddDialog(context, c, staff: null, date: null),
                      elevation: 0,
                      padding: MySpacing.xy(16, 10),
                      backgroundColor: contentTheme.primary,
                      borderRadiusAll: 8,
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(LucideIcons.plus,
                            size: 16, color: contentTheme.onPrimary),
                        MySpacing.width(6),
                        MyText.labelMedium('Add Shift',
                            color: contentTheme.onPrimary, fontWeight: 600),
                      ]),
                    ),
                  ]),
                ],
              ),
            ),
            MySpacing.height(flexSpacing),

            Padding(
              padding: MySpacing.x(flexSpacing),
              child: Column(
                children: [
                  // ── Week nav + role filter ─────────────────────────────
                  MyContainer(
                    paddingAll: 16,
                    borderRadiusAll: 12,
                    child: Row(
                      children: [
                        // Week navigation
                        InkWell(
                          onTap: c.previousWeek,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: MySpacing.all(8),
                            child: Icon(LucideIcons.chevron_left,
                                size: 18, color: contentTheme.primary),
                          ),
                        ),
                        MySpacing.width(8),
                        MyText.labelLarge(c.weekRangeLabel, fontWeight: 700),
                        MySpacing.width(8),
                        InkWell(
                          onTap: c.nextWeek,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: MySpacing.all(8),
                            child: Icon(LucideIcons.chevron_right,
                                size: 18, color: contentTheme.primary),
                          ),
                        ),
                        const Spacer(),
                        // Role filter
                        Wrap(spacing: 8, children: [
                          _roleChip(c, 'all', 'All'),
                          _roleChip(c, 'doctor', 'Doctors'),
                          _roleChip(c, 'nurse', 'Nurses'),
                          _roleChip(c, 'receptionist', 'Reception'),
                        ]),
                      ],
                    ),
                  ),
                  MySpacing.height(16),

                  // ── Grid ──────────────────────────────────────────────
                  if (c.loadingStaff)
                    const Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (c.filteredStaff.isEmpty)
                    MyContainer(
                      paddingAll: 48,
                      borderRadiusAll: 12,
                      child: Center(
                        child: Column(children: [
                          Icon(LucideIcons.users,
                              size: 40, color: Colors.grey.shade400),
                          MySpacing.height(12),
                          MyText.bodyMedium('No staff found for this role.',
                              muted: true),
                        ]),
                      ),
                    )
                  else
                    MyContainer(
                      paddingAll: 0,
                      borderRadiusAll: 12,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: _grid(c),
                        ),
                      ),
                    ),

                  MySpacing.height(16),
                  // ── Legend ────────────────────────────────────────────
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: ShiftType.values
                        .map((t) => Row(mainAxisSize: MainAxisSize.min, children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: t.color,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              MySpacing.width(6),
                              MyText.bodySmall(
                                  '${t.label} (${t.defaultStart}–${t.defaultEnd})',
                                  muted: true,
                                  fontSize: 11),
                            ]))
                        .toList(),
                  ),
                ],
              ),
            ),
            MySpacing.height(flexSpacing),
          ],
        ),
      ),
    );
  }

  // ── Grid ───────────────────────────────────────────────────────────────────

  Widget _grid(RosterController c) {
    final days = c.weekDays;
    final today = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        _buildHeaderRow(days, today),
        const Divider(height: 1),
        // Staff rows
        ...c.filteredStaff.asMap().entries.map((entry) {
          final staff = entry.value;
          final isLast = entry.key == c.filteredStaff.length - 1;
          return Column(children: [
            _buildStaffRow(c, staff, days, today),
            if (!isLast)
              Divider(height: 1, color: Colors.grey.shade200),
          ]);
        }),
      ],
    );
  }

  Widget _buildHeaderRow(List<DateTime> days, DateTime today) {
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Row(children: [
      // Staff label cell
      Container(
        width: _staffColW,
        height: _headerH,
        padding: MySpacing.x(16),
        color: contentTheme.primary.withAlpha(15),
        child: Align(
          alignment: Alignment.centerLeft,
          child: MyText.labelMedium('Staff Member',
              fontWeight: 700, color: contentTheme.primary),
        ),
      ),
      // Day cells
      ...days.asMap().entries.map((e) {
        final i = e.key;
        final day = e.value;
        final isToday = _sameDay(day, today);
        return Container(
          width: _dayColW,
          height: _headerH,
          decoration: BoxDecoration(
            color: isToday
                ? contentTheme.primary.withAlpha(20)
                : contentTheme.primary.withAlpha(10),
            border: Border(
              left: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MyText.labelSmall(dayNames[i],
                  fontWeight: 700,
                  color: isToday ? contentTheme.primary : null),
              MyText.bodySmall('${day.day}',
                  fontWeight: isToday ? 700 : 400,
                  color: isToday ? contentTheme.primary : null),
            ],
          ),
        );
      }),
    ]);
  }

  Widget _buildStaffRow(
      RosterController c, UserModel staff, List<DateTime> days, DateTime today) {
    return SizedBox(
      height: _rowH,
      child: Row(children: [
        // Staff info cell
        Container(
          width: _staffColW,
          height: _rowH,
          padding: MySpacing.x(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MyText.labelMedium(staff.name,
                  fontWeight: 600, overflow: TextOverflow.ellipsis),
              MySpacing.height(2),
              _roleBadge(staff.role),
            ],
          ),
        ),
        // Day cells
        ...days.map((day) {
          final isToday = _sameDay(day, today);
          final dayShifts = c.shiftsFor(staff.uid, day);
          return GestureDetector(
            onTap: () =>
                _showAddDialog(context, c, staff: staff, date: day),
            child: Container(
              width: _dayColW,
              height: _rowH,
              decoration: BoxDecoration(
                color: isToday ? contentTheme.primary.withAlpha(8) : null,
                border: Border(
                  left: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: dayShifts.isEmpty
                  ? Center(
                      child: Icon(LucideIcons.plus,
                          size: 14, color: Colors.grey.shade300),
                    )
                  : Padding(
                      padding: MySpacing.all(6),
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: dayShifts
                            .map((s) => _shiftChip(c, s))
                            .toList(),
                      ),
                    ),
            ),
          );
        }),
      ]),
    );
  }

  Widget _shiftChip(RosterController c, ShiftModel shift) {
    return GestureDetector(
      onTap: () => _confirmDelete(context, c, shift),
      child: Container(
        padding: MySpacing.xy(7, 3),
        decoration: BoxDecoration(
          color: shift.type.bgColor,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: shift.type.color.withAlpha(80)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            MyText.bodySmall(shift.type.label,
                fontSize: 10,
                fontWeight: 700,
                color: shift.type.color),
            MyText.bodySmall(
                '${shift.startTime}–${shift.endTime}',
                fontSize: 9,
                color: shift.type.color),
          ],
        ),
      ),
    );
  }

  // ── Add shift dialog ────────────────────────────────────────────────────────

  void _showAddDialog(
    BuildContext context,
    RosterController c, {
    required UserModel? staff,
    required DateTime? date,
  }) {
    showDialog(
      context: context,
      builder: (_) => _AddShiftDialog(
        ctrl: c,
        preStaff: staff,
        preDate: date,
      ),
    );
  }

  // ── Delete confirm ──────────────────────────────────────────────────────────

  void _confirmDelete(
      BuildContext context, RosterController c, ShiftModel shift) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Shift'),
        content: Text(
            'Remove ${shift.type.label} shift (${shift.startTime}–${shift.endTime}) '
            'for ${shift.staffName}?'),
        actions: [
          TextButton(
              onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              c.deleteShift(shift);
            },
            child: const Text('Remove',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Widget _roleChip(RosterController c, String key, String label) {
    final selected = c.roleFilter == key;
    return InkWell(
      onTap: () => c.setRoleFilter(key),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: MySpacing.xy(12, 6),
        decoration: BoxDecoration(
          color: selected
              ? contentTheme.primary
              : contentTheme.primary.withAlpha(15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? contentTheme.primary
                : contentTheme.primary.withAlpha(50),
          ),
        ),
        child: MyText.labelSmall(label,
            color: selected ? contentTheme.onPrimary : contentTheme.primary,
            fontWeight: selected ? 700 : 500),
      ),
    );
  }

  Widget _roleBadge(UserRole role) {
    Color color;
    switch (role) {
      case UserRole.doctor:
        color = Colors.blue;
        break;
      case UserRole.nurse:
        color = Colors.green;
        break;
      case UserRole.receptionist:
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: MySpacing.xy(6, 2),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(4),
      ),
      child: MyText.bodySmall(
        role.name[0].toUpperCase() + role.name.substring(1),
        color: color,
        fontWeight: 600,
        fontSize: 10,
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ── Add Shift dialog ──────────────────────────────────────────────────────────

class _AddShiftDialog extends StatefulWidget {
  final RosterController ctrl;
  final UserModel? preStaff;
  final DateTime? preDate;

  const _AddShiftDialog({
    required this.ctrl,
    required this.preStaff,
    required this.preDate,
  });

  @override
  State<_AddShiftDialog> createState() => _AddShiftDialogState();
}

class _AddShiftDialogState extends State<_AddShiftDialog> {
  late UserModel? _staff;
  late DateTime _date;
  ShiftType _type = ShiftType.morning;
  late TextEditingController _startCtrl;
  late TextEditingController _endCtrl;
  final TextEditingController _notesCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _staff = widget.preStaff;
    _date = widget.preDate ?? DateTime.now();
    _startCtrl = TextEditingController(text: _type.defaultStart);
    _endCtrl = TextEditingController(text: _type.defaultEnd);
  }

  void _setType(ShiftType t) {
    setState(() {
      _type = t;
      _startCtrl.text = t.defaultStart;
      _endCtrl.text = t.defaultEnd;
    });
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _save() async {
    if (_staff == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a staff member.')));
      return;
    }
    setState(() => _saving = true);
    await widget.ctrl.addShift(
      staff: _staff!,
      date: _date,
      type: _type,
      startTime: _startCtrl.text.trim(),
      endTime: _endCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _startCtrl.dispose();
    _endCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    final dateLabel =
        '${_date.day} ${months[_date.month - 1]} ${_date.year}';

    return AlertDialog(
      title: const Text('Add Shift', style: TextStyle(fontWeight: FontWeight.w700)),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Staff
              const Text('Staff Member *',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _staff?.uid,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  hintText: 'Select staff member',
                ),
                items: widget.ctrl.allStaff
                    .map((u) => DropdownMenuItem(
                          value: u.uid,
                          child: Text(
                            '${u.name} (${u.role.name})',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ))
                    .toList(),
                onChanged: (uid) {
                  setState(() {
                    _staff = widget.ctrl.allStaff
                        .firstWhereOrNull((u) => u.uid == uid);
                  });
                },
              ),
              const SizedBox(height: 16),

              // Date
              const Text('Date *',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(children: [
                    const Icon(Icons.calendar_today, size: 16),
                    const SizedBox(width: 8),
                    Text(dateLabel,
                        style: const TextStyle(fontSize: 13)),
                  ]),
                ),
              ),
              const SizedBox(height: 16),

              // Shift type
              const Text('Shift Type *',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ShiftType.values
                    .map((t) => ChoiceChip(
                          label: Text(t.label,
                              style: const TextStyle(fontSize: 12)),
                          selected: _type == t,
                          selectedColor: t.color.withAlpha(60),
                          onSelected: (_) => _setType(t),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),

              // Times
              Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Start',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _startCtrl,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          hintText: 'HH:mm',
                        ),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('End',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _endCtrl,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          hintText: 'HH:mm',
                        ),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 16),

              // Notes
              const Text('Notes (optional)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Add Shift'),
        ),
      ],
    );
  }
}
