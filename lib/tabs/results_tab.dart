import 'package:flutter/material.dart';
import '../models/forwarded_sms_log.dart'; // Use the log model
import '../utils/database_helper.dart'; // Import DB Helper
import 'package:intl/intl.dart';

class ResultsTab extends StatefulWidget {
  const ResultsTab({super.key});

  @override
  State<ResultsTab> createState() => _ResultsTabState();
}

class _ResultsTabState extends State<ResultsTab> {
  List<ForwardedSmsLog> _logs = [];
  bool _isLoading = true;
  final dbHelper = DatabaseHelper();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm');

  @override
  void initState() {
    super.initState();
    _loadLogs();
    // TODO: Add mechanism to refresh logs if app stays open and new logs are added by background service
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final loadedLogs = await dbHelper.getAllForwardedSmsLogs();
      setState(() {
        _logs = loadedLogs;
        _isLoading = false;
      });
    } catch (e) {
       print("Error loading logs: $e");
       setState(() {
        _isLoading = false;
      });
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error loading results: ${e.toString()}')),
        );
    }
  }

  // --- Refresh Action --- (Optional but helpful)
  Future<void> _refreshLogs() async {
     print("Refreshing logs...");
     await _loadLogs();
     if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Results refreshed.'), duration: Duration(seconds: 1)),
        );
     }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildLogList(),
       floatingActionButton: FloatingActionButton(
         mini: true,
         onPressed: _refreshLogs,
         tooltip: 'Refresh Logs',
         child: const Icon(Icons.refresh),
       ), // Add refresh button
    );
  }

  Widget _buildLogList() {
    if (_logs.isEmpty) {
      return const Center(
        child: Text('No forwarded SMS messages logged yet.'),
      );
    }

    return ListView.builder(
      itemCount: _logs.length,
      itemBuilder: (context, index) {
        final log = _logs[index];
        final formattedDate = _dateFormat.format(log.dateTime);

        return ListTile(
          leading: CircleAvatar(
             // Show icon based on status
             backgroundColor: log.status == 'Sent' ? Colors.green : Colors.redAccent,
             child: Icon(
                 log.status == 'Sent' ? Icons.check : Icons.error_outline,
                 color: Colors.white,
                 size: 20,
             ),
           ),
          title: Text('From: ${log.originalSender} -> ${log.forwardedTo}'),
          subtitle: Text(
            log.messageContent,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             crossAxisAlignment: CrossAxisAlignment.end,
             children: [
                Text(formattedDate.split(' ')[0]), // Date part
                Text(formattedDate.split(' ')[1]), // Time part
             ],
          ),
           isThreeLine: true,
           // Optional: Show error on tap?
           onTap: log.status == 'Failed' && log.errorMessage != null
            ? () {
                showDialog(
                   context: context,
                   builder: (_) => AlertDialog(
                      title: const Text('Forwarding Error'),
                      content: Text(log.errorMessage!),
                      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                   ),
                 );
               }
            : null,
        );
      },
    );
  }
} 