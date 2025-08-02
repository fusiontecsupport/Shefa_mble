class State {
  final int id;
  final String stateName;

  State({required this.id, required this.stateName});

  factory State.fromJson(Map<String, dynamic> json) {
    return State(id: json['Id'] as int, stateName: json['StateName'] as String);
  }

  @override
  String toString() {
    return 'State(id: $id, stateName: $stateName)';
  }
}
