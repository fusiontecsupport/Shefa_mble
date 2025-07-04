class CollectionTarget {
  final String cateCode;
  final String cateName;
  final String catePName;
  final String catePHN3;
  final String cateEmail;
  final double hamt1;
  final double hamt2;
  final int cateId;
  final int tgtPlnMId;

  CollectionTarget({
    required this.cateCode,
    required this.cateName,
    required this.catePName,
    required this.catePHN3,
    required this.cateEmail,
    required this.hamt1,
    required this.hamt2,
    required this.cateId,
    required this.tgtPlnMId,
  });

  factory CollectionTarget.fromJson(Map<String, dynamic> json) {
    return CollectionTarget(
      cateCode: json['CATECODE'] ?? '',
      cateName: json['CATENAME'] ?? '',
      catePName: json['CATEPNAME'] ?? '',
      catePHN3: json['CATEPHN3'] ?? '',
      cateEmail: json['CATEMAIL'] ?? '',
      hamt1: (json['HAMT1'] ?? 0.0).toDouble(),
      hamt2: (json['HAMT2'] ?? 0.0).toDouble(),
      cateId: json['CATEID'] ?? 0,
      tgtPlnMId: json['TGTPLNMID'] ?? 0,
    );
  }
}