import 'package:flutter/material.dart';
import '../tabs/filters_tab.dart' as filters_tab;
import '../tabs/results_tab.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0; // To track the current tab index

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Add listener to update index when tab changes
    _tabController.addListener(() {
      setState(() {
        _currentIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(() {}); // Clean up listener
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto SMS Forwarder'),
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            // Optional: If you need to do something specific on tap besides changing the view
            setState(() {
              _currentIndex = index;
            });
          },
          tabs: const [
            Tab(icon: Icon(Icons.list_alt), text: 'Results'), // Added icons
            Tab(icon: Icon(Icons.filter_list), text: 'Filters'), // Added icons
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const ResultsTab(),
          // Use the key here
          filters_tab.FiltersTab(key: filters_tab.filtersTabKey),
        ],
      ),
      // Conditionally display FAB based on the current tab index
      floatingActionButton: _currentIndex == 1 // Show only on Filters tab (index 1)
          ? FloatingActionButton(
              onPressed: filters_tab.triggerAddFilterDialog, // Call the exposed function
              tooltip: 'Add Filter',
              child: const Icon(Icons.add),
            )
          : null, // Don't show FAB on other tabs
    );
  }
} 