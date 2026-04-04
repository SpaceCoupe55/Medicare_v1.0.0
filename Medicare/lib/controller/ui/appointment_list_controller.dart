import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:medicare/controller/auth_controller.dart';
import 'package:medicare/models/appointment_model.dart';
import 'package:medicare/route_names.dart';
import 'package:medicare/views/my_controller.dart';

class AppointmentListController extends MyController {
  List<AppointmentModel> appointmentListModel = [];
  bool loading = false;
  bool loadingMore = false;
  bool hasMore = true;
  String? errorMessage;

  DocumentSnapshot? _lastDocument;
  static const int _pageSize = 20;

  String get _hospitalId => AppAuthController.instance.user?.hospitalId ?? '';

  @override
  void onInit() {
    super.onInit();
    _loadPage();
  }

  Future<void> _loadPage({bool isRefresh = false}) async {
    if (isRefresh) {
      _lastDocument = null;
      hasMore = true;
      appointmentListModel = [];
    }

    if (!hasMore) return;

    if (appointmentListModel.isEmpty) {
      loading = true;
    } else {
      loadingMore = true;
    }
    errorMessage = null;
    update();

    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('appointments')
          .where('hospitalId', isEqualTo: _hospitalId)
          .orderBy('createdAt', descending: true)
          .limit(_pageSize);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snap = await query.get();
      final newItems = snap.docs.map(AppointmentModel.fromFirestore).toList();

      appointmentListModel.addAll(newItems);
      _lastDocument = snap.docs.isNotEmpty ? snap.docs.last : null;
      hasMore = snap.docs.length == _pageSize;
    } catch (e) {
      errorMessage = 'Failed to load appointments. Please try again.';
    } finally {
      loading = false;
      loadingMore = false;
      update();
    }
  }

  Future<void> refreshList() => _loadPage(isRefresh: true);

  Future<void> loadMore() async {
    if (!loadingMore && hasMore) await _loadPage();
  }

  Future<void> deleteAppointment(String id) async {
    try {
      await FirebaseFirestore.instance.collection('appointments').doc(id).delete();
      appointmentListModel.removeWhere((a) => a.id == id);
      update();
    } catch (_) {
      errorMessage = 'Failed to delete appointment.';
      update();
    }
  }

  void bookAppointment() {
    Get.toNamed(AppRoutes.appointmentBook);
  }

  void goToSchedulingEditScreen(AppointmentModel appointment) {
    Get.toNamed(AppRoutes.appointmentEdit, arguments: appointment);
  }

  void goToSchedulingScreen() {
    Get.toNamed(AppRoutes.appointmentSchedule);
  }
}
