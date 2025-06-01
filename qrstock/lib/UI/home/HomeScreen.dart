import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:qrstock/FirebaseController/Firebase_Controller.dart';
import 'package:qrstock/themes/colors.dart';
import 'dart:io';
import 'package:qrstock/UI/login/login.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:qrstock/UI/config/ConfigPage.dart';
import 'package:qrstock/UI/contact/ContactPage.dart';
import 'package:qrstock/UI/products/ProductsPage.dart';
import 'package:qrstock/UI/warehouses/WarehouseSelectionPage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedPage = "Home";

  bool get _isMobile =>
      Platform.isAndroid ||
      Platform.isIOS ||
      MediaQuery.of(context).size.width < 600;

  void _changePage(String page) {
    setState(() {
      _selectedPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backGreen,
      appBar: AppBar(
        leading: const Icon(Icons.qr_code, color: black),
        title: _buildAppBarTitle(),
        actions: _buildAppBarActions(),
        backgroundColor: barGreen,
        titleTextStyle: const TextStyle(
          color: black,
          fontWeight: FontWeight.bold,
          fontSize: 18.0,
        ),
        titleSpacing: -15,
      ),
      body: _getSelectedPage(),
    );
  }

  Widget _buildAppBarTitle() {
    return _isMobile
        ? const Text('QRStock')
        : Row(
          children: [
            const Text('QRStock'),
            const SizedBox(width: 20),
            ..._buildNavButtons(),
            _buildLogoutButton(),
          ],
        );
  }

  List<Widget> _buildNavButtons() {
    return [
      _buildNavButton("Home"),
      _buildNavButton("Products"),
      _buildNavButton("Map"),
      _buildNavButton("Contact"),
      _buildNavButton("Config"),
    ];
  }

  Widget _buildLogoutButton() {
    return TextButton(
      onPressed: () => _logout(context),
      child: Text(
        'Logout',
        style: TextStyle(
          color: _selectedPage == "Logout" ? blue : black,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    if (_isMobile) {
      return [
        PopupMenuButton<String>(
          position: PopupMenuPosition.under,
          onSelected: (value) {
            if (value == 'Logout') {
              _logout(context);
            } else {
              _changePage(value);
            }
          },
          itemBuilder:
              (context) => [
                _buildPopupMenuItem('Home'),
                _buildPopupMenuItem('Products'),
                _buildPopupMenuItem('Map'),
                _buildPopupMenuItem('Contact'),
                _buildPopupMenuItem('Config'),
                const PopupMenuItem(
                  value: 'Logout',
                  child: Text('Logout', style: TextStyle(color: Colors.red)),
                ),
              ],
        ),
      ];
    } else {
      return [];
    }
  }

  PopupMenuItem<String> _buildPopupMenuItem(String value) {
    return PopupMenuItem(
      value: value,
      child: Text(
        value,
        style: TextStyle(
          color: _selectedPage == value ? blue : black,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildNavButton(String name) {
    return TextButton(
      onPressed: () => _changePage(name),
      child: Text(
        name,
        style: TextStyle(
          color: _selectedPage == name ? blue : black,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _getSelectedPage() {
    switch (_selectedPage) {
      case "Home":
        return _buildStockAlertsSection();
      case "Products":
        return const ProductsPage();
      case "Map":
        return const WarehouseSelectionPage();
      case "Contact":
        return const ContactPage();
      case "Config":
        return const ConfigPage();
      default:
        return _buildStockAlertsSection();
    }
  }

  Widget _buildWelcomeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.waving_hand_rounded, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Welcome to your inventory manager, don't forget to check your stock.",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockAlertsSection() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildWelcomeBanner()),
        _buildStickyStockAlertHeader(),
        SliverToBoxAdapter(child: SizedBox(height: 24)),
        _buildExpiryAlertContainer(),
      ],
    );
  }

  Widget _buildStickyStockAlertHeader() {
    return MultiSliver(
      children: [
        SliverPinnedHeader(
          child: Container(
            padding: const EdgeInsets.all(16),
            color: darkGreen,
            child: Row(
              children: const [
                Icon(Icons.inventory, color: red),
                SizedBox(width: 8),
                Text(
                  "Low Stock Alerts",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseController.getStockSettings().asStream(),
            builder: (context, configSnapshot) {
              if (!configSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final config =
                  configSnapshot.data!.data() as Map<String, dynamic>? ?? {};
              final criticalStock = config['criticalStock'];
              final enabled = config['criticalStockEnabled'] ?? true;

              if (!enabled) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Stock alerts are disabled'),
                );
              }

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseController.getLowStockProducts(
                  int.parse(criticalStock),
                ),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('All stock is in order.'),
                    );
                  }
                  return Column(
                    children:
                        snapshot.data!.docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final productId = data['productId'];
                          final warehouseId = data['warehouseId'];

                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseController.getProduct(productId),
                            builder: (context, productSnapshot) {
                              if (!productSnapshot.hasData)
                                return const ListTile(
                                  leading: CircularProgressIndicator(),
                                );

                              final productData =
                                  productSnapshot.data!.data()
                                      as Map<String, dynamic>;
                              final productName = productData['name'];

                              return StreamBuilder<DocumentSnapshot>(
                                stream:
                                    FirebaseController.getWarehouse(
                                      warehouseId,
                                    ).asStream(),
                                builder: (context, warehouseSnapshot) {
                                  if (!warehouseSnapshot.hasData ||
                                      warehouseSnapshot.data?.data() == null) {
                                    return const ListTile(
                                      title: Text(
                                        "Problems finding warehouses",
                                      ),
                                    );
                                  }

                                  final warehouseData =
                                      warehouseSnapshot.data!.data()
                                          as Map<String, dynamic>;
                                  final warehouseName = warehouseData['name'];

                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    title: Text(productName),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text("Quantity: ${data['quantity']}"),
                                        Text(
                                          "Location: $warehouseName (${data['row']} , ${data['col']})",
                                        ),
                                      ],
                                    ),
                                    leading: const Icon(
                                      Icons.warning,
                                      color: Colors.red,
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        }).toList(),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExpiryAlertContainer() {
    return MultiSliver(
      children: [
        SliverPinnedHeader(
          child: Container(
            padding: const EdgeInsets.all(16),
            color: darkGreen,
            child: Row(
              children: const [
                Icon(Icons.event_note, color: buttonColor),
                SizedBox(width: 8),
                Text(
                  "Products Near Expiration",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseController.getStockSettings().asStream(),
            builder: (context, configSnapshot) {
              if (!configSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final config =
                  configSnapshot.data!.data() as Map<String, dynamic>? ?? {};
              final bool _isExpirationDateEnabled =
                  config['expirationDateEnabled'];
              final String? setting = config['expirationDate'];
              final int days = _daysFromSetting(setting);
              final DateTime thresholdDate = DateTime.now().subtract(
                Duration(days: days),
              );

              if (!_isExpirationDateEnabled) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Near Expiration alerts are disabled'),
                );
              }

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseController.getExpiredProducts(thresholdDate),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No products nearing expiration.'),
                    );
                  }

                  return Column(
                    children:
                        snapshot.data!.docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final expiry =
                              (data['updatedAt'] as Timestamp).toDate();

                          return FutureBuilder(
                            future: Future.wait([
                              FirebaseController.getProduct(data['productId']),
                              FirebaseController.getWarehouse(
                                data['warehouseId'],
                              ),
                            ]),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const ListTile(
                                  leading: CircularProgressIndicator(),
                                );
                              }

                              if (!snapshot.hasData) {
                                return const ListTile(
                                  title: Text('Error loading data'),
                                );
                              }

                              final results = snapshot.data!;
                              final productData =
                                  results[0].data() as Map<String, dynamic>? ??
                                  {};
                              final warehouseData =
                                  results[1].data() as Map<String, dynamic>? ??
                                  {};

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                title: Text(
                                  productData['name'] ?? 'Unknown Product',
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Quantity: ${data['quantity']}"),
                                    Text(
                                      "Last Update: ${DateFormat('MMM dd, yyyy').format(expiry)}",
                                    ),
                                    Text(
                                      "Location: ${warehouseData['name'] ?? 'Unknown Warehouse'} (${data['row']}, ${data['col']})",
                                    ),
                                  ],
                                ),
                                leading: const Icon(
                                  Icons.schedule,
                                  color: buttonColor,
                                ),
                              );
                            },
                          );
                        }).toList(),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Logout"),
            content: const Text("Are you sure you want to leave?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  "Logout",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed ?? false) {
      try {
        await FirebaseAuth.instance.signOut();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: ${e.toString()}')),
        );
      }
    }
  }
}

int _daysFromSetting(String? setting) {
  switch (setting) {
    case '1 week':
      return 7;
    case '2 weeks':
      return 14;
    case '3 weeks':
      return 21;
    case '1 month':
      return 30;
    case '3 months':
      return 90;
    default:
      return 30;
  }
}
