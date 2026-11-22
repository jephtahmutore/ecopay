/// One person in a Mukando (rotating savings club).
class ClubMember {
  ClubMember({required this.name, this.paid = false, this.isYou = false});

  final String name;

  /// Whether they have paid for the current round.
  bool paid;
  final bool isYou;
}

/// A Mukando: everyone pays the same amount each round and one member,
/// in turn, receives the whole pot.
class SavingsClub {
  SavingsClub({
    required this.id,
    required this.name,
    required this.contributionCents,
    required this.members,
    required this.payoutDate,
    this.round = 1,
  });

  final String id;
  final String name;
  final int contributionCents;

  /// Members in payout order.
  final List<ClubMember> members;
  final DateTime payoutDate;
  int round;

  int get totalRounds => members.length;
  ClubMember get receiver => members[(round - 1) % members.length];
  ClubMember get you => members.firstWhere((m) => m.isYou);
  int get potCents => contributionCents * members.length;
  int get paidCount => members.where((m) => m.paid).length;
  int get collectedCents => paidCount * contributionCents;
  bool get allPaid => paidCount == members.length;
}
