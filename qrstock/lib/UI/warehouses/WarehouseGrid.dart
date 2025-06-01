import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../FirebaseController/Firebase_Controller.dart';
import 'package:qrstock/UI/products/ProductEditDialog.dart';
import '../../mobileScanner/ScannerScreen.dart';
import '../../themes/colors.dart';

class WarehouseGrid extends StatefulWidget {
  final String warehouseId;

  const WarehouseGrid({super.key, required this.warehouseId});

  @override
  _WarehouseGridState createState() => _WarehouseGridState();
}

class _WarehouseGridState extends State<WarehouseGrid> {
  List<List<Cell>> _grid = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Map<String, Map<String, dynamic>> _allProducts = {};

  @override
  void initState() {
    super.initState();
    _loadGrid();
    _loadAllProducts();
  }

  Future<void> _loadGrid() async {
    try {
      final doc = await FirebaseController.getWarehouse(widget.warehouseId);

      if (!doc.exists) throw Exception("Warehouse not found");

      final data = doc.data()! as Map<String, dynamic>;
      final gridData = data['grid'] as Map<String, dynamic>;

      setState(() {
        _grid = _initializeGrid(
          (gridData['rows'] as int?) ?? 0,
          (gridData['cols'] as int?) ?? 0,
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Error: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAllProducts() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('products').get();
    setState(() {
      _allProducts = {for (var doc in snapshot.docs) doc.id: doc.data()};
    });
  }

  List<List<Cell>> _initializeGrid(int rows, int cols) {
    return List.generate(rows, (row) {
      return List.generate(cols, (col) => Cell(row: row, col: col));
    });
  }

  void _showProductDialog(int row, int col) {
    showDialog(
      context: context,
      builder:
          (context) => ProductEditDialog(
            warehouseId: widget.warehouseId,
            row: row,
            col: col,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _buildGrid(),
    );
  }

  Widget _buildGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseController.getProductLocationsStream(widget.warehouseId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final locations = snapshot.data?.docs ?? [];

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _grid.first.length,
            childAspectRatio: 1.0,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: _grid.length * _grid.first.length,
          itemBuilder: (ctx, index) {
            final row = index ~/ _grid.first.length;
            final col = index % _grid.first.length;

            final productsInCell =
                locations.where((doc) {
                  return doc['row'] == row && doc['col'] == col;
                }).toList();

            final matchesSearch =
                _searchQuery.isNotEmpty
                    ? productsInCell.any((doc) {
                      final productId = doc['productId'];
                      final productData = _allProducts[productId];
                      if (productData == null) return false;

                      final name =
                          productData['name']?.toString().toLowerCase() ?? '';
                      final barcode =
                          productData['barcode']?.toString().toLowerCase() ??
                          '';
                      return name.contains(_searchQuery) ||
                          barcode.contains(_searchQuery);
                    })
                    : false;

            final colorCell =
                matchesSearch
                    ? buttonColor
                    : (productsInCell.isEmpty ? blueCell : greenCell);

            return _buildCell(row, col, colorCell, productsInCell.length);
          },
        );
      },
    );
  }

  Widget _buildCell(int row, int col, Color colorCell, int productCount) {
    return GestureDetector(
      onTap: () => _showProductDialog(row, col),
      child: Container(
        decoration: BoxDecoration(
          color: colorCell,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                '${row + 1}-${col + 1}',
                style: TextStyle(color: black, fontWeight: FontWeight.bold),
              ),
            ),
            if (productCount > 0)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$productCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
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
}

class Cell {
  final int row;
  final int col;

  const Cell({required this.row, required this.col});
}
