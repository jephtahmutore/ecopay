import 'quote.dart';

enum TransferStatus { pending, completed, failed }

/// A money transfer from the user's wallet to a recipient.
class Transfer {
  const Transfer({
    required this.id,
    required this.recipientName,
    required this.recipientPhone,
    required this.quote,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String recipientName;
  final String recipientPhone;
  final Quote quote;
  final TransferStatus status;
  final DateTime createdAt;

  Transfer copyWith({TransferStatus? status}) => Transfer(
        id: id,
        recipientName: recipientName,
        recipientPhone: recipientPhone,
        quote: quote,
        status: status ?? this.status,
        createdAt: createdAt,
      );
}
