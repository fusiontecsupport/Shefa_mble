class Branch {
  final int branchId;
  final String branchName;
  final String branchCode;
  final int stateId;
  final String stateName;

  Branch({
    required this.branchId,
    required this.branchName,
    required this.branchCode,
    required this.stateId,
    required this.stateName,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      branchId: json['Id'] ?? 0, // API returns 'Id'
      branchName: json['BrnchName'] ?? '', // API returns 'BrnchName'
      branchCode: json['BranchCode'] ?? '', // May not be present
      stateId: json['StateId'] ?? 0,
      stateName: json['StateName'] ?? '',
    );
  }

  @override
  String toString() {
    return 'Branch(branchId: $branchId, branchName: $branchName, branchCode: $branchCode, stateId: $stateId, stateName: $stateName)';
  }
}
