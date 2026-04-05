import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:medicare/controller/auth_controller.dart';
import 'package:medicare/helpers/chart_data.dart';
import 'package:medicare/helpers/utils/ui_mixins.dart';
import 'package:medicare/views/my_controller.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ReportsController extends MyController with UIMixin {
  bool loading = false;
  String? errorMessage;
  bool _dataLoaded = false;
  Worker? _authWorker;

  // Chart 1 — Monthly appointments by status (12 months, current year)
  List<ChartSampleData> monthlyAppointments = [];

  // Chart 2 — Monthly patient registrations (current year)
  List<ChartSampleData> monthlyPatients = [];

  // Chart 3 — Appointment status breakdown (donut)
  int scheduledCount = 0;
  int completedCount = 0;
  int cancelledCount = 0;

  // Chart 4 — Patients by blood type
  List<ChartSampleData> bloodGroupData = [];

  // Chart 5 — Doctors by specialization
  List<ChartSampleData> specializationData = [];

  TooltipBehavior tooltipBehavior = TooltipBehavior(enable: true);

  String get _hospitalId => AppAuthController.instance.user?.hospitalId ?? '';

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  void onInit() {
    super.onInit();
    _seedEmpty();

    // Load immediately if user is already available, otherwise wait.
    final existing = AppAuthController.instance.user;
    if (existing != null && existing.hospitalId.isNotEmpty) {
      _dataLoaded = true;
      loadData();
    }

    _authWorker = ever(AppAuthController.instance.appUser, (user) {
      if (user != null && (user as dynamic).hospitalId?.isNotEmpty == true && !_dataLoaded) {
        _dataLoaded = true;
        loadData();
      }
    });
  }

  @override
  void onClose() {
    _authWorker?.dispose();
    super.onClose();
  }

  void _seedEmpty() {
    monthlyAppointments = List.generate(
      12,
      (i) => ChartSampleData(x: _months[i], y: 0, secondSeriesYValue: 0, thirdSeriesYValue: 0),
    );
    monthlyPatients = List.generate(
      12,
      (i) => ChartSampleData(x: _months[i], y: 0),
    );
    bloodGroupData = [];
    specializationData = [];
  }

  Future<void> loadData() async {
    loading = true;
    errorMessage = null;
    update();

    final db = FirebaseFirestore.instance;
    final hid = _hospitalId;
    final now = DateTime.now();
    final yearStart = DateTime(now.year, 1, 1);
    final yearEnd = DateTime(now.year + 1, 1, 1);

    try {
      final results = await Future.wait([
        // 0 — appointments this year
        db
            .collection('appointments')
            .where('hospitalId', isEqualTo: hid)
            .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(yearStart))
            .where('createdAt', isLessThan: Timestamp.fromDate(yearEnd))
            .get(),
        // 1 — patients this year
        db
            .collection('patients')
            .where('hospitalId', isEqualTo: hid)
            .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(yearStart))
            .get(),
        // 2 — all doctors (small collection)
        db
            .collection('doctors')
            .where('hospitalId', isEqualTo: hid)
            .limit(200)
            .get(),
      ]);

      // ── Chart 1 + 3: appointments by month and status ────────────────────
      final apptSnap = results[0];
      final scheduledByMonth = List.filled(12, 0);
      final completedByMonth = List.filled(12, 0);
      final cancelledByMonth = List.filled(12, 0);
      scheduledCount = 0;
      completedCount = 0;
      cancelledCount = 0;

      for (final doc in apptSnap.docs) {
        final d = doc.data();
        final dt = (d['createdAt'] as Timestamp?)?.toDate();
        if (dt == null) continue;
        final m = dt.month - 1;
        final status = (d['status'] as String? ?? 'scheduled').toLowerCase();
        if (status == 'completed') {
          completedByMonth[m]++;
          completedCount++;
        } else if (status == 'cancelled') {
          cancelledByMonth[m]++;
          cancelledCount++;
        } else {
          scheduledByMonth[m]++;
          scheduledCount++;
        }
      }

      monthlyAppointments = List.generate(
        12,
        (i) => ChartSampleData(
          x: _months[i],
          y: scheduledByMonth[i],
          secondSeriesYValue: completedByMonth[i],
          thirdSeriesYValue: cancelledByMonth[i],
        ),
      );

      // ── Chart 2 + 4: patients by month and blood type ────────────────────
      final patientSnap = results[1];
      final patientsByMonth = List.filled(12, 0);
      final bloodMap = <String, int>{};

      for (final doc in patientSnap.docs) {
        final d = doc.data();
        final dt = (d['createdAt'] as Timestamp?)?.toDate();
        if (dt != null) patientsByMonth[dt.month - 1]++;
        final blood = (d['bloodType'] as String? ?? 'Unknown').trim();
        bloodMap[blood] = (bloodMap[blood] ?? 0) + 1;
      }

      monthlyPatients = List.generate(
        12,
        (i) => ChartSampleData(x: _months[i], y: patientsByMonth[i]),
      );

      bloodGroupData = bloodMap.entries
          .map((e) => ChartSampleData(x: e.key, y: e.value))
          .toList()
        ..sort((a, b) => (b.y ?? 0).compareTo(a.y ?? 0));

      // ── Chart 5: doctors by specialization ───────────────────────────────
      final docSnap = results[2];
      final specMap = <String, int>{};

      for (final doc in docSnap.docs) {
        final spec = (doc.data()['specialization'] as String? ?? 'General').trim();
        specMap[spec] = (specMap[spec] ?? 0) + 1;
      }

      specializationData = specMap.entries
          .map((e) => ChartSampleData(x: e.key, y: e.value))
          .toList()
        ..sort((a, b) => (b.y ?? 0).compareTo(a.y ?? 0));
    } catch (e) {
      errorMessage = 'Failed to load report data. Please try again.';
    } finally {
      loading = false;
      update();
    }
  }

  // ── Chart series builders ─────────────────────────────────────────────────

  List<SplineSeries<ChartSampleData, String>> appointmentTrendSeries() {
    return [
      SplineSeries<ChartSampleData, String>(
        name: 'Scheduled',
        dataSource: monthlyAppointments,
        color: contentTheme.primary,
        markerSettings: const MarkerSettings(isVisible: true),
        xValueMapper: (s, _) => s.x as String,
        yValueMapper: (s, _) => s.y,
      ),
      SplineSeries<ChartSampleData, String>(
        name: 'Completed',
        dataSource: monthlyAppointments,
        color: contentTheme.success,
        markerSettings: const MarkerSettings(isVisible: true),
        xValueMapper: (s, _) => s.x as String,
        yValueMapper: (s, _) => s.secondSeriesYValue,
      ),
      SplineSeries<ChartSampleData, String>(
        name: 'Cancelled',
        dataSource: monthlyAppointments,
        color: contentTheme.danger,
        markerSettings: const MarkerSettings(isVisible: true),
        xValueMapper: (s, _) => s.x as String,
        yValueMapper: (s, _) => s.thirdSeriesYValue,
      ),
    ];
  }

  List<ColumnSeries<ChartSampleData, String>> patientGrowthSeries() {
    return [
      ColumnSeries<ChartSampleData, String>(
        name: 'Registrations',
        dataSource: monthlyPatients,
        color: contentTheme.primary,
        width: 0.6,
        xValueMapper: (s, _) => s.x as String,
        yValueMapper: (s, _) => s.y,
      ),
    ];
  }

  List<ChartSampleData> statusDonutData() {
    return [
      ChartSampleData(x: 'Scheduled', y: scheduledCount, pointColor: contentTheme.primary),
      ChartSampleData(x: 'Completed', y: completedCount, pointColor: contentTheme.success),
      ChartSampleData(x: 'Cancelled', y: cancelledCount, pointColor: contentTheme.danger),
    ];
  }

  List<BarSeries<ChartSampleData, String>> bloodGroupSeries() {
    return [
      BarSeries<ChartSampleData, String>(
        name: 'Patients',
        dataSource: bloodGroupData,
        color: contentTheme.secondary,
        xValueMapper: (s, _) => s.x as String,
        yValueMapper: (s, _) => s.y,
      ),
    ];
  }

  List<BarSeries<ChartSampleData, String>> specializationSeries() {
    return [
      BarSeries<ChartSampleData, String>(
        name: 'Doctors',
        dataSource: specializationData,
        color: contentTheme.purple,
        xValueMapper: (s, _) => s.x as String,
        yValueMapper: (s, _) => s.y,
      ),
    ];
  }
}
