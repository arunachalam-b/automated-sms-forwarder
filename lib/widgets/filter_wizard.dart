import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
// Remove sim_data_plus imports
// import 'package:sim_data_plus/sim_data.dart';
// import 'package:sim_data_plus/sim_model.dart';
// Remove permission_handler if only used for SIM
// import 'package:permission_handler/permission_handler.dart';
// Keep telephony for later use, but remove instance here if not used in wizard
// import 'package:another_telephony/telephony.dart';

import '../models/filter.dart' as custom_filter;

class FilterWizard extends StatefulWidget {
  final custom_filter.Filter? initialFilter;

  const FilterWizard({super.key, this.initialFilter});

  @override
  State<FilterWizard> createState() => _FilterWizardState();
}

class _FilterWizardState extends State<FilterWizard> {
  // Reduce page count to 2
  final _pageController = PageController();
  int _currentPage = 0;
  final _formKeys = [
    GlobalKey<FormState>(), // Page 0: Recipients
    GlobalKey<FormState>(), // Page 1: Conditions
  ];

  // --- State variables for the filter ---
  late String _filterId;
  List<String> _recipients = [];
  List<custom_filter.FilterCondition> _conditions = [];
  // Removed _selectedSim state variable

  // --- Controllers & State for Wizard Pages ---
  final _recipientController = TextEditingController();
  final _conditionValueController = TextEditingController();
  custom_filter.FilterConditionType _newConditionType =
      custom_filter.FilterConditionType.sender;
  bool _newConditionCaseSensitive = false;

