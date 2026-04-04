import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _db.collection(path);
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getDocument(
      String collection, String docId) {
    return _db.collection(collection).doc(docId).get();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getCollection(
      String collection) {
    return _db.collection(collection).get();
  }

  Future<DocumentReference<Map<String, dynamic>>> addDocument(
      String collection, Map<String, dynamic> data) {
    return _db.collection(collection).add(data);
  }

  Future<void> setDocument(
      String collection, String docId, Map<String, dynamic> data) {
    return _db.collection(collection).doc(docId).set(data);
  }

  Future<void> updateDocument(
      String collection, String docId, Map<String, dynamic> data) {
    return _db.collection(collection).doc(docId).update(data);
  }

  Future<void> deleteDocument(String collection, String docId) {
    return _db.collection(collection).doc(docId).delete();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamCollection(
      String collection) {
    return _db.collection(collection).snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamDocument(
      String collection, String docId) {
    return _db.collection(collection).doc(docId).snapshots();
  }
}
