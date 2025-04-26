import 'package:flutter/material.dart';
import '../models/filter.dart'; // Adjust path if necessary
import '../widgets/filter_wizard.dart'; // Import the wizard

class FiltersTab extends StatefulWidget {
  const FiltersTab({super.key});

  @override
  State<FiltersTab> createState() => FiltersTabState();
}

class FiltersTabState extends State<FiltersTab> {
  // In-memory list of filters for now
  final List<Filter> _filters = [];

  void _addFilter(Filter filter) {
    setState(() {
      _filters.add(filter);
    });
    // TODO: Persist filter
  }

  void _editFilter(Filter oldFilter, Filter newFilter) {
    setState(() {
      final index = _filters.indexWhere((f) => f.id == oldFilter.id);
      if (index != -1) {
        _filters[index] = newFilter;
      }
    });
    // TODO: Persist changes
  }

  void _deleteFilter(String filterId) {
    setState(() {
      _filters.removeWhere((f) => f.id == filterId);
    });
    // TODO: Persist deletion
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
    final editedFilter = await showDialog<Filter>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return FilterWizard(initialFilter: filter);
      },
    );
    if (editedFilter != null) {
      _editFilter(filter, editedFilter);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildFilterList(),
      // The FAB is moved to HomePage to be displayed conditionally
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
                _deleteFilter(filterId);
                Navigator.of(context).pop();
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