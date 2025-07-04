class Location {
  final String loctId;
  final String loctDesc;

  Location({required this.loctId, required this.loctDesc});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      loctId: json['LoctId'].toString(),
      loctDesc: json['LoctDesc'],
    );
  }

  @override
  String toString() {
    return loctDesc; // Ensure this returns a meaningful string for display
  }
}
