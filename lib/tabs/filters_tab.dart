import 'package:flutter/material.dart';
import '../models/filter.dart'; // Adjust path if necessary
import '../widgets/filter_wizard.dart'; // Import the wizard
import '../utils/database_helper.dart'; // Import DatabaseHelper

class FiltersTab extends StatefulWidget {
  const FiltersTab({super.key});

  @override
  State<FiltersTab> createState() => FiltersTabState();
}

class FiltersTabState extends State<FiltersTab> {
  List<Filter> _filters = []; // Start with empty list
  bool _isLoading = true; // Add loading state
  final dbHelper = DatabaseHelper(); // Instance of the helper

  @override
  void initState() {
    super.initState();
    _loadFilters(); // Load filters when the widget initializes
  }

  Future<void> _loadFilters() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final loadedFilters = await dbHelper.getAllFilters();
      setState(() {
        _filters = loadedFilters;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading filters: $e");
      setState(() {
        _isLoading = false;
        // Optionally show an error message to the user
      });
       ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error loading filters: ${e.toString()}')),
        );
    }
  }

  // Update state and database on add
  void _addFilter(Filter filter) async {
    try {
      await dbHelper.insertFilter(filter);
      setState(() {
        _filters.add(filter);
      });
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Filter added successfully.'), duration: Duration(seconds: 1)),
      );
    } catch (e) {
        print("Error adding filter: $e");
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error saving filter: ${e.toString()}')),
        );
    }
  }

  // Update state and database on edit
  void _editFilter(Filter oldFilter, Filter newFilter) async {
     try {
      await dbHelper.updateFilter(newFilter);
      setState(() {
        final index = _filters.indexWhere((f) => f.id == oldFilter.id);
        if (index != -1) {
          _filters[index] = newFilter;
        }
      });
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Filter updated successfully.'), duration: Duration(seconds: 1)),
      );
    } catch (e) {
        print("Error updating filter: $e");
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error updating filter: ${e.toString()}')),
        );
    }
  }

  // Update state and database on delete
  void _deleteFilter(String filterId) async {
    try {
      await dbHelper.deleteFilter(filterId);
      setState(() {
        _filters.removeWhere((f) => f.id == filterId);
      });
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Filter deleted.'), duration: Duration(seconds: 1)),
      );
    } catch (e) {
        print("Error deleting filter: $e");
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error deleting filter: ${e.toString()}')),
        );
    }
  }

  Future<void> openAddFilterDialog() async {
    final newFilter = await showDialog<Filter>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const FilterWizard();
      },
    );
    if (newFilter != null) {
      _addFilter(newFilter);
    }
  }

  Future<void> openEditFilterDialog(Filter filter) async {
    // Pass a clone to the wizard to avoid modifying the original in case of cancel
    final filterClone = Filter(
      id: filter.id,
      recipients: List.from(filter.recipients),
      conditions: filter.conditions.map((c) => FilterCondition(
          type: c.type,
          value: c.value,
          caseSensitive: c.caseSensitive
        )).toList(),
    );

    final editedFilter = await showDialog<Filter>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return FilterWizard(initialFilter: filterClone);
      },
    );
    if (editedFilter != null) {
      _editFilter(filter, editedFilter); // Pass original filter for finding index
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Show loading indicator or the list
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildFilterList(),
    );
  }

  Widget _buildFilterList() {
    if (_filters.isEmpty) {
      return const Center(
        child: Text('No filters created yet. Tap the + button to add one.'),
      );
    }

    return ListView.builder(
      itemCount: _filters.length,
      itemBuilder: (context, index) {
        final filter = _filters[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: ListTile(
            title: Text('Forward to: ${filter.recipients.join(", ")}'),
            subtitle: Text('Conditions: ${filter.conditions.length}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => openEditFilterDialog(filter),
                  tooltip: 'Edit Filter',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDeleteFilter(filter.id),
                  tooltip: 'Delete Filter',
                ),
              ],
            ),
            onTap: () => openEditFilterDialog(filter),
          ),
        );
      },
    );
  }

  void _confirmDeleteFilter(String filterId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this filter?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog first
                _deleteFilter(filterId); // Then call the delete method
              },
            ),
          ],
        );
      },
    );
  }
}

// Remove the triggerAddFilterDialog function as it's not needed anymore
// The FAB directly calls the instance method via the GlobalKey approach.
// GlobalKey<_FiltersTabState> filtersTabKey = GlobalKey<_FiltersTabState>();

// void triggerAddFilterDialog() {
//   filtersTabKey.currentState?._openAddFilterDialog();
// } 