import 'package:cloud_firestore/cloud_firestore.dart';

FirebaseFirestore db = FirebaseFirestore.instance;

//CRUD
class FirebaseService {
  final CollectionReference productos = FirebaseFirestore.instance.collection(
    'productos',
  );

  // ---------- Productos ----------
  Future<void> addProducto(Map<String, dynamic> data) {
    return productos.add(data);
  }

  Stream<QuerySnapshot> getProductos() {
    return productos.snapshots();
  }

  Future<void> updateProducto(String id, Map<String, dynamic> data) {
    return productos.doc(id).update(data);
  }

  Future<void> deleteProducto(String id) {
    return productos.doc(id).delete();
  }
}
