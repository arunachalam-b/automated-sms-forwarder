import 'package:flutter/material.dart';
import '../models/forwarded_sms.dart'; // Adjust path if necessary
import 'package:intl/intl.dart'; // For date formatting

class ResultsTab extends StatefulWidget {
  const ResultsTab({super.key});

  @override
  State<ResultsTab> createState() => _ResultsTabState();
}

class _ResultsTabState extends State<ResultsTab> {
  // Dummy data
  final List<ForwardedSms> _forwardedSmsList = [
    ForwardedSms(
      contactName: 'Alice',
      forwardedTo: '+1234567890',
      messageContent: 'Meeting at 5 PM today.',
      dateTime: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    ForwardedSms(
      contactName: 'Bob',
      forwardedTo: '+0987654321',
      messageContent: 'Can you pick up groceries?',
      dateTime: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    ForwardedSms(
      contactName: 'Charlie',
      forwardedTo: '+1122334455',
      messageContent: 'Project update: Looks good!',
      dateTime: DateTime.now().subtract(const Duration(days: 1)),
    ),
    ForwardedSms(
      contactName: 'David (Unknown Number)',
      forwardedTo: '+5566778899',
      messageContent: 'Your verification code is 123456',
      dateTime: DateTime.now().subtract(const Duration(days: 2)),
    ),
    ForwardedSms(
      contactName: 'Eve',
      forwardedTo: '+9988776655',
      messageContent: 'Happy Birthday! 🎉',
      dateTime: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (_forwardedSmsList.isEmpty) {
      return const Center(
        child: Text('No forwarded SMS messages yet.'),
      );
    }

    return ListView.builder(
      itemCount: _forwardedSmsList.length,
      itemBuilder: (context, index) {
        final item = _forwardedSmsList[index];
        final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(item.dateTime);

        return ListTile(
          leading: CircleAvatar(child: Text(item.contactName[0])), // First letter
          title: Text('From: ${item.contactName}'),
          subtitle: Text(
            'Forwarded To: ${item.forwardedTo}\n'
            '${item.messageContent}',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(formattedDate),
          isThreeLine: true, // Allows more space for subtitle
        );
      },
    );
  }
} 