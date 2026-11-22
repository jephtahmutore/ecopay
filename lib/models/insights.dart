import 'corridor.dart';
import 'transfer.dart';

/// A summary of the user's spending for one calendar month.
class SpendingInsights {
  const SpendingInsights({
    required this.sentCents,
    required this.feesCents,
    required this.airtimeCents,
    required this.transferCount,
    required this.topCountry,
  });

  /// Money sent to recipients, before fees.
  final int sentCents;
  final int feesCents;
  final int airtimeCents;
  final int transferCount;

  /// The country the user sent the most money to, or null if none.
  final String? topCountry;

  int get totalSpentCents => sentCents + feesCents + airtimeCents;

  static SpendingInsights forMonth(Iterable<Transfer> transfers, DateTime month) {
    var sent = 0;
    var fees = 0;
    var airtime = 0;
    var count = 0;
    final byCountry = <String, int>{};

    for (final t in transfers) {
      if (t.createdAt.year != month.year || t.createdAt.month != month.month) continue;
      if (t.status == TransferStatus.failed) continue;
      if (t.isAirtime) {
        airtime += t.quote.totalCents;
        continue;
      }
      sent += t.quote.sendCents;
      fees += t.quote.feeCents;
      count++;
      byCountry[t.country] = (byCountry[t.country] ?? 0) + t.quote.sendCents;
    }

    String? top;
    var topAmount = 0;
    for (final entry in byCountry.entries) {
      if (entry.value > topAmount) {
        top = entry.key;
        topAmount = entry.value;
      }
    }

    return SpendingInsights(
      sentCents: sent,
      feesCents: fees,
      airtimeCents: airtime,
      transferCount: count,
      topCountry: top,
    );
  }
}

/// Someone the user has sent money to before, so they can send again in one tap.
class SavedRecipient {
  const SavedRecipient({
    required this.name,
    required this.phone,
    required this.country,
    required this.deliveryMethod,
  });

  final String name;
  final String phone;
  final String country;
  final DeliveryMethod deliveryMethod;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  /// Newest first, one entry per phone number, airtime excluded.
  static List<SavedRecipient> fromHistory(Iterable<Transfer> newestFirst, {int limit = 8}) {
    final seen = <String>{};
    final result = <SavedRecipient>[];
    for (final t in newestFirst) {
      if (t.isAirtime || !seen.add(t.recipientPhone)) continue;
      result.add(SavedRecipient(
        name: t.recipientName,
        phone: t.recipientPhone,
        country: t.country,
        deliveryMethod: t.deliveryMethod,
      ));
      if (result.length == limit) break;
    }
    return result;
  }
}
