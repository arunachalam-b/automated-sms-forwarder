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
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildLogList(),
      ),
       floatingActionButton: FloatingActionButton(
         mini: true,
         onPressed: _refreshLogs,
         tooltip: 'Refresh Logs',
         backgroundColor: Theme.of(context).colorScheme.primary,
         child: const Icon(Icons.refresh, color: Colors.white),
       ), // Add refresh button
    );
  }

  Widget _buildLogList() {
    if (_logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'No forwarded SMS messages logged yet.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _logs.length,
      itemBuilder: (context, index) {
        final log = _logs[index];
        final formattedDate = _dateFormat.format(log.dateTime);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
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
                        color: log.status == 'Sent'
                            ? Colors.green.withOpacity(0.2)
                            : Colors.red.withOpacity(0.2),
                      ),
                      child: Icon(
                        log.status == 'Sent' ? Icons.check : Icons.error_outline,
                        color: log.status == 'Sent' ? Colors.green : Colors.red,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log.originalSender,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'To: ${log.forwardedTo}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formattedDate.split(' ')[0],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                        Text(
                          formattedDate.split(' ')[1],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  log.messageContent,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (log.status == 'Failed' && log.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Error: ${log.errorMessage}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[300],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
} 