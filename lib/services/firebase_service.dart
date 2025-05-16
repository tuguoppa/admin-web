// lib/services/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// --------------------
  /// Authentication
  /// --------------------

  static Future<User?> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// --------------------
  /// Users
  /// --------------------

  static Stream<QuerySnapshot> getUsers() {
    return _firestore.collection('users').snapshots();
  }

  static Future<void> deleteUser(String docId) async {
    await _firestore.collection('users').doc(docId).delete();
  }

  /// --------------------
  /// Staff
  /// --------------------

  static Stream<QuerySnapshot> getStaff() {
    return _firestore.collection('staff').snapshots();
  }

  static Future<void> addStaff(String name, String email) async {
    await _firestore.collection('staff').add({
      'name': name,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteStaff(String docId) async {
    await _firestore.collection('staff').doc(docId).delete();
  }

  /// --------------------
  /// Services
  /// --------------------

  static Stream<QuerySnapshot> getServices() {
    return _firestore.collection('services').snapshots();
  }

  static Future<void> addService(String name, double price) async {
    await _firestore.collection('services').add({
      'name': name,
      'price': price,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteService(String docId) async {
    await _firestore.collection('services').doc(docId).delete();
  }

  /// --------------------
  /// Spare Parts
  /// --------------------

  static Stream<QuerySnapshot> getSpareParts() {
    return _firestore.collection('spareparts').snapshots();
  }

  static Future<void> addSparePart(String name, int stock, double price) async {
    await _firestore.collection('spareparts').add({
      'name': name,
      'stock': stock,
      'price': price,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteSparePart(String docId) async {
    await _firestore.collection('spareparts').doc(docId).delete();
  }
}
