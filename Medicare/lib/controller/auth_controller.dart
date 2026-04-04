import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:medicare/models/user_model.dart';
import 'package:medicare/services/auth_service.dart';
import 'package:medicare/services/fcm_service.dart';

class AppAuthController extends GetxController {
  static AppAuthController get instance => Get.find<AppAuthController>();

  final AuthService _authService = AuthService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FcmService _fcmService = FcmService();

  final Rxn<UserModel> appUser = Rxn<UserModel>();

  bool get isLoggedIn => appUser.value != null;
  UserModel? get user => appUser.value;
  UserRole? get role => appUser.value?.role;

  @override
  void onInit() {
    super.onInit();
    _authService.userStream.listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      appUser.value = null;
      return;
    }
    await fetchUser(firebaseUser.uid);
  }

  Future<void> fetchUser(String uid) async {
    try {
      final doc = await _db
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 10));
      if (doc.exists) {
        appUser.value = UserModel.fromFirestore(doc);
        _fcmService.init(uid);
      } else {
        // No Firestore profile — sign out to avoid a broken session
        await _authService.signOut();
      }
    } catch (_) {
      appUser.value = null;
    }
  }

  Future<void> signOut() async {
    final uid = appUser.value?.uid;
    if (uid != null) await _fcmService.clearToken(uid);
    await _authService.signOut();
    appUser.value = null;
    Get.offAllNamed('/auth/login');
  }
}
