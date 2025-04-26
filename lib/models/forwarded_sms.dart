class ForwardedSms {
  final String contactName;
  final String forwardedTo;
  final String messageContent;
  final DateTime dateTime;

  ForwardedSms({
    required this.contactName,
    required this.forwardedTo,
    required this.messageContent,
    required this.dateTime,
  });
} 