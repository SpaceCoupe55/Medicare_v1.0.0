import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medicare/controller/auth_controller.dart';
import 'package:medicare/images.dart';
import 'package:medicare/model/drag_n_drop.dart';
import 'package:medicare/views/my_controller.dart';

/// Loads recent appointment activity from Firestore and exposes it as
/// [DragNDropModel] objects so the existing TimeLineScreen widget tree
/// requires no structural changes.
///
/// Field mapping:
///   contactName → patient name
///   location    → doctor name
///   createdAt   → appointment date/time
///   image       → avatar placeholder
class TimeLineController extends MyController {
  List<DragNDropModel> timeline = [];
  List<String> dummyTexts = [];
  bool loading = false;

  String get _hospitalId => AppAuthController.instance.user?.hospitalId ?? '';

  @override
  void onInit() {
    super.onInit();
    _loadTimeline();
  }

  Future<void> _loadTimeline() async {
    loading = true;
    update();
    try {
      final snap = await FirebaseFirestore.instance
          .collection('appointments')
          .where('hospitalId', isEqualTo: _hospitalId)
          .orderBy('createdAt', descending: true)
          .limit(8)
          .get();

      timeline = snap.docs.asMap().entries.map((entry) {
        final index = entry.key;
        final doc = entry.value;
        final data = doc.data();
        final dt = (data['dateTime'] as Timestamp?)?.toDate() ?? DateTime.now();
        return DragNDropModel(
          index,
          data['patientName'] as String? ?? 'Unknown Patient',
          '',
          data['doctorName'] as String? ?? '',
          0,
          dt,
          Images.avatars[index % Images.avatars.length],
        );
      }).toList();

      dummyTexts = snap.docs.map((doc) {
        final data = doc.data();
        final rawStatus = data['status'] as String? ?? 'scheduled';
        final status =
            rawStatus[0].toUpperCase() + rawStatus.substring(1);
        final notes = data['notes'] as String? ?? '';
        return notes.isNotEmpty ? '$status — $notes' : 'Status: $status';
      }).toList();
    } catch (_) {
      timeline = [];
      dummyTexts = [];
    } finally {
      loading = false;
      update();
    }
  }
}
