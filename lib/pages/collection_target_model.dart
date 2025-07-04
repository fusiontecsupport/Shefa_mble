class CollectionTarget {
  final String cateCode;
  final String cateName;
  final String catePName;
  final String catePhn3;
  final String cateEmail;
  final int cateId;
  final int tgtplnmid;

  CollectionTarget({
    required this.cateCode,
    required this.cateName,
    required this.catePName,
    required this.catePhn3,
    required this.cateEmail,
    required this.cateId,
    required this.tgtplnmid,
  });

  factory CollectionTarget.fromJson(Map<String, dynamic> json) {
    return CollectionTarget(
      cateCode: json['CATECODE'] ?? '',
      cateName: json['CATENAME'] ?? '',
      catePName: json['CATEPNAME'] ?? '',
      catePhn3: json['CATEPHN3'] ?? '',
      cateEmail: json['CATEMAIL'] ?? '',
      cateId: json['CATEID'] ?? 0,
      tgtplnmid: json['TGTPLNMID'] ?? 0,
    );
  }
}