import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/filter.dart';

class FilterWizard extends StatefulWidget {
  final Filter? initialFilter; // Pass existing filter for editing

  const FilterWizard({super.key, this.initialFilter});

  @override
  State<FilterWizard> createState() => _FilterWizardState();
}

class _FilterWizardState extends State<FilterWizard> {
  final _pageController = PageController();
  int _currentPage = 0;
  final _formKeys = [GlobalKey<FormState>(), GlobalKey<FormState>(), GlobalKey<FormState>()]; // One key per page if needed

  // State variables for the filter being built/edited
  late String _filterId;
  List<String> _recipients = [];
  List<FilterCondition> _conditions = [];
  String? _selectedSim;

  // Controllers for input fields
  final _recipientController = TextEditingController();
  // TODO: Add controllers for condition inputs

  @override
  void initState() {
    super.initState();
    if (widget.initialFilter != null) {
      // Pre-populate state if editing
      _filterId = widget.initialFilter!.id;
      _recipients = List.from(widget.initialFilter!.recipients);
      _conditions = List.from(widget.initialFilter!.conditions);
      _selectedSim = widget.initialFilter!.selectedSim;
    } else {
      // Generate new ID if creating
      _filterId = const Uuid().v4();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _recipientController.dispose();
    // TODO: Dispose condition controllers
    super.dispose();
  }

  void _nextPage() {
    // Optional: Validate current page form before proceeding
    // if (_formKeys[_currentPage].currentState?.validate() ?? false) {
      if (_currentPage < 2) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() {
          _currentPage++;
        });
      }
    // }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentPage--;
      });
    }
  }

  void _submitFilter() {
    // Optional: Validate final page form
    // if (_formKeys[_currentPage].currentState?.validate() ?? false) {
      final newFilter = Filter(
        id: _filterId,
        recipients: _recipients,
        conditions: _conditions,
        selectedSim: _selectedSim,
      );
      Navigator.of(context).pop(newFilter); // Return the created/edited filter
    // }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialFilter == null ? 'Add New Filter' : 'Edit Filter'),
      content: SizedBox(
        width: double.maxFinite, // Use available width
        height: 400, // Adjust height as needed
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(), // Disable swiping
          children: [
            _buildRecipientsPage(),
            _buildConditionsPage(),
            _buildSimSelectionPage(),
          ],
        ),
      ),
      actions: <Widget>[
        if (_currentPage > 0)
          TextButton(
            child: const Text('Back'),
            onPressed: _previousPage,
          ),
        if (_currentPage < 2)
          TextButton(
            child: const Text('Next'),
            onPressed: _nextPage,
          )
        else // Show Submit on the last page
          TextButton(
            child: const Text('Submit'),
            onPressed: _submitFilter,
          ),
      ],
    );
  }

  // Placeholder builders for each page
  Widget _buildRecipientsPage() {
    // TODO: Implement recipients UI (TextFormField, Add button, List/Chips)
    return Form(
      key: _formKeys[0],
      child: const Center(child: Text('Page 1: Recipients')),
    );
  }

  Widget _buildConditionsPage() {
    // TODO: Implement conditions UI (Add button, List of conditions with type/value/case inputs)
     return Form(
      key: _formKeys[1],
      child: const Center(child: Text('Page 2: Conditions')),
    );
  }

  Widget _buildSimSelectionPage() {
    // TODO: Implement SIM selection UI (Dropdown/Radio buttons)
     return Form(
      key: _formKeys[2],
      child: const Center(child: Text('Page 3: SIM Selection')),
    );
  }
} 