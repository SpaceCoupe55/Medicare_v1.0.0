import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:medicare/controller/auth_controller.dart';
import 'package:medicare/models/pharmacy_model.dart';
import 'package:medicare/views/my_controller.dart';

class PharmacyListController extends MyController {
  // Exposed as List (dynamic maps) so existing UI map-access syntax still works.
  List<Map<String, dynamic>> products = [];
  bool loading = false;
  bool loadingMore = false;
  bool hasMore = true;
  String? errorMessage;

  final List<PharmacyModel> _items = [];
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
      _items.clear();
      products = [];
    }

    if (!hasMore) return;

    if (_items.isEmpty) {
      loading = true;
    } else {
      loadingMore = true;
    }
    errorMessage = null;
    update();

    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('pharmacy')
          .where('hospitalId', isEqualTo: _hospitalId)
          .orderBy('name')
          .limit(_pageSize);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snap = await query.get();
      final newItems = snap.docs.map(PharmacyModel.fromFirestore).toList();

      _items.addAll(newItems);
      products = _items.map((p) => p.toDisplayMap()).toList();
      _lastDocument = snap.docs.isNotEmpty ? snap.docs.last : null;
      hasMore = snap.docs.length == _pageSize;
    } catch (e) {
      errorMessage = 'Failed to load pharmacy items. Please try again.';
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

  PharmacyModel? getItemById(String id) {
    try {
      return _items.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  void goToDetails() {
    Get.toNamed('/detail');
  }
}
