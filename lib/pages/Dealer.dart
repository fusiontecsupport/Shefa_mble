class Dealer {
  final int cateId;
  final String cateName;
  final int creditPeriod;

  Dealer({
    required this.cateId,
    required this.cateName,
    required this.creditPeriod,
  });

  factory Dealer.fromJson(Map<String, dynamic> json) {
    return Dealer(
      cateId: int.tryParse(json['CateId']?.toString() ?? '') ?? 0,
      cateName: json['CateName']?.toString() ?? 'Unknown',
      creditPeriod: int.tryParse(json['CreditPeriod']?.toString() ?? '') ?? 0,
    );
  }

  @override
  String toString() => '$cateName (CateId: $cateId)';
}
