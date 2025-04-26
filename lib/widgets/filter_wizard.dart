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
  final _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>()
  ];

  // State variables
  late String _filterId;
  List<String> _recipients = [];
  List<FilterCondition> _conditions = [];
  String? _selectedSim;

  // Controllers
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
    // Validate recipients page before proceeding
    if (_currentPage == 0) {
        if (_recipients.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please add at least one recipient.')),
            );
            return; // Don't proceed if no recipients
        }
    } 
    // Add validation for other pages later if needed
    // else if (_currentPage == 1) { ... }

    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentPage++;
      });
    }
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
     if (_recipients.isEmpty) {
         ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please add at least one recipient before submitting.')),
         );
         // Optionally navigate back to the first page
         if (_currentPage != 0) {
             _pageController.jumpToPage(0);
             setState(() { _currentPage = 0; });
         }
         return;
     }
     if (_conditions.isEmpty) {
         ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please add at least one condition before submitting.')),
         );
         if (_currentPage != 1) {
             _pageController.jumpToPage(1);
             setState(() { _currentPage = 1; });
         }
         return;
     }
      // Add validation for SIM selection if needed

      final newFilter = Filter(
        id: _filterId,
        recipients: _recipients,
        conditions: _conditions,
        selectedSim: _selectedSim,
      );
      Navigator.of(context).pop(newFilter); // Return the created/edited filter
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

  Widget _buildRecipientsPage() {
    return Form(
      key: _formKeys[0],
      child: SingleChildScrollView(
        // Ensure content scrolls if it overflows
        child: Column(
          mainAxisSize: MainAxisSize.min, // Take minimum vertical space
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Forward SMS To:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            // --- Recipient Input Row ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start, // Align items top
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _recipientController,
                    decoration: const InputDecoration(
                      labelText: 'Enter Phone Number',
                      border: OutlineInputBorder(),
                      hintText: '+1234567890',
                    ),
                    keyboardType: TextInputType.phone,
                    // Basic validation: not empty
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        // No error shown directly, button handles logic
                        return null; // Returning null means valid for the field itself
                      }
                      // TODO: Add more robust phone validation later
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0), // Align button slightly
                  child: ElevatedButton(
                    onPressed: _addRecipient,
                    child: const Text('Add'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // --- Select from Contacts Button ---
            Center(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.contact_phone),
                label: const Text('Select from Contacts'),
                onPressed: _selectFromContacts, // Placeholder action
              ),
            ),
            const SizedBox(height: 15),
            // --- Display Added Recipients ---
            const Text('Recipients:', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 5),
            if (_recipients.isEmpty)
              const Text(' No recipients added yet.')
            else
              Wrap(
                spacing: 8.0, // Horizontal space between chips
                runSpacing: 4.0, // Vertical space between lines
                children: _recipients.map((recipient) {
                  return Chip(
                    label: Text(recipient),
                    onDeleted: () {
                      setState(() {
                        _recipients.remove(recipient);
                      });
                    },
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  void _addRecipient() {
    final number = _recipientController.text.trim();
    if (number.isNotEmpty) {
      // Basic check to prevent duplicates
      if (!_recipients.contains(number)) {
        setState(() {
          _recipients.add(number);
        });
        _recipientController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$number is already added.')),
        );
      }
    } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a phone number to add.')),
        );
    }
  }

  void _selectFromContacts() {
    // TODO: Implement contact selection using a plugin
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contact selection not yet implemented.')),
    );
  }

  Widget _buildConditionsPage() {
    // TODO: Implement conditions UI
     return Form(
      key: _formKeys[1],
      child: const Center(child: Text('Page 2: Conditions - Placeholder')),
    );
  }

  Widget _buildSimSelectionPage() {
    // TODO: Implement SIM selection UI
     return Form(
      key: _formKeys[2],
      child: const Center(child: Text('Page 3: SIM Selection - Placeholder')),
    );
  }
} 