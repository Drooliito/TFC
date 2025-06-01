import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qrstock/FirebaseController/Firebase_Controller.dart';
import 'WarehouseGrid.dart';
import '../../themes/colors.dart';

class CreateWarehousePage extends StatefulWidget {
  const CreateWarehousePage({super.key});

  @override
  State<CreateWarehousePage> createState() => _CreateWarehousePageState();
}

class _CreateWarehousePageState extends State<CreateWarehousePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _rowsController = TextEditingController(text: '5');
  final _colsController = TextEditingController(text: '5');
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _rowsController.dispose();
    _colsController.dispose();
    super.dispose();
  }

  Future<void> _createWarehouse() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final checkWarehouseName = await FirebaseController.checkWarehouseExists(
        name,
      );

      if (checkWarehouseName.docs.isNotEmpty) {
        _showErrorSnackbar('A warehouse with this name already exists');
        return;
      }

      final warehouseData = await _generateWarehouseData();
      final docRef = await FirebaseController.createWarehouse(warehouseData);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => WarehouseGrid(warehouseId: docRef.id),
        ),
      );
    } on FirebaseException catch (e) {
      _showErrorSnackbar('Firebase Error: ${e.message}');
    } catch (e) {
      _showErrorSnackbar('Unexpected Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>> _generateWarehouseData() async {
    final rows = int.parse(_rowsController.text);
    final cols = int.parse(_colsController.text);

    return {
      'name': _nameController.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'grid': {
        'rows': rows,
        'cols': cols,
        'cells': _generateEmptyGrid(rows, cols),
      },
      'stats': {
        'totalCells': rows * cols,
        'occupiedCells': 0,
        'lastModified': FieldValue.serverTimestamp(),
      },
    };
  }

  List<Map<String, dynamic>> _generateEmptyGrid(int rows, int cols) {
    return List.generate(
      rows * cols,
      (index) => {'row': index ~/ cols, 'col': index % cols},
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Warehouse'),
        elevation: 2,
        backgroundColor: barGreen,
      ),
      backgroundColor: backGreen,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildNameField(),
              const SizedBox(height: 24),
              _buildGridSizeFields(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Warehouse Name',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.warehouse),
        filled: true,
        fillColor: white,
      ),
      validator: (value) => value!.trim().isEmpty ? 'Required field' : null,
    );
  }

  Widget _buildGridSizeFields() {
    return Row(
      children: [
        Expanded(
          child: _buildNumberField(
            controller: _rowsController,
            label: 'Rows',
            icon: Icons.table_rows,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildNumberField(
            controller: _colsController,
            label: 'Columns',
            icon: Icons.table_chart,
          ),
        ),
      ],
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: white,
      ),
      keyboardType: TextInputType.number,
      validator: _validateNumber,
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton.icon(
      icon:
          _isLoading
              ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: white),
              )
              : const Icon(Icons.add_circle_outline, color: white),
      label: Text(
        _isLoading ? 'Creating...' : 'Create Warehouse',
        style: const TextStyle(fontSize: 16, color: white),
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: buttonColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: _isLoading ? null : _createWarehouse,
    );
  }

  String? _validateNumber(String? value) {
    final number = int.tryParse(value ?? '');
    if (number == null || number < 1 || number > 25) {
      return 'Enter number 1-25';
    }
    return null;
  }
}
