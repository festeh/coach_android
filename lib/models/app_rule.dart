class AppRule {
  final String id;
  final String packageName;
  final int everyN;
  final int maxTriggers;
  final String challengeType;

  const AppRule({
    required this.id,
    required this.packageName,
    required this.everyN,
    required this.maxTriggers,
    this.challengeType = 'none',
  });

  AppRule copyWith({
    String? id,
    String? packageName,
    int? everyN,
    int? maxTriggers,
    String? challengeType,
  }) {
    return AppRule(
      id: id ?? this.id,
      packageName: packageName ?? this.packageName,
      everyN: everyN ?? this.everyN,
      maxTriggers: maxTriggers ?? this.maxTriggers,
      challengeType: challengeType ?? this.challengeType,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'packageName': packageName,
        'everyN': everyN,
        'maxTriggers': maxTriggers,
        'challengeType': challengeType,
      };

  factory AppRule.fromJson(Map<String, dynamic> json) => AppRule(
        id: json['id'] as String,
        packageName: json['packageName'] as String,
        everyN: json['everyN'] as int,
        maxTriggers: json['maxTriggers'] as int,
        challengeType: json['challengeType'] as String? ?? 'none',
      );
}