  // Removed SIM detection state variables
  // final Telephony _telephony = Telephony.instance;
  // bool _isLoadingSimData = true;
  // bool _phoneStatePermissionGranted = false;
  // String _simError = '';
  // int _simCount = 0;
  // List<SimState?> _simStates = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialFilter != null) {
      _filterId = widget.initialFilter!.id;
      _recipients = List.from(widget.initialFilter!.recipients);
      _conditions = widget.initialFilter!.conditions
          .map((c) => custom_filter.FilterCondition(
                type: c.type,
                value: c.value,
                caseSensitive: c.caseSensitive,
              ))
          .toList();
      // No SIM state to initialize
    } else {
      _filterId = const Uuid().v4();
    }
    // Removed call to _loadSimData()
  }

  // Removed _loadSimData function
  // Future<void> _loadSimData() async { ... }

  // Removed _getSimStateSuffix helper
  // String _getSimStateSuffix(int index) { ... }

  @override
  void dispose() {
    _pageController.dispose();
    _recipientController.dispose();
    _conditionValueController.dispose();
    super.dispose();
  }

  // --- Navigation and Submission Logic (Updated for 2 pages) ---
  void _nextPage() {
    bool valid = true;
    // Only validate page 0 (Recipients) when moving from 0 to 1
    if (_currentPage == 0) {
      if (_recipients.isEmpty) {
        valid = false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one recipient.')),
        );
      }
    }

    if (!valid) return;

    // Check if we are not on the last page (which is now page 1)
    if (_currentPage < 1) {
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
        const SnackBar(content: Text('Please add at least one recipient.')),
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
        const SnackBar(content: Text('Please add at least one condition.')),
      );
       if (_currentPage != 1) {
          _pageController.jumpToPage(1);
          setState(() { _currentPage = 1; });
      }
      return;
    }

    // Create filter without SIM info
    final newFilter = custom_filter.Filter(
      id: _filterId,
      recipients: _recipients,
      conditions: _conditions,
      // selectedSim removed
    );
    Navigator.of(context).pop(newFilter);
  }

  // --- Build Method (Updated for 2 pages) ---
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initialFilter == null ? 'Add New Filter' : 'Edit Filter',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      scrollable: true,
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6,
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildRecipientsPage(),
            _buildConditionsPage(),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        if (_currentPage > 0)
          TextButton(
            child: const Text('Back'),
            onPressed: _previousPage,
          ),
        if (_currentPage < 1)
          ElevatedButton(
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

  // --- Page Builders ---

  Widget _buildRecipientsPage() {
    return Form(
      key: _formKeys[0],
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Forward SMS To:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _recipientController,
              decoration: InputDecoration(
                labelText: 'Enter Phone Number',
                hintText: '+1234567890',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addRecipientManual,
                  tooltip: 'Add Recipient',
                ),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            Center(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.contact_phone),
                label: const Text('Select from Contacts'),
                onPressed: _selectRecipientFromContacts,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Recipients:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            if (_recipients.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'No recipients added yet',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: _recipients.map((recipient) {
                    return Chip(
                      label: Text(recipient),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        setState(() {
                          _recipients.remove(recipient);
                        });
                      },
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionsPage() {
    return Form(
      key: _formKeys[1],
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add a new condition:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<custom_filter.FilterConditionType>(
                    value: _newConditionType,
                    decoration: InputDecoration(
                      labelText: 'Condition Type',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: custom_filter.FilterConditionType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.name[0].toUpperCase() + type.name.substring(1)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _newConditionType = value;
                          if (value != custom_filter.FilterConditionType.content) {
                            _newConditionCaseSensitive = false;
                          }
                          _conditionValueController.clear();
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _conditionValueController,
                    decoration: InputDecoration(
                      labelText: _newConditionType == custom_filter.FilterConditionType.sender
                          ? 'Sender Name/Number'
                          : 'Text Content',
                      hintText: _newConditionType == custom_filter.FilterConditionType.sender
                          ? 'e.g., BankName or +1...'
                          : 'e.g., OTP or Urgent',
                      helperText: _newConditionType == custom_filter.FilterConditionType.content && !_newConditionCaseSensitive
                          ? 'Content checks are case insensitive'
                          : null,
                      helperStyle: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: _newConditionType == custom_filter.FilterConditionType.sender
                          ? IconButton(
                              icon: const Icon(Icons.contact_phone_outlined),
                              tooltip: 'Select Sender from Contacts',
                              onPressed: _selectSenderFromContacts,
                            )
                          : null,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a value for the condition';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
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
            const SizedBox(height: 24),
            const Text(
              'Added Conditions:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            if (_conditions.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'No conditions added yet',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: _conditions.map((condition) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          condition.type == custom_filter.FilterConditionType.sender
                              ? Icons.person_outline
                              : Icons.text_fields,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(
                          '${condition.type.name[0].toUpperCase()}${condition.type.name.substring(1)}: ${condition.value}',
                        ),
                        subtitle: condition.type == custom_filter.FilterConditionType.content
                            ? Text('Case Sensitive: ${condition.caseSensitive ? 'Yes' : 'No'}')
                            : null,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _deleteCondition(_conditions.indexOf(condition)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- Helper Methods --- (Keep recipient/condition helpers)

  void _addRecipientManual() {
    final number = _recipientController.text.trim();
    _addRecipientToList(number);
    _recipientController.clear();
  }

  void _addRecipientToList(String number) {
    if (number.isNotEmpty) {
      if (!number.startsWith('+') && !RegExp(r'^[0-9]+$').hasMatch(number)){
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid phone number (e.g., +123... or 123...).')),
        );
        return;
      }

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

  Future<String?> _pickContactPhoneNumber() async {
    if (!await FlutterContacts.requestPermission(readonly: true)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact permission is required.')),
        );
      }
      return null;
    }

    Contact? contact = await FlutterContacts.openExternalPick();
    if (contact == null) return null;

    contact = await FlutterContacts.getContact(contact.id);
    if (contact == null || contact.phones.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Selected contact has no phone numbers.')),
        );
      }
      return null;
    }
    return contact.phones.first.number.replaceAll(RegExp(r'\s+|-|\(|\)'), '');
  }

  void _selectRecipientFromContacts() async {
    final String? number = await _pickContactPhoneNumber();
    if (number != null) {
        _addRecipientToList(number);
    }
  }

  void _selectSenderFromContacts() async {
    final String? number = await _pickContactPhoneNumber();
    if (number != null) {
        _conditionValueController.text = number;
    }
  }

  void _addCondition() {
    if (!_formKeys[1].currentState!.validate()) {
      return;
    }
    final value = _conditionValueController.text.trim();
    final newCondition = custom_filter.FilterCondition(
      type: _newConditionType,
      value: value,
      caseSensitive: _newConditionType == custom_filter.FilterConditionType.content
          ? _newConditionCaseSensitive
          : false,
    );
    setState(() {
      _conditions.add(newCondition);
      _conditionValueController.clear();
    });
  }

  void _deleteCondition(int index) {
    setState(() {
      _conditions.removeAt(index);
    });
  }
} 