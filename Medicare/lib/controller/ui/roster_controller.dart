import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medicare/controller/auth_controller.dart';
import 'package:medicare/models/shift_model.dart';
import 'package:medicare/models/user_model.dart';
import 'package:medicare/views/my_controller.dart';

class RosterController extends MyController {
  // ── Staff ─────────────────────────────────────────────────────────────────
  List<UserModel> allStaff = [];
  List<UserModel> filteredStaff = [];
  bool loadingStaff = true;
  String roleFilter = 'all';

  // ── Week ──────────────────────────────────────────────────────────────────
  late DateTime weekStart;
  StreamSubscription<QuerySnapshot>? _shiftSub;

  // ── Shifts ────────────────────────────────────────────────────────────────
  List<ShiftModel> shifts = [];
  bool loadingShifts = false;

  // staffId_YYYY_M_D → list of shifts
  Map<String, List<ShiftModel>> _shiftMap = {};

  // ── Computed ──────────────────────────────────────────────────────────────
  List<DateTime> get weekDays =>
      List.generate(7, (i) => weekStart.add(Duration(days: i)));

  String get weekRangeLabel {
    final end = weekStart.add(const Duration(days: 6));
    return '${_fmt(weekStart)} – ${_fmt(end)}';
  }

  List<ShiftModel> shiftsFor(String staffId, DateTime date) =>
      _shiftMap['${staffId}_${_key(date)}'] ?? [];

  @override
  void onInit() {
    super.onInit();
    weekStart = _mondayOf(DateTime.now());
    _loadStaff();
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void previousWeek() {
    weekStart = weekStart.subtract(const Duration(days: 7));
    _subscribeShifts();
    update();
  }

  void nextWeek() {
    weekStart = weekStart.add(const Duration(days: 7));
    _subscribeShifts();
    update();
  }

  void setRoleFilter(String role) {
    roleFilter = role;
    _applyFilter();
    update();
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _loadStaff() async {
    final user = AppAuthController.instance.user;
    if (user == null) return;
    loadingStaff = true;
    update();
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('hospitalId', isEqualTo: user.hospitalId)
          .orderBy('name')
          .get();
      allStaff = snap.docs.map(UserModel.fromFirestore).toList();
      _applyFilter();
    } catch (_) {}
    loadingStaff = false;
    update();
    _subscribeShifts();
  }

  void _applyFilter() {
    filteredStaff = roleFilter == 'all'
        ? allStaff
        : allStaff.where((u) => u.role.name == roleFilter).toList();
  }

  void _subscribeShifts() {
    _shiftSub?.cancel();
    final user = AppAuthController.instance.user;
    if (user == null) return;

    final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final end = start.add(const Duration(days: 7));
    loadingShifts = true;
    update();

    _shiftSub = FirebaseFirestore.instance
        .collection('shifts')
        .where('hospitalId', isEqualTo: user.hospitalId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .snapshots()
        .listen(
      (snap) {
        shifts = snap.docs.map(ShiftModel.fromFirestore).toList();
        _buildMap();
        loadingShifts = false;
        update();
      },
      onError: (_) {
        loadingShifts = false;
        update();
      },
    );
  }

  void _buildMap() {
    _shiftMap = {};
    for (final s in shifts) {
      final k = '${s.staffId}_${_key(s.date)}';
      _shiftMap.putIfAbsent(k, () => []).add(s);
    }
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  Future<void> addShift({
    required UserModel staff,
    required DateTime date,
    required ShiftType type,
    required String startTime,
    required String endTime,
    String? notes,
  }) async {
    final user = AppAuthController.instance.user;
    if (user == null) return;
    final day = DateTime(date.year, date.month, date.day);
    await FirebaseFirestore.instance.collection('shifts').add({
      'staffId': staff.uid,
      'staffName': staff.name,
      'staffRole': staff.role.name,
      'date': Timestamp.fromDate(day),
      'type': type.name,
      'startTime': startTime,
      'endTime': endTime,
      'notes': notes?.isEmpty == true ? null : notes,
      'hospitalId': user.hospitalId,
      'createdBy': user.name,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteShift(ShiftModel shift) async {
    await FirebaseFirestore.instance
        .collection('shifts')
        .doc(shift.id)
        .delete();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static DateTime _mondayOf(DateTime d) =>
      d.subtract(Duration(days: d.weekday - 1));

  String _key(DateTime d) => '${d.year}_${d.month}_${d.day}';

  String _fmt(DateTime d) {
    const m = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${d.day} ${m[d.month - 1]}';
  }

  @override
  void onClose() {
    _shiftSub?.cancel();
    super.onClose();
  }
}
