import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseController {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ======================= Alerts =======================
  static Future<DocumentSnapshot> getStockSettings() async {
    return await _firestore
        .collection('app_config')
        .doc('stock_settings')
        .get();
  }

  static Future<void> updateStockSettings(Map<String, dynamic> data) async {
    await _firestore.collection('app_config').doc('stock_settings').set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Stream<QuerySnapshot> getLowStockProducts(int criticalStock) {
    return _firestore
        .collection('product_locations')
        .where('quantity', isLessThan: criticalStock)
        .orderBy('quantity')
        .snapshots();
  }

  static Stream<QuerySnapshot> getExpiredProducts(DateTime thresholdDate) {
    return _firestore
        .collection('product_locations')
        .where('updatedAt', isLessThan: Timestamp.fromDate(thresholdDate))
        .orderBy('updatedAt')
        .snapshots();
  }

  // ======================= Warehouse =======================
  static Future<DocumentSnapshot> getWarehouse(String warehouseId) async {
    return await _firestore.collection('warehouses').doc(warehouseId).get();
  }

  static Future<QuerySnapshot> checkWarehouseExists(String name) {
    return _firestore
        .collection('warehouses')
        .where('name', isEqualTo: name)
        .get();
  }

  static Future<DocumentReference> createWarehouse(Map<String, dynamic> data) {
    return _firestore.collection('warehouses').add(data);
  }

  static Stream<QuerySnapshot> getWarehousesStream() {
    return _firestore.collection('warehouses').snapshots();
  }

  static Future<void> deleteWarehouse(String warehouseId) async {
    WriteBatch batch = _firestore.batch();

    final productLocations =
        await _firestore
            .collection('product_locations')
            .where('warehouseId', isEqualTo: warehouseId)
            .get();

    for (var doc in productLocations.docs) {
      batch.delete(doc.reference);
    }

    final warehouseRef = _firestore.collection('warehouses').doc(warehouseId);
    batch.delete(warehouseRef);
    await batch.commit();
  }

  // ======================= Products =======================
  static Stream<QuerySnapshot> getProductsStream() {
    return _firestore.collection('products').snapshots();
  }

  static Future<QuerySnapshot> checkProductExists(String barcode) {
    return _firestore
        .collection('products')
        .where('barcode', isEqualTo: barcode)
        .get();
  }

  static Future<void> updateProduct(String docId, Map<String, dynamic> data) {
    return _firestore.collection('products').doc(docId).update(data);
  }

  static Future<DocumentReference> createProduct(Map<String, dynamic> data) {
    return _firestore.collection('products').add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<DocumentSnapshot> getProduct(String productId) {
    return _firestore.collection('products').doc(productId).get();
  }

  static Future<void> deleteProduct(String productId) async {
    final locations =
        await _firestore
            .collection('product_locations')
            .where('productId', isEqualTo: productId)
            .get();
    WriteBatch batch =
        _firestore
            .batch(); // Execute many operations at the same time on Firebase
    for (var doc in locations.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(_firestore.collection('products').doc(productId));

    await batch.commit();
  }

  // ======================= Product Locations =======================
  static Future<void> batchUpdateProductLocations(
    List<Map<String, dynamic>> operations,
  ) async {
    WriteBatch batch = _firestore.batch();
    for (var op in operations) {
      final docRef = _firestore
          .collection('product_locations')
          .doc(op['docId']);
      batch.set(docRef, op['data']);
    }
    await batch.commit();
  }

  static Future<void> updateProductQuantity(String docId, int newQty) {
    return _firestore.collection('product_locations').doc(docId).update({
      'quantity': newQty,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<QuerySnapshot> getProductLocationsStream(String warehouseId) {
    return _firestore
        .collection('product_locations')
        .where('warehouseId', isEqualTo: warehouseId)
        .snapshots();
  }

  static Stream<QuerySnapshot> getProductLocationsByPosition(
    String warehouseId,
    int row,
    int col,
  ) {
    return _firestore
        .collection('product_locations')
        .where('warehouseId', isEqualTo: warehouseId)
        .where('row', isEqualTo: row)
        .where('col', isEqualTo: col)
        .snapshots();
  }

  static Future<void> deleteProductLocation(String docId) {
    return _firestore.collection('product_locations').doc(docId).delete();
  }

  static String generateLocationDocId(
    String warehouseId,
    String productId,
    int row,
    int col,
  ) {
    return '${warehouseId}_${productId}_${row}_${col}';
  }
}
