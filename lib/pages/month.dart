class Month {
  final int monthId;
  final String monthDesc;
  final int dispOrder;

  Month({
    required this.monthId,
    required this.monthDesc,
    required this.dispOrder,
  });

  factory Month.fromJson(Map<String, dynamic> json) {
    return Month(
      monthId: json['MonthId'] as int,
      monthDesc: json['MonthDesc'] as String,
      dispOrder: json['DispOrder'] as int,
    );
  }
}