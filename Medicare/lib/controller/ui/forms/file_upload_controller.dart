import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:medicare/services/storage_service.dart';
import 'package:medicare/views/my_controller.dart';

enum UploadStatus { idle, uploading, done, error }

class FileUploadController extends MyController {
  // Picked files — UI reads this list for display (unchanged)
  List<PlatformFile> files = [];
  bool selectMultipleFile = false;
  FileType type = FileType.any;

  // Upload state per file (keyed by PlatformFile.name)
  final Map<String, double> uploadProgress = {};
  final Map<String, String> downloadUrls = {};
  final Map<String, String> uploadErrors = {};
  UploadStatus uploadStatus = UploadStatus.idle;

  final StorageService _storageService = StorageService();

  // Optional context: set before calling uploadFiles() to scope the upload path.
  String? patientId;
  String? doctorId;

  Future<void> pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: selectMultipleFile,
      type: type,
      withData: true, // ensure bytes are available on web
    );
    if (result?.files.isNotEmpty ?? false) {
      files.addAll(result!.files);
    }
    update();
  }

  void onSelectMultipleFile(value) {
    selectMultipleFile = value ?? selectMultipleFile;
    update();
  }

  void removeFile(PlatformFile file) {
    files.remove(file);
    uploadProgress.remove(file.name);
    downloadUrls.remove(file.name);
    uploadErrors.remove(file.name);
    update();
  }

  /// Uploads all picked files to Firebase Storage.
  /// - If [patientId] is set: images go to patient avatar; other files go to reports.
  /// - If [doctorId] is set: files go to doctor avatar.
  /// - Otherwise: uploads to a generic `uploads/` path.
  Future<void> uploadFiles() async {
    if (files.isEmpty) return;

    uploadStatus = UploadStatus.uploading;
    uploadErrors.clear();
    update();

    for (final file in files) {
      final bytes = file.bytes;
      if (bytes == null) {
        uploadErrors[file.name] = 'No file data available.';
        update();
        continue;
      }

      final contentType = _guessContentType(file.name);

      try {
        uploadProgress[file.name] = 0.0;
        update();

        String url;

        if (patientId != null) {
          final isImage = contentType.startsWith('image/');
          if (isImage) {
            url = await _storageService.uploadPatientAvatar(
              patientId!,
              bytes,
              contentType,
              onProgress: (p) {
                uploadProgress[file.name] = p;
                update();
              },
            );
          } else {
            url = await _storageService.uploadPatientReport(
              patientId!,
              file.name,
              bytes,
              contentType,
              onProgress: (p) {
                uploadProgress[file.name] = p;
                update();
              },
            );
          }
        } else if (doctorId != null) {
          url = await _storageService.uploadDoctorAvatar(
            doctorId!,
            bytes,
            contentType,
            onProgress: (p) {
              uploadProgress[file.name] = p;
              update();
            },
          );
        } else {
          // Generic upload (demo mode — no Firestore update)
          url = await _storageService.ref('uploads/${file.name}').putData(
                bytes,
                SettableMetadata(contentType: contentType),
              ).then((snap) => snap.ref.getDownloadURL());
        }

        uploadProgress[file.name] = 1.0;
        downloadUrls[file.name] = url;
      } catch (e) {
        uploadErrors[file.name] = 'Upload failed: ${e.toString()}';
      }
      update();
    }

    uploadStatus =
        uploadErrors.isEmpty ? UploadStatus.done : UploadStatus.error;
    update();
  }

  void clearAll() {
    files.clear();
    uploadProgress.clear();
    downloadUrls.clear();
    uploadErrors.clear();
    uploadStatus = UploadStatus.idle;
    update();
  }

  static String _guessContentType(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    const map = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'pdf': 'application/pdf',
    };
    return map[ext] ?? 'application/octet-stream';
  }
}
