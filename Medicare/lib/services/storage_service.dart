import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Generic primitives ───────────────────────────────────────────────────

  Reference ref(String path) => _storage.ref(path);

  Future<String> getDownloadUrl(String path) =>
      _storage.ref(path).getDownloadURL();

  Future<void> delete(String path) => _storage.ref(path).delete();

  /// Uploads [bytes] to [storagePath] and returns the download URL.
  /// Pass [onProgress] to receive 0.0–1.0 progress updates.
  Future<String> _upload(
    String storagePath,
    Uint8List bytes,
    String contentType, {
    void Function(double)? onProgress,
  }) async {
    final ref = _storage.ref(storagePath);
    final task = ref.putData(bytes, SettableMetadata(contentType: contentType));

    if (onProgress != null) {
      task.snapshotEvents.listen((snap) {
        if (snap.totalBytes > 0) {
          onProgress(snap.bytesTransferred / snap.totalBytes);
        }
      });
    }

    final snap = await task;
    return snap.ref.getDownloadURL();
  }

  // ── Patient avatar ───────────────────────────────────────────────────────

  /// Uploads a patient profile image, saves the URL to Firestore, returns URL.
  Future<String> uploadPatientAvatar(
    String patientId,
    Uint8List bytes,
    String contentType, {
    void Function(double)? onProgress,
  }) async {
    final url = await _upload(
      'patients/$patientId/avatar',
      bytes,
      contentType,
      onProgress: onProgress,
    );
    await _db.collection('patients').doc(patientId).update({'avatarUrl': url});
    return url;
  }

  // ── Doctor avatar ────────────────────────────────────────────────────────

  /// Uploads a doctor profile image, saves the URL to Firestore, returns URL.
  Future<String> uploadDoctorAvatar(
    String doctorId,
    Uint8List bytes,
    String contentType, {
    void Function(double)? onProgress,
  }) async {
    final url = await _upload(
      'doctors/$doctorId/avatar',
      bytes,
      contentType,
      onProgress: onProgress,
    );
    await _db.collection('doctors').doc(doctorId).update({'avatarUrl': url});
    return url;
  }

  // ── Patient medical reports ──────────────────────────────────────────────

  /// Uploads a PDF or image report, appends the URL to the patient's
  /// `reports` array in Firestore, returns the download URL.
  Future<String> uploadPatientReport(
    String patientId,
    String filename,
    Uint8List bytes,
    String contentType, {
    void Function(double)? onProgress,
  }) async {
    final safeName = filename.replaceAll(RegExp(r'[^\w.\-]'), '_');
    final url = await _upload(
      'patients/$patientId/reports/$safeName',
      bytes,
      contentType,
      onProgress: onProgress,
    );
    await _db.collection('patients').doc(patientId).update({
      'reports': FieldValue.arrayUnion([
        {'name': filename, 'url': url, 'uploadedAt': Timestamp.now()}
      ]),
    });
    return url;
  }
}
