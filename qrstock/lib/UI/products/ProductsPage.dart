import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qrstock/FirebaseController/Firebase_Controller.dart';
import '../../mobileScanner/ScannerScreen.dart';
import '../../themes/colors.dart';
import 'package:intl/intl.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  ProductsPageState createState() => ProductsPageState();
}

class ProductsPageState extends State<ProductsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backGreen,
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.search, color: white),
            hintText: 'Search by name or barcode...',
            hintStyle: TextStyle(color: white),
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: Icon(Icons.clear, color: white),
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
            ),
          ),
          style: TextStyle(color: white, fontSize: 16),
          onChanged:
              (value) =>
                  setState(() => _searchQuery = value.trim().toLowerCase()),
        ),
        backgroundColor: barGreen,
        actions: [
          if (Platform.isAndroid || Platform.isIOS)
            IconButton(
              icon: Icon(Icons.camera_alt, color: white),
              onPressed: _scanBarcode,
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseController.getProductsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allProducts = snapshot.data!.docs;

          final filteredProducts =
              allProducts.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = data['name']?.toString().toLowerCase() ?? '';
                final barcode = data['barcode']?.toString().toLowerCase() ?? '';
                return name.contains(_searchQuery) ||
                    barcode.contains(_searchQuery);
              }).toList();

          if (filteredProducts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _searchQuery.isEmpty ? Icons.inventory : Icons.search_off,
                    size: 60,
                    color: black,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _searchQuery.isEmpty
                        ? 'No products found'
                        : 'No results for "$_searchQuery"',
                    style: TextStyle(
                      fontSize: 20,
                      color: black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredProducts.length,
            itemBuilder: (context, index) {
              final product = filteredProducts[index];
              final data = product.data() as Map<String, dynamic>;

              return Card(
                color: darkGreen,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(
                    data['name'] ?? 'No name',
                    style: TextStyle(color: black),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Barcode: ${data['barcode'] ?? ''}'),
                      Text('Price: ${data['price'] ?? ''}'),
                      Text('Modified by: ${data['lastModifiedBy'] ?? 'N/A'}'),
                      Text(
                        'Last Update: ${data['updatedAt'] != null && data['updatedAt'] is Timestamp ? DateFormat('dd/MM/yyyy HH:mm').format((data['updatedAt'] as Timestamp).toDate()) : 'N/A'}',
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showProductForm(product),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: red),
                        onPressed:
                            () => _confirmDeleteProduct(context, product.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: buttonColor,
        child: const Icon(Icons.add, color: white),
        onPressed: () => _showProductForm(),
      ),
    );
  }

  Future<void> _createOrUpdateProduct([DocumentSnapshot? product]) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'Unauthenticated user';

      final isEditing = product != null;

      if (!isEditing) {
        final barcode = _barcodeController.text.trim();
        if (barcode.isEmpty) throw 'Introduce a valid barcode';

        final existing = await FirebaseController.checkProductExists(barcode);

        if (existing.docs.isNotEmpty) {
          throw 'The code already exists';
        }
      }

      final productData = {
        'barcode': _barcodeController.text.trim(),
        'name': _nameController.text.trim(),
        'price': _priceController.text.trim(),
        'lastModifiedBy': user.email,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (isEditing) {
        await FirebaseController.updateProduct(product.id, productData);
      } else {
        productData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseController.createProduct(productData);
      }

      if (mounted) {
        Navigator.pop(context);
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _deleteProduct(String productId) async {
    try {
      await FirebaseController.deleteProduct(productId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product deleted successfully')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Delete error: $e')));
      }
    }
  }

  void _confirmDeleteProduct(BuildContext context, String productId) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Confirm Delete'),
            content: const Text(
              'Are you sure you want to delete this product?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _deleteProduct(productId);
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  void _showProductForm([DocumentSnapshot? product]) {
    final isEditing = product != null;
    final data = product?.data() as Map<String, dynamic>?;

    _barcodeController.text = isEditing ? (data?['barcode'] ?? '') : '';
    _nameController.text = isEditing ? (data?['name'] ?? '') : '';
    _priceController.text = isEditing ? (data?['price'] ?? '') : '';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(isEditing ? 'Edit Product' : 'New Product'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _barcodeController,
                          decoration: const InputDecoration(
                            labelText: 'Barcode*',
                            border: OutlineInputBorder(),
                          ),
                          readOnly: isEditing,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!isEditing && (Platform.isAndroid || Platform.isIOS))
                        IconButton(
                          icon: const Icon(Icons.camera_alt),
                          onPressed: _scanBarcodeForProductCreation,
                        ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name*',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Price*',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _clearForm();
                  if (mounted) Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async => await _createOrUpdateProduct(product),
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: white,
                ),
                child: Text(isEditing ? 'Save' : 'Create'),
              ),
            ],
          ),
    );
  }

  void _scanBarcodeForProductCreation() async {
    final status = await Permission.camera.request();
    if (status.isGranted && mounted) {
      final String? scanResult = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ScannerScreen()),
      );
      if (scanResult != null && mounted) {
        final parts = scanResult.split('|');
        if (parts.length == 3) {
          _barcodeController.text = parts[0];
          _nameController.text = parts[1];
          _priceController.text = parts[2];
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Incomplete format, Correct Format is : Barcode|Name|Price. Try again with the correct format.',
              ),
              backgroundColor: red,
            ),
          );
        }
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera access required'),
          backgroundColor: red,
        ),
      );
    }
  }

  void _scanBarcode() async {
    final status = await Permission.camera.request();

    if (status.isGranted && mounted) {
      final String? barcode = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ScannerScreen()),
      );

      if (barcode != null && mounted) {
        _searchController.text = barcode;
        setState(() => _searchQuery = barcode.trim().toLowerCase());
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera access required'),
          backgroundColor: red,
        ),
      );
    }
  }

  void _clearForm() {
    _barcodeController.clear();
    _nameController.clear();
    _priceController.clear();
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
