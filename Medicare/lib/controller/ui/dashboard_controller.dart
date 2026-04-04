import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medicare/controller/auth_controller.dart';
import 'package:medicare/helpers/chart_data.dart';
import 'package:medicare/models/user_model.dart';
import 'package:medicare/helpers/utils/ui_mixins.dart';
import 'package:medicare/route_names.dart';
import 'package:medicare/views/my_controller.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class DashboardController extends MyController with UIMixin {
  List<ChartSampleData>? chartData;
  List<ChartSampleData>? patientByAge;
  TooltipBehavior tooltipBehavior = TooltipBehavior(enable: true);

  // Live counts from Firestore
  int totalPatients = 0;
  int totalDoctors = 0;
  int totalAppointments = 0;
  int totalAppointmentsToday = 0;

  // Recent appointments (last 5)
  List<Map<String, dynamic>> recentAppointments = [];

  // Top doctors for the sidebar widget
  List<Map<String, dynamic>> topDoctors = [];

  bool loading = false;

  bool get isAdmin =>
      AppAuthController.instance.user?.role == UserRole.admin;

  String get _hospitalId => AppAuthController.instance.user?.hospitalId ?? '';

  @override
  void onInit() {
    _initChartData();
    super.onInit();
    _loadDashboardData();
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

  Future<void> _loadDashboardData() async {
    loading = true;
    update();

    final db = FirebaseFirestore.instance;
    final hid = _hospitalId;

    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      final yearStart = DateTime(today.year, 1, 1);

      final results = await Future.wait([
        // 0 – total patients
        db.collection('patients').where('hospitalId', isEqualTo: hid).count().get(),
        // 1 – total doctors
        db.collection('doctors').where('hospitalId', isEqualTo: hid).count().get(),
        // 2 – total appointments
        db.collection('appointments').where('hospitalId', isEqualTo: hid).count().get(),
        // 3 – today's appointments
        db
            .collection('appointments')
            .where('hospitalId', isEqualTo: hid)
            .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('dateTime', isLessThan: Timestamp.fromDate(endOfDay))
            .count()
            .get(),
        // 4 – recent 5 appointments
        db
            .collection('appointments')
            .where('hospitalId', isEqualTo: hid)
            .orderBy('createdAt', descending: true)
            .limit(5)
            .get(),
        // 5 – this year's appointments (for monthly chart)
        db
            .collection('appointments')
            .where('hospitalId', isEqualTo: hid)
            .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(yearStart))
            .get(),
        // 6 – this year's patients (for monthly gender chart)
        db
            .collection('patients')
            .where('hospitalId', isEqualTo: hid)
            .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(yearStart))
            .get(),
        // 7 – top 5 doctors
        db.collection('doctors').where('hospitalId', isEqualTo: hid).limit(5).get(),
      ]);

      totalPatients          = (results[0] as AggregateQuerySnapshot).count ?? 0;
      totalDoctors           = (results[1] as AggregateQuerySnapshot).count ?? 0;
      totalAppointments      = (results[2] as AggregateQuerySnapshot).count ?? 0;
      totalAppointmentsToday = (results[3] as AggregateQuerySnapshot).count ?? 0;

      // Recent appointments
      final recentSnap = results[4] as QuerySnapshot<Map<String, dynamic>>;
      recentAppointments = recentSnap.docs.map((doc) {
        final d = doc.data();
        final dt = (d['dateTime'] as Timestamp?)?.toDate() ?? DateTime.now();
        return {
          'id': doc.id,
          'patient_name': d['patientName'] ?? '',
          'gender': d['gender'] ?? '',
          'appointment_for': d['doctorName'] ?? '',
          'date': dt,
          'time': dt,
          'status': d['status'] ?? 'scheduled',
        };
      }).toList();

      // Monthly appointment chart (scheduled vs completed)
      final apptSnap = results[5] as QuerySnapshot<Map<String, dynamic>>;
      final scheduledByMonth = List.filled(12, 0);
      final completedByMonth = List.filled(12, 0);
      for (final doc in apptSnap.docs) {
        final d = doc.data();
        final dt = (d['createdAt'] as Timestamp?)?.toDate();
        if (dt == null) continue;
        final m = dt.month - 1;
        if (d['status'] == 'completed') {
          completedByMonth[m]++;
        } else {
          scheduledByMonth[m]++;
        }
      }

      // Monthly patient registrations by gender
      final patientSnap = results[6] as QuerySnapshot<Map<String, dynamic>>;
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

      // Top doctors list
      final docSnap = results[7] as QuerySnapshot<Map<String, dynamic>>;
      topDoctors = docSnap.docs.map((doc) {
        final d = doc.data();
        return {
          'name': d['name'] as String? ?? '',
          'designation': d['specialization'] as String? ?? '',
        };
      }).toList();
    } catch (_) {
      // Dashboard degrades gracefully — counts stay at 0.
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

  // ── Chart series ────────────────────────────────────────────────────────────

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
}
