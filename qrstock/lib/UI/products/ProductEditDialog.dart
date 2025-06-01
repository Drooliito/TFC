import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../FirebaseController/Firebase_Controller.dart';
import 'package:qrstock/themes/colors.dart';
import 'dart:io';

import '../../mobileScanner/ScannerScreen.dart';

class ProductEditDialog extends StatefulWidget {
  final String warehouseId;
  final int row;
  final int col;

  const ProductEditDialog({
    super.key,
    required this.warehouseId,
    required this.row,
    required this.col,
  });

  @override
  _ProductEditDialogState createState() => _ProductEditDialogState();
}

class _ProductEditDialogState extends State<ProductEditDialog> {
  final Set<String> _selectedProducts = {};
  final Map<String, TextEditingController> _quantityControllers = {};

  @override
  void dispose() {
    for (var controller in _quantityControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _assignToShelf() async {
    if (_selectedProducts.isEmpty) return;

    try {
      final operations =
          _selectedProducts
              .map(
                (productId) => {
                  'docId': FirebaseController.generateLocationDocId(
                    widget.warehouseId,
                    productId,
                    widget.row,
                    widget.col,
                  ),
                  'data': {
                    'warehouseId': widget.warehouseId,
                    'productId': productId,
                    'row': widget.row,
                    'col': widget.col,
                    'quantity': int.parse(
                      _quantityControllers[productId]!.text,
                    ),
                    'createdAt': FieldValue.serverTimestamp(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  },
                },
              )
              .toList();

      await FirebaseController.batchUpdateProductLocations(operations);
      _selectedProducts.clear();
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Future<void> _showEditQuantityDialog(String productId, int currentQty) async {
    final controller = TextEditingController(text: currentQty.toString());

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Quantity'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'New Quantity',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () async {
                try {
                  final newQty = int.parse(controller.text);
                  if (newQty <= 0) throw Exception('Invalid quantity');

                  await FirebaseController.updateProductQuantity(
                    FirebaseController.generateLocationDocId(
                      widget.warehouseId,
                      productId,
                      widget.row,
                      widget.col,
                    ),
                    newQty,
                  );

                  Navigator.of(context).pop();
                  setState(() {});
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _removeFromShelf(String productId) async {
    try {
      await FirebaseController.deleteProductLocation(
        FirebaseController.generateLocationDocId(
          widget.warehouseId,
          productId,
          widget.row,
          widget.col,
        ),
      );
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseController.getProductsStream(),
      builder: (context, productsSnapshot) {
        if (productsSnapshot.hasError) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text(productsSnapshot.error.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseController.getProductLocationsByPosition(
            widget.warehouseId,
            widget.row,
            widget.col,
          ),
          builder: (context, locationsSnapshot) {
            if (locationsSnapshot.hasError) {
              return AlertDialog(
                title: const Text('Error'),
                content: Text(locationsSnapshot.error.toString()),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              );
            }

            if (!productsSnapshot.hasData || !locationsSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final allProducts = productsSnapshot.data!.docs;
            final currentLocations = locationsSnapshot.data!.docs;

            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Manage ${widget.row + 1}-${widget.col + 1}'),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildCurrentProducts(currentLocations, allProducts),
                        const Divider(height: 30),
                        _buildAvailableProducts(allProducts, currentLocations),
                      ],
                    ),
                  ),
                  actions: [
                    if (_selectedProducts.isNotEmpty)
                      Center(
                        child: ElevatedButton(
                          onPressed: _assignToShelf,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: buttonColor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(200, 50),
                          ),
                          child: const Text('Assign Selected'),
                        ),
                      ),
                  ],
                  contentPadding: const EdgeInsets.fromLTRB(
                    24.0,
                    20.0,
                    24.0,
                    0.0,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCurrentProducts(
    List<QueryDocumentSnapshot> locations,
    List<QueryDocumentSnapshot> allProducts,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Current Products:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        ...locations.map((location) {
          final matchingProducts =
              allProducts.where((p) => p.id == location['productId']).toList();

          if (matchingProducts.isEmpty) return const SizedBox.shrink();

          final product = matchingProducts.first;
          final currentQty = location['quantity'] as int;

          return ListTile(
            title: Text(product['name']),
            subtitle: Text('Quantity: $currentQty'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed:
                      () => _showEditQuantityDialog(product.id, currentQty),
                  tooltip: 'Edit quantity',
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeFromShelf(product.id),
                  tooltip: 'Delete',
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAvailableProducts(
    List<QueryDocumentSnapshot> allProducts,
    List<QueryDocumentSnapshot> currentLocations,
  ) {
    final currentProductIds =
        currentLocations.map((loc) => loc['productId']).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (Platform.isAndroid || Platform.isIOS)
          ElevatedButton.icon(
            onPressed: _scanAndAssignProduct,
            icon: const Icon(Icons.qr_code_scanner, color: white),
            label: const Text('Scan Product'),
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: white,
              minimumSize: const Size(double.infinity, 50),
            ),
          ),

        const SizedBox(height: 10),
        const Text(
          'Available Products:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        ...allProducts
            .where((product) => !currentProductIds.contains(product.id))
            .map((product) {
              _quantityControllers.putIfAbsent(
                product.id,
                () => TextEditingController(text: '1'),
              );

              return CheckboxListTile(
                title: Text(product['name']),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Barcode: ${product['barcode']}'),
                    SizedBox(
                      width: 100,
                      child: TextField(
                        controller: _quantityControllers[product.id],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                value: _selectedProducts.contains(product.id),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedProducts.add(product.id);
                    } else {
                      _selectedProducts.remove(product.id);
                    }
                  });
                },
              );
            }),
      ],
    );
  }

  Future<void> _scanAndAssignProduct() async {
    final status = await Permission.camera.request();

    if (!status.isGranted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Camera permission denied')));
      return;
    }

    final String? barcode = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScannerScreen()),
    );

    if (barcode == null) return;

    try {
      final query = await FirebaseController.checkProductExists(barcode);

      if (query.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No product found with barcode $barcode')),
        );
        return;
      }

      final product = query.docs.first;
      final productId = product.id;

      setState(() {
        _selectedProducts.add(productId);
        _quantityControllers.putIfAbsent(
          productId,
          () => TextEditingController(text: '1'),
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Product ${product['name']} added')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }
}
