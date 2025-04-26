import 'package:uuid/uuid.dart';

class ForwardedSmsLog {
  final String id; // Unique ID for the log entry
  final String filterId; // ID of the filter that triggered the forward
  final String originalSender;
  final String forwardedTo; // The specific recipient it was forwarded to
  final String messageContent; // The original message body
  final DateTime dateTime; // When the forwarding occurred
  final String status; // e.g., 'Sent', 'Failed'
  final String? errorMessage; // Optional error message if sending failed

  ForwardedSmsLog({
    String? id,
    required this.filterId,
    required this.originalSender,
    required this.forwardedTo,
    required this.messageContent,
    required this.dateTime,
    required this.status,
    this.errorMessage,
  }) : id = id ?? const Uuid().v4(); // Generate ID if not provided

  // For Database (Map <-> Object)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'filterId': filterId,
      'originalSender': originalSender,
      'forwardedTo': forwardedTo,
      'messageContent': messageContent,
      'dateTime': dateTime.toIso8601String(), // Store as ISO string
      'status': status,
      'errorMessage': errorMessage,
    };
  }

  factory ForwardedSmsLog.fromMap(Map<String, dynamic> map) {
    return ForwardedSmsLog(
      id: map['id'] as String,
      filterId: map['filterId'] as String,
      originalSender: map['originalSender'] as String,
      forwardedTo: map['forwardedTo'] as String,
      messageContent: map['messageContent'] as String,
      dateTime: DateTime.parse(map['dateTime'] as String), // Parse from ISO string
      status: map['status'] as String,
      errorMessage: map['errorMessage'] as String?,
    );
  }
} 