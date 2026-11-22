import 'corridor.dart';
import 'quote.dart';

enum TransferStatus { pending, completed, failed }

/// What the money was used for.
enum TransferKind { remittance, airtime }

/// A money transfer from the user's wallet to a recipient,
/// or an airtime top up bought from the wallet.
class Transfer {
  const Transfer({
    required this.id,
    required this.recipientName,
    required this.recipientPhone,
    required this.quote,
    required this.status,
    required this.createdAt,
    this.kind = TransferKind.remittance,
    this.country = 'Other',
    this.deliveryMethod = DeliveryMethod.mobileWallet,
  });

  final String id;
  final String recipientName;
  final String recipientPhone;
  final Quote quote;
  final TransferStatus status;
  final DateTime createdAt;
  final TransferKind kind;
  final String country;
  final DeliveryMethod deliveryMethod;

  bool get isAirtime => kind == TransferKind.airtime;

  Transfer copyWith({TransferStatus? status}) => Transfer(
        id: id,
        recipientName: recipientName,
        recipientPhone: recipientPhone,
        quote: quote,
        status: status ?? this.status,
        createdAt: createdAt,
        kind: kind,
        country: country,
        deliveryMethod: deliveryMethod,
      );
}
