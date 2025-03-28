class AppInfo {
  final String name;
  final String packageName; // Add package name field

  AppInfo({required this.name, required this.packageName});

  factory AppInfo.fromMap(Map<dynamic, dynamic> map) {
    return AppInfo(
      name: map['name'] as String,
      packageName: map['packageName'] as String, // Extract package name
    );
  }

  // Optional: Add equals and hashCode for Set operations if needed later
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppInfo &&
          runtimeType == other.runtimeType &&
          packageName == other.packageName;

  @override
  int get hashCode => packageName.hashCode;
}
