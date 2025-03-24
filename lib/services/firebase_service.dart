import 'package:cloud_firestore/cloud_firestore.dart';

class MyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionName = 'myCollection'; // Koleksiyon adınızı buraya yazın

  // Create
  Future<void> addItem(Map<String, dynamic> data) async {
    await _firestore.collection(collectionName).add(data);
  }

  // Read
  Future<List<Map<String, dynamic>>> getItems() async {
    QuerySnapshot snapshot = await _firestore.collection(collectionName).get();
    return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  // Update
  Future<void> updateItem(String id, Map<String, dynamic> data) async {
    await _firestore.collection(collectionName).doc(id).update(data);
  }

  // Delete
  Future<void> deleteItem(String id) async {
    await _firestore.collection(collectionName).doc(id).delete();
  }
}
