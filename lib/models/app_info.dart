class AppInfo {
  final String name;
  
  AppInfo({required this.name});
  
  factory AppInfo.fromMap(Map<dynamic, dynamic> map) {
    return AppInfo(
      name: map['name'] as String,
    );
  }
}
