import 'dart:convert';

class ScheduleModel {
  final String id;
  final String title;
  final String content;
  final int taskCount;
  final int totalDuration;
  final DateTime createdAt;

  ScheduleModel({
    required this.id,
    required this.title,
    required this.content,
    required this.taskCount,
    required this.totalDuration,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'taskCount': taskCount,
      'totalDuration': totalDuration,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ScheduleModel.fromMap(Map<String, dynamic> map) {
    return ScheduleModel(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      taskCount: map['taskCount'],
      totalDuration: map['totalDuration'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  String toJson() => jsonEncode(toMap());
  factory ScheduleModel.fromJson(String source) =>
      ScheduleModel.fromMap(jsonDecode(source));
}
