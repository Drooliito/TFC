import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../FirebaseController/Firebase_Controller.dart';
import 'package:qrstock/themes/colors.dart';

import 'CreateWarehousePage.dart';
import 'WarehouseGrid.dart';

class WarehouseSelectionPage extends StatelessWidget {
  const WarehouseSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: backGreen,

        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseController.getWarehousesStream(),
          builder: (ctx, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final warehouses = snapshot.data?.docs ?? [];

            if (warehouses.isEmpty) {
              return _buildCreateFirstWarehouseButton(context);
            }

            return ListView.builder(
              itemCount: warehouses.length,
              itemBuilder: (ctx, index) {
                final warehouse = warehouses[index];
                return Container(
                  margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                    color: darkGreen,
                  ),
                  child: ListTile(
                    title: Text(
                      warehouse['name'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: black,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: red),
                      onPressed:
                          () => _confirmDeleteWarehouse(context, warehouse.id),
                    ),
                    onTap:
                        () => _navigateToWarehouseGrid(context, warehouse.id),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: buttonColor,
        child: const Icon(Icons.add, color: white),
        onPressed: () => _navigateToCreatePage(context),
      ),
    );
  }

  Widget _buildCreateFirstWarehouseButton(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.warehouse),
          const Text("No warehouses found", style: TextStyle(fontSize: 18)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
            icon: const Icon(Icons.warehouse, color: white),
            label: const Text("Create First Warehouse"),
            onPressed: () => _navigateToCreatePage(context),
          ),
        ],
      ),
    );
  }

  void _navigateToCreatePage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => const CreateWarehousePage()),
    );
  }

  void _navigateToWarehouseGrid(BuildContext context, String warehouseId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (ctx) => Scaffold(body: WarehouseGrid(warehouseId: warehouseId)),
      ),
    );
  }

  Future<void> _deleteWarehouse(
    BuildContext context,
    String warehouseId,
  ) async {
    try {
      await FirebaseController.deleteWarehouse(warehouseId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Warehouse deleted successfully')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting warehouse: $error')),
      );
    }
  }

  void _confirmDeleteWarehouse(BuildContext context, String warehouseId) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Confirm Delete'),
            content: const Text(
              'Are you sure you want to delete this warehouse?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _deleteWarehouse(context, warehouseId);
                },
                child: const Text('Delete', style: TextStyle(color: red)),
              ),
            ],
          ),
    );
  }
}
