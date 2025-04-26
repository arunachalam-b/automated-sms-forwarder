import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
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
    GlobalKey<FormState>(), // Page 0: Recipients
    GlobalKey<FormState>(), // Page 1: Conditions
    GlobalKey<FormState>(), // Page 2: SIM Selection
  ];

  // State variables for the filter
  late String _filterId;
  List<String> _recipients = [];
  List<FilterCondition> _conditions = [];
  String? _selectedSim;

  // --- Controllers & State for Wizard Pages ---
  // Page 0: Recipients
  final _recipientController = TextEditingController();

  // Page 1: Conditions (for the *new* condition entry)
  final _conditionValueController = TextEditingController();
  FilterConditionType _newConditionType = FilterConditionType.sender; // Default
  bool _newConditionCaseSensitive = false; // Default

  // Page 2: SIM Selection (Placeholder for now)
  // String? _selectedSimController; // Example if using a controller

  @override
  void initState() {
    super.initState();
    if (widget.initialFilter != null) {
      // Pre-populate state if editing
      _filterId = widget.initialFilter!.id;
      _recipients = List.from(widget.initialFilter!.recipients);
      // Clone conditions to avoid modifying the original list directly
      _conditions = widget.initialFilter!.conditions
          .map((c) => FilterCondition(
                type: c.type,
                value: c.value,
                caseSensitive: c.caseSensitive,
              ))
          .toList();
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
    _conditionValueController.dispose(); // Dispose new controller
    super.dispose();
  }

  void _nextPage() {
    bool valid = true;
    if (_currentPage == 0) {
        if (_recipients.isEmpty) {
            valid = false;
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please add at least one recipient.')),
            );
        }
    } else if (_currentPage == 1) {
        // Also check conditions page validity before moving to page 2
        if (_conditions.isEmpty) {
            valid = false;
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please add at least one condition.')),
            );
        }
    }

    if (!valid) return;

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
     // Validate page 0 (Recipients)
     if (_recipients.isEmpty) {
         ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please add at least one recipient before submitting.')),
         );
         if (_currentPage != 0) {
             _pageController.jumpToPage(0);
             setState(() { _currentPage = 0; });
         }
         return;
     }
     // Validate page 1 (Conditions)
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
     // TODO: Add validation for SIM selection if needed (page 2)

      final newFilter = Filter(
        id: _filterId,
        recipients: _recipients,
        conditions: _conditions,
        selectedSim: _selectedSim,
      );
      Navigator.of(context).pop(newFilter);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialFilter == null ? 'Add New Filter' : 'Edit Filter'),
      // Make dialog scrollable if content overflows
      scrollable: true,
      content: SizedBox(
        width: double.maxFinite,
        // Use constraints for height instead of fixed height
        height: MediaQuery.of(context).size.height * 0.6, // Example: 60% of screen height
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildRecipientsPage(),
            _buildConditionsPage(),
            _buildSimSelectionPage(),
          ],
        ),
      ),
      actions: <Widget>[
        // Cancel button added
        TextButton(
           child: const Text('Cancel'),
           onPressed: () => Navigator.of(context).pop(), // Close dialog, return null
         ),
        if (_currentPage > 0)
          TextButton(
            child: const Text('Back'),
            onPressed: _previousPage,
          ),
        if (_currentPage < 2)
          ElevatedButton( // Make Next/Submit more prominent
            child: const Text('Next'),
            onPressed: _nextPage,
          )
        else
          ElevatedButton(
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Forward SMS To:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                    validator: (value) {
                      // Basic validation is handled by the add button logic
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: ElevatedButton(
                    onPressed: _addRecipientManual,
                    child: const Text('Add'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Center(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.contact_phone),
                label: const Text('Select from Contacts'),
                onPressed: _selectFromContacts,
              ),
            ),
            const SizedBox(height: 15),
            const Text('Recipients:', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 5),
            if (_recipients.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(' No recipients added yet.', style: TextStyle(fontStyle: FontStyle.italic)),
              )
            else
              Container(
                constraints: const BoxConstraints(maxHeight: 150), // Limit chip area height
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
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
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _addRecipientManual() {
    final number = _recipientController.text.trim();
    _addRecipientToList(number);
    _recipientController.clear();
  }

  void _addRecipientToList(String number) {
     if (number.isNotEmpty) {
      if (!_recipients.contains(number)) {
        setState(() {
          _recipients.add(number);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$number is already added.')),
        );
      }
    } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter or select a valid phone number.')),
        );
    }
  }


  void _selectFromContacts() async {
    if (!await FlutterContacts.requestPermission(readonly: true)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact permission is required to select recipients.')),
        );
      }
      return;
    }

    Contact? contact = await FlutterContacts.openExternalPick();
    if (contact == null) return;

    contact = await FlutterContacts.getContact(contact.id);
    if (contact == null || contact.phones.isEmpty) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Selected contact has no phone numbers.')),
          );
       }
       return;
    }

    final firstNumber = contact.phones.first.number.replaceAll(RegExp(r'\s+|-|\(|\)'), '');
    _addRecipientToList(firstNumber);
  }

  // --- Conditions Page Implementation ---
  Widget _buildConditionsPage() {
    return Form(
      key: _formKeys[1],
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter Conditions (SMS must match ALL):', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            // --- Add New Condition Section ---
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 15),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Add a new condition:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 10),
                    // Condition Type Dropdown
                    DropdownButtonFormField<FilterConditionType>(
                      value: _newConditionType,
                      decoration: const InputDecoration(
                        labelText: 'Condition Type',
                        border: OutlineInputBorder(),
                      ),
                      items: FilterConditionType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          // Capitalize first letter for display
                          child: Text(type.name[0].toUpperCase() + type.name.substring(1)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _newConditionType = value;
                            // Reset case sensitivity if switching away from content
                            if (value != FilterConditionType.content) {
                              _newConditionCaseSensitive = false;
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    // Condition Value Text Field
                    TextFormField(
                      controller: _conditionValueController,
                      decoration: InputDecoration(
                        labelText: _newConditionType == FilterConditionType.sender
                            ? 'Sender Name/Number'
                            : 'Text Content',
                        border: const OutlineInputBorder(),
                        hintText: _newConditionType == FilterConditionType.sender
                            ? 'e.g., BankName or +1...`'
                            : 'e.g., OTP or Urgent'
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a value for the condition';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 5),
                    // Case Sensitive Checkbox (Conditional)
                    if (_newConditionType == FilterConditionType.content)
                      CheckboxListTile(
                        title: const Text('Case Sensitive'),
                        value: _newConditionCaseSensitive,
                        onChanged: (bool? value) {
                          setState(() {
                            _newConditionCaseSensitive = value ?? false;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading, // Checkbox on left
                        contentPadding: EdgeInsets.zero, // Remove default padding
                      ),
                    const SizedBox(height: 10),
                    // Add Condition Button
                    Center(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Add Condition'),
                        onPressed: _addCondition,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- Display Added Conditions Section ---
            const Text('Added Conditions:', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 5),
            if (_conditions.isEmpty)
              const Padding(
                 padding: EdgeInsets.symmetric(vertical: 8.0),
                 child: Text(' No conditions added yet.', style: TextStyle(fontStyle: FontStyle.italic)),
              )
            else
              ListView.builder(
                shrinkWrap: true, // Important inside SingleChildScrollView
                physics: const NeverScrollableScrollPhysics(), // List scrolling managed by parent
                itemCount: _conditions.length,
                itemBuilder: (context, index) {
                  final condition = _conditions[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    child: ListTile(
                      leading: Icon(condition.type == FilterConditionType.sender
                          ? Icons.person_outline
                          : Icons.text_fields),
                      title: Text('${condition.type.name[0].toUpperCase()}${condition.type.name.substring(1)}: ${condition.value}'),
                      subtitle: condition.type == FilterConditionType.content
                          ? Text('Case Sensitive: ${condition.caseSensitive ? 'Yes' : 'No'}')
                          : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        tooltip: 'Remove Condition',
                        onPressed: () => _deleteCondition(index),
                      ),
                      dense: true,
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _addCondition() {
    // Validate the input fields for the new condition
    if (!_formKeys[1].currentState!.validate()) {
      return; // Don't add if validation fails
    }

    final value = _conditionValueController.text.trim();

    final newCondition = FilterCondition(
      type: _newConditionType,
      value: value,
      // Only use the state variable if type is content
      caseSensitive: _newConditionType == FilterConditionType.content
          ? _newConditionCaseSensitive
          : false,
    );

    setState(() {
      _conditions.add(newCondition);
      // Reset input fields for the next condition
      _conditionValueController.clear();
      // Optionally reset type and case sensitivity to defaults
      // _newConditionType = FilterConditionType.sender;
      // _newConditionCaseSensitive = false;
    });
  }

  void _deleteCondition(int index) {
    setState(() {
      _conditions.removeAt(index);
    });
  }


  // --- SIM Selection Page Implementation (Placeholder) ---
  Widget _buildSimSelectionPage() {
    return Form(
      key: _formKeys[2],
      child: SingleChildScrollView(
         padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             const Text('Select SIM Card for Forwarding:', style: TextStyle(fontWeight: FontWeight.bold)),
             const SizedBox(height: 15),
             // TODO: Implement actual SIM selection logic
             // This usually requires a platform-specific plugin (e.g., sim_data_plus or telephony)
             // For now, we'll use dummy radio buttons
             RadioListTile<String>(
                title: const Text('SIM 1 (Dummy)'),
                value: 'SIM 1',
                groupValue: _selectedSim,
                onChanged: (value) => setState(() => _selectedSim = value),
              ),
             RadioListTile<String>(
                title: const Text('SIM 2 (Dummy)'),
                value: 'SIM 2',
                groupValue: _selectedSim,
                onChanged: (value) => setState(() => _selectedSim = value),
              ),
             RadioListTile<String>(
                title: const Text('Ask Every Time (Dummy)'),
                value: "", // Representing no specific SIM selected
                groupValue: _selectedSim,
                onChanged: (value) => setState(() => _selectedSim = value),
              ),
             const SizedBox(height: 20),
             const Center(
                child: Text('(Note: Actual SIM detection requires specific plugins and permissions)',
                  style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                  textAlign: TextAlign.center,
                )
             )
          ],
        ),
      ),
    );
  }

} 