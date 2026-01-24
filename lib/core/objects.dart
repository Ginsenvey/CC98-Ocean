class SectionInfo {
  final String jsonPropertyName;  // 英文名
  final String description; // 中文描述

  const SectionInfo({
    required this.jsonPropertyName,
    required this.description,
  });

  @override
  String toString() {
    return 'SectionInfo(Name: $jsonPropertyName, Description: $description)';
  }
}