class State {
  final int id;
  final String stateName;
  final String? stateDesc;

  State({required this.id, required this.stateName, this.stateDesc});

  factory State.fromJson(Map<String, dynamic> json) {
    return State(
      id: json['Id'] as int,
      stateName: json['StateName'] as String,
      stateDesc: json['StateDesc'] as String?,
    );
  }

  @override
  String toString() {
    return 'State(id: $id, stateName: $stateName, stateDesc: $stateDesc)';
  }
}
