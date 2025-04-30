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
  final filtersTabKey = GlobalKey<filters_tab.FiltersTabState>(); // Use the state's type

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
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.background,
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            const ResultsTab(),
            // Use the key here, associating it with the FiltersTab widget
            filters_tab.FiltersTab(key: filtersTabKey),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        child: TabBar(
          controller: _tabController,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          indicator: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 3,
              ),
            ),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          padding: const EdgeInsets.only(top: 8),
          tabs: const [
            Tab(
              icon: Icon(Icons.list_alt),
              text: 'Results',
            ),
            Tab(
              icon: Icon(Icons.filter_list),
              text: 'Filters',
            ),
          ],
        ),
      ),
      // Conditionally display FAB based on the current tab index
      floatingActionButton: _currentIndex == 1 // Show only on Filters tab (index 1)
          ? FloatingActionButton(
              // Directly access the method on the state via the key
              onPressed: () => filtersTabKey.currentState?.openAddFilterDialog(),
              tooltip: 'Add Filter',
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null, // Don't show FAB on other tabs
    );
  }
} 