import 'package:cc98_ocean/core/objects.dart';

abstract class ConstantItems{
  static const List<SectionInfo> sectionList = [
  SectionInfo(
    jsonPropertyName: "hotTopic",
    description: "十大话题",
  ),
  SectionInfo(
    jsonPropertyName: "study",
    description: "学习天地",
  ),
  SectionInfo(
    jsonPropertyName: "emotion",
    description: "感性·情感",
  ),
  SectionInfo(
    jsonPropertyName: "academics",
    description: "学术通知",
  ),
  SectionInfo(
    jsonPropertyName: "schoolEvent",
    description: "校园活动",
  ),
  SectionInfo(
    jsonPropertyName: "fleaMarket",
    description: "跳蚤市场",
  ),
  SectionInfo(
    jsonPropertyName: "fullTimeJob",
    description: "求职广场",
  ),
  SectionInfo(
    jsonPropertyName: "partTimeJob",
    description: "实习兼职",
  ),
];
}