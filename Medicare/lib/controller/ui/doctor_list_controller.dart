import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:medicare/controller/auth_controller.dart';
import 'package:medicare/models/doctor_model.dart';
import 'package:medicare/views/my_controller.dart';

class DoctorListController extends MyController {
  List<DoctorModel> doctors = [];
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
      doctors = [];
    }

    if (!hasMore) return;

    if (doctors.isEmpty) {
      loading = true;
    } else {
      loadingMore = true;
    }
    errorMessage = null;
    update();

    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('doctors')
          .where('hospitalId', isEqualTo: _hospitalId)
          .orderBy('createdAt', descending: true)
          .limit(_pageSize);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snap = await query.get();
      final newItems = snap.docs.map(DoctorModel.fromFirestore).toList();

      doctors.addAll(newItems);
      _lastDocument = snap.docs.isNotEmpty ? snap.docs.last : null;
      hasMore = snap.docs.length == _pageSize;
    } catch (e) {
      errorMessage = 'Failed to load doctors. Please try again.';
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

  Future<void> deleteDoctor(String id) async {
    try {
      await FirebaseFirestore.instance.collection('doctors').doc(id).delete();
      doctors.removeWhere((d) => d.id == id);
      update();
    } catch (_) {
      errorMessage = 'Failed to delete doctor.';
      update();
    }
  }

  void goEditDoctorScreen() {
    Get.toNamed('/admin/doctor/edit');
  }

  void goDetailDoctorScreen() {
    Get.toNamed('/admin/doctor/detail');
  }

  void addDoctor() {
    Get.toNamed('/admin/doctor/add');
  }
}
