// lib/client.dart

class Client {
  final String code;
  final String name;
  final String contactPerson;
  final String mobileNo;
  final int cateId;
  final int tgtplnMid;

  Client({
    required this.code,
    required this.name,
    required this.contactPerson,
    required this.mobileNo,
    required this.cateId,
    required this.tgtplnMid,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      code: json['CATECODE'] ?? '',
      name: json['CATENAME'] ?? '',
      contactPerson: json['CATEPNAME'] ?? '',
      mobileNo: json['CATEPHN3'] ?? '',
      cateId: json['CATEID'] ?? 0,
      tgtplnMid: json['TGTPLNMID'] ?? 0,
    );
  }
}