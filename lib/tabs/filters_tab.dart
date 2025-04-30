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
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading filters: ${e.toString()}')),
        );
      }
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
    final result = await showDialog<Filter>(
      context: context,
      builder: (BuildContext context) => const FilterWizard(),
    );

    if (result != null) {
      try {
        await dbHelper.insertFilter(result);
        await _loadFilters();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Filter added successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding filter: ${e.toString()}')),
          );
        }
      }
    }
  }

  Future<void> openEditFilterDialog(Filter filter) async {
    final result = await showDialog<Filter>(
      context: context,
      builder: (BuildContext context) => FilterWizard(initialFilter: filter),
    );

    if (result != null) {
      try {
        await dbHelper.updateFilter(result);
        await _loadFilters();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Filter updated successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating filter: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildFilterList(),
      ),
    );
  }

  Widget _buildFilterList() {
    if (_filters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_list_outlined,
              size: 64,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'No filters added yet.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: openAddFilterDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Filter'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _filters.length,
      itemBuilder: (context, index) {
        final filter = _filters[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => openEditFilterDialog(filter),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        ),
                        child: Icon(
                          Icons.filter_list,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Filter ${index + 1}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${filter.recipients.length} recipient(s)',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: Colors.red[300],
                        onPressed: () => _confirmDeleteFilter(filter.id),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Recipients:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: filter.recipients.map((recipient) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          recipient,
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Conditions:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: filter.conditions.map((condition) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              condition.type == FilterConditionType.sender
                                  ? Icons.person_outline
                                  : Icons.message_outlined,
                              size: 16,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${condition.type.name}: ${condition.value}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
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
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteFilter(filterId);
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