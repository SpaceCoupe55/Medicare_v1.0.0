import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medicare/controller/auth_controller.dart';
import 'package:medicare/helpers/chart_data.dart';
import 'package:medicare/helpers/utils/ui_mixins.dart';
import 'package:medicare/models/user_model.dart';
import 'package:medicare/route_names.dart';
import 'package:medicare/views/my_controller.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class DashboardController extends MyController with UIMixin {
  List<ChartSampleData>? chartData;
  List<ChartSampleData>? patientByAge;
  TooltipBehavior tooltipBehavior = TooltipBehavior(enable: true);

  // Live counts — kept as plain ints (GetBuilder handles reactivity)
  int totalPatients = 0;
  int totalDoctors = 0;
  int totalAppointments = 0;
  int totalAppointmentsToday = 0;

  // Recent appointments (last 5)
  List<Map<String, dynamic>> recentAppointments = [];

  // Top doctors for the sidebar widget
  List<Map<String, dynamic>> topDoctors = [];

  bool loading = false;

  // ── Internal state ─────────────────────────────────────────────────────────
  bool _dataLoaded = false;
  StreamSubscription? _patientsSub;
  StreamSubscription? _doctorsSub;
  Worker? _authWorker;

  bool get isAdmin =>
      AppAuthController.instance.user?.role == UserRole.admin;

  String get _hospitalId =>
      AppAuthController.instance.user?.hospitalId ?? '';

  @override
  void onInit() {
    _initChartData();
    super.onInit();

    // If user is already available (e.g. hot restart), load immediately.
    final existing = AppAuthController.instance.user;
    if (existing != null && existing.hospitalId.isNotEmpty) {
      _dataLoaded = true;
      _setupRealtimeListeners();
      loadDashboard();
    }

    // Also react whenever the auth user changes (initial login, token refresh).
    _authWorker = ever(AppAuthController.instance.appUser, (UserModel? user) {
      if (user != null && user.hospitalId.isNotEmpty && !_dataLoaded) {
        _dataLoaded = true;
        _setupRealtimeListeners();
        loadDashboard();
      }
    });
  }

  void _initChartData() {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    chartData = List.generate(
      12,
      (i) => ChartSampleData(x: months[i], y: 0, secondSeriesYValue: 0),
    );
    patientByAge = List.generate(
      12,
      (i) => ChartSampleData(x: months[i], y: 0, secondSeriesYValue: 0),
    );
  }

  // ── Real-time listeners (patients + doctors only) ──────────────────────────

  void _setupRealtimeListeners() {
    final hid = _hospitalId;
    if (hid.isEmpty) return;
    final db = FirebaseFirestore.instance;

    _patientsSub?.cancel();
    _patientsSub = db
        .collection('patients')
        .where('hospitalId', isEqualTo: hid)
        .snapshots()
        .listen((snap) {
      totalPatients = snap.docs.length;
      update();
    }, onError: (_) {});

    _doctorsSub?.cancel();
    _doctorsSub = db
        .collection('doctors')
        .where('hospitalId', isEqualTo: hid)
        .snapshots()
        .listen((snap) {
      totalDoctors = snap.docs.length;
      update();
    }, onError: (_) {});
  }

  // ── Main load / refresh ────────────────────────────────────────────────────

  Future<void> loadDashboard() async {
    loading = true;
    update();

    final db = FirebaseFirestore.instance;
    final hid = _hospitalId;

    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay   = DateTime(today.year, today.month, today.day, 23, 59, 59);
      final yearStart  = DateTime(today.year, 1, 1);
      final yearEnd    = DateTime(today.year, 12, 31, 23, 59, 59);

      // ── Parallel: stat counts + chart data + doctors list ─────────────────
      final results = await Future.wait([
        // 0 – total appointments count
        db.collection('appointments')
            .where('hospitalId', isEqualTo: hid)
            .count()
            .get(),
        // 1 – today's appointments count
        db.collection('appointments')
            .where('hospitalId', isEqualTo: hid)
            .where('dateTime',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('dateTime',
                isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
            .count()
            .get(),
        // 2 – recent 5 appointments
        db.collection('appointments')
            .where('hospitalId', isEqualTo: hid)
            .orderBy('dateTime', descending: true)
            .limit(5)
            .get(),
        // 3 – this year's appointments (for chart)
        db.collection('appointments')
            .where('hospitalId', isEqualTo: hid)
            .where('dateTime',
                isGreaterThanOrEqualTo: Timestamp.fromDate(yearStart))
            .where('dateTime',
                isLessThanOrEqualTo: Timestamp.fromDate(yearEnd))
            .get(),
        // 4 – this year's patients (for gender chart)
        db.collection('patients')
            .where('hospitalId', isEqualTo: hid)
            .where('createdAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(yearStart))
            .where('createdAt',
                isLessThanOrEqualTo: Timestamp.fromDate(yearEnd))
            .get(),
        // 5 – top 5 doctors
        db.collection('doctors')
            .where('hospitalId', isEqualTo: hid)
            .limit(5)
            .get(),
      ]);

      // ── Stat cards ─────────────────────────────────────────────────────────
      totalAppointments      = (results[0] as AggregateQuerySnapshot).count ?? 0;
      totalAppointmentsToday = (results[1] as AggregateQuerySnapshot).count ?? 0;
      // totalPatients / totalDoctors come from real-time listeners —
      // only set them here if the listeners haven't fired yet.
      if (totalPatients == 0 || totalDoctors == 0) {
        final pc = await db.collection('patients')
            .where('hospitalId', isEqualTo: hid).count().get();
        final dc = await db.collection('doctors')
            .where('hospitalId', isEqualTo: hid).count().get();
        if (totalPatients == 0) totalPatients = pc.count ?? 0;
        if (totalDoctors  == 0) totalDoctors  = dc.count ?? 0;
      }

      // ── Recent appointments ────────────────────────────────────────────────
      final recentSnap = results[2] as QuerySnapshot<Map<String, dynamic>>;
      recentAppointments = recentSnap.docs.map((doc) {
        final d = doc.data();
        final dt = (d['dateTime'] as Timestamp?)?.toDate() ?? DateTime.now();
        return {
          'id': doc.id,
          'patient_name': d['patientName'] ?? '',
          'appointment_for': d['doctorName'] ?? '',
          'date': dt,
          'status': d['status'] ?? 'scheduled',
        };
      }).toList();

      // ── Appointment chart (Scheduled vs Completed by month) ───────────────
      final apptSnap = results[3] as QuerySnapshot<Map<String, dynamic>>;
      final scheduledByMonth = List.filled(12, 0);
      final completedByMonth = List.filled(12, 0);
      for (final doc in apptSnap.docs) {
        final d = doc.data();
        final dt = (d['dateTime'] as Timestamp?)?.toDate();
        if (dt == null) continue;
        final m = dt.month - 1;
        if ((d['status'] as String? ?? '').toLowerCase() == 'completed') {
          completedByMonth[m]++;
        } else {
          scheduledByMonth[m]++;
        }
      }

      // ── Patient gender chart (Male vs Female by month) ─────────────────────
      final patientSnap = results[4] as QuerySnapshot<Map<String, dynamic>>;
      final maleByMonth   = List.filled(12, 0);
      final femaleByMonth = List.filled(12, 0);
      for (final doc in patientSnap.docs) {
        final d = doc.data();
        final dt = (d['createdAt'] as Timestamp?)?.toDate();
        if (dt == null) continue;
        final m = dt.month - 1;
        if ((d['gender'] as String? ?? '').toLowerCase() == 'female') {
          femaleByMonth[m]++;
        } else {
          maleByMonth[m]++;
        }
      }

      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      chartData = List.generate(
        12,
        (i) => ChartSampleData(
          x: months[i],
          y: scheduledByMonth[i],
          secondSeriesYValue: completedByMonth[i],
        ),
      );
      patientByAge = List.generate(
        12,
        (i) => ChartSampleData(
          x: months[i],
          y: maleByMonth[i],
          secondSeriesYValue: femaleByMonth[i],
        ),
      );

      // ── Top doctors ────────────────────────────────────────────────────────
      final docSnap = results[5] as QuerySnapshot<Map<String, dynamic>>;
      topDoctors = docSnap.docs.map((doc) {
        final d = doc.data();
        return {
          'name': d['name'] as String? ?? '',
          'designation': d['specialization'] as String? ?? '',
        };
      }).toList();
    } catch (_) {
      // Dashboard degrades gracefully — counts stay at whatever they were.
    } finally {
      loading = false;
      update();
    }
  }

  // ── Navigation ──────────────────────────────────────────────────────────────

  void goToPatients() => Get.toNamed(AppRoutes.patientList);
  void goToDoctors() => Get.toNamed(AppRoutes.doctorList);
  void goToAppointments() => Get.toNamed(AppRoutes.appointmentList);
  void goToAddPatient() => Get.toNamed(AppRoutes.patientAdd);
  void goToBookAppointment() => Get.toNamed(AppRoutes.appointmentBook);
  void goToAddDoctor() => Get.toNamed(AppRoutes.doctorAdd);
  void goToReports() => Get.toNamed(AppRoutes.reports);
  void goToAppointmentDetail(String id) =>
      Get.toNamed(AppRoutes.appointmentEdit, arguments: {'id': id});

  // ── Chart series builders ───────────────────────────────────────────────────

  List<SplineSeries<ChartSampleData, String>> treatmentTypeChart() {
    return <SplineSeries<ChartSampleData, String>>[
      SplineSeries<ChartSampleData, String>(
        dataSource: chartData,
        color: contentTheme.success,
        xValueMapper: (ChartSampleData s, _) => s.x as String,
        yValueMapper: (ChartSampleData s, _) => s.y,
        markerSettings: const MarkerSettings(isVisible: true),
        name: 'Scheduled',
      ),
      SplineSeries<ChartSampleData, String>(
        dataSource: chartData,
        name: 'Completed',
        color: contentTheme.purple,
        markerSettings: const MarkerSettings(isVisible: true),
        xValueMapper: (ChartSampleData s, _) => s.x as String,
        yValueMapper: (ChartSampleData s, _) => s.secondSeriesYValue,
      ),
    ];
  }

  List<ColumnSeries<ChartSampleData, String>> patientByAgeChart() {
    return <ColumnSeries<ChartSampleData, String>>[
      ColumnSeries<ChartSampleData, String>(
        width: 0.8,
        spacing: 0.2,
        dataSource: patientByAge,
        color: contentTheme.primary,
        xValueMapper: (ChartSampleData s, _) => s.x as String,
        yValueMapper: (ChartSampleData s, _) => s.y,
        name: 'Male',
      ),
      ColumnSeries<ChartSampleData, String>(
        dataSource: patientByAge,
        width: 0.8,
        spacing: 0.2,
        color: contentTheme.secondary,
        xValueMapper: (ChartSampleData s, _) => s.x as String,
        yValueMapper: (ChartSampleData s, _) => s.secondSeriesYValue,
        name: 'Female',
      ),
    ];
  }

  @override
  void onClose() {
    _patientsSub?.cancel();
    _doctorsSub?.cancel();
    _authWorker?.dispose();
    super.onClose();
  }
}
