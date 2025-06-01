import 'package:flutter/material.dart';
import '../../FirebaseController/Firebase_Controller.dart';
import '../../themes/colors.dart';

class ConfigPage extends StatefulWidget {
  const ConfigPage({super.key});

  @override
  _ConfigPageState createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _criticalStockController =
      TextEditingController();
  final List<String> _expirationDateOptions = [
    '1 week',
    '2 weeks',
    '3 weeks',
    '1 month',
    '3 months',
  ];
  String? _selectedExpirationDateOption;
  bool _isLoading = true;
  bool _isCriticalStockEnabled = true;
  bool _isExpirationDateEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  Future<void> _loadCurrentConfig() async {
    try {
      final doc = await FirebaseController.getStockSettings();
      if (doc.exists && doc.data() != null) {
        setState(() {
          final criticalStock = doc['criticalStock'] ?? 5;
          _criticalStockController.text = criticalStock.toString();
          _isCriticalStockEnabled = doc['criticalStockEnabled'] ?? true;
          _isExpirationDateEnabled = doc['expirationDateEnabled'] ?? true;
          _selectedExpirationDateOption = doc['expirationDate'] ?? '1 month';
          _isLoading = false;
        });
      } else {
        setState(() {
          _selectedExpirationDateOption = '1 month';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Future<void> _saveConfig() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseController.updateStockSettings({
          'criticalStock': _criticalStockController.text,
          'criticalStockEnabled': _isCriticalStockEnabled,
          'expirationDate': _selectedExpirationDateOption,
          'expirationDateEnabled': _isExpirationDateEnabled,
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Configuration updated')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error to save: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: backGreen,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: backGreen,
      body: Column(
        children: [
          const SizedBox(height: 20),
          Expanded(
            child: Center(
              child: Container(
                width: 600,
                height: 315,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color.fromRGBO(178, 229, 178, 1),
                  ),
                  borderRadius: BorderRadius.circular(10),
                  color: darkGreen,
                ),
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'CONFIG',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: blue,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _criticalStockController,
                              enabled: _isCriticalStockEnabled,
                              decoration: const InputDecoration(
                                filled: true,
                                fillColor: white,
                                labelText: 'Critical Stock',
                                hintText: 'When stock is less than this number',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.warning_rounded),
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 10,
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (!_isCriticalStockEnabled) return null;
                                if (value == null || value.isEmpty)
                                  return 'Insert value';
                                final num = int.tryParse(value);
                                if (num == null || num <= 0)
                                  return 'Must be positive number';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 1),
                          Padding(
                            padding: const EdgeInsets.only(left: 6.0, top: 4.0),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              child: Transform.scale(
                                scale: 0.8,
                                child: Switch(
                                  value: _isCriticalStockEnabled,
                                  onChanged:
                                      (value) => setState(
                                        () => _isCriticalStockEnabled = value,
                                      ),
                                  activeColor: blue,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedExpirationDateOption,
                              isExpanded: true,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: white,
                                labelText: 'Expiration Date',
                                hintText: 'When Date is less than this number',
                                border: const OutlineInputBorder(),
                                prefixIcon: Icon(
                                  Icons.warning_rounded,
                                  color:
                                      _isExpirationDateEnabled
                                          ? null
                                          : Colors.grey[500],
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 10,
                                ),
                              ),
                              items:
                                  _expirationDateOptions.map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                              onChanged:
                                  _isExpirationDateEnabled
                                      ? (String? newValue) {
                                        setState(() {
                                          _selectedExpirationDateOption =
                                              newValue;
                                        });
                                      }
                                      : null,
                              validator: (value) {
                                if (!_isExpirationDateEnabled) return null;
                                if (value == null || value.isEmpty) {
                                  return 'Please select an option';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 1),
                          Padding(
                            padding: const EdgeInsets.only(left: 6.0, top: 4.0),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              child: Transform.scale(
                                scale: 0.8,
                                child: Switch(
                                  value: _isExpirationDateEnabled,
                                  onChanged:
                                      (value) => setState(
                                        () => _isExpirationDateEnabled = value,
                                      ),
                                  activeColor: blue,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _saveConfig,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          foregroundColor: white,
                          minimumSize: const Size(30, 50),
                        ),
                        child: const Text("SAVE CONFIGURATION"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
