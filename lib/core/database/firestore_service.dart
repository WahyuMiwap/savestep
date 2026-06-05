import 'package:cloud_firestore/cloud_firestore.dart';
import 'database_service.dart';

class FirestoreService implements DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String uid;

  FirestoreService(this.uid);

  // Semua koleksi data akan disimpan di bawah folder UID user (demi keamanan dan privasi)
  // Contoh letak data: users/{uid}/notes/{id_catatan}
  CollectionReference _collection(String path) {
    return _db.collection('users').doc(uid).collection(path);
  }

  @override
  Future<void> create(String collection, String id, Map<String, dynamic> data) async {
    await _collection(collection).doc(id).set(data);
  }

  @override
  Future<List<Map<String, dynamic>>> readAll(String collection) async {
    final snapshot = await _collection(collection).get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id; // Menyisipkan ID ke dalam map
      return data;
    }).toList();
  }

  @override
  Future<Map<String, dynamic>?> read(String collection, String id) async {
    final doc = await _collection(collection).doc(id).get();
    if (!doc.exists) return null;
    
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return data;
  }

  @override
  Future<void> update(String collection, String id, Map<String, dynamic> data) async {
    await _collection(collection).doc(id).update(data);
  }

  @override
  Future<void> delete(String collection, String id) async {
    await _collection(collection).doc(id).delete();
  }
}
