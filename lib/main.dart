import 'dart:io';

import 'package:milk_business/screens/customer_screen.dart';
import 'package:milk_business/screens/daily_milk_screen.dart';
import 'package:milk_business/screens/dashboard_screen.dart';
import 'package:milk_business/screens/monthly_bill_screen.dart';
import 'package:milk_business/screens/vendor_screen.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const MilkBusinessApp());
}

class MilkBusinessApp extends StatelessWidget {
  const MilkBusinessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Milk Business',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green.shade700),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _milkRefreshToken = 0;

  void _refreshMilkScreen() {
    setState(() {
      _milkRefreshToken += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const DashboardScreen(),
      CustomerScreen(onCustomerChanged: _refreshMilkScreen),
      DailyMilkScreen(
        key: ValueKey('daily_milk_$_milkRefreshToken'),
        onCustomerChanged: _refreshMilkScreen,
      ),
      const MonthlyBillScreen(),
      const ExpenseScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(icon: Icon(Icons.people), label: 'Customers'),
          NavigationDestination(icon: Icon(Icons.local_drink), label: 'Milk'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Bill'),
          NavigationDestination(icon: Icon(Icons.money_off), label: 'Expenses'),
        ],
      ),
    );
  }
}
