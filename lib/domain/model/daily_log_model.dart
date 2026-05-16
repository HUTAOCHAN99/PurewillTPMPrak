enum LogStatus {
  neutral,
  success,
  failed,
}

class DailyLogModel {
  final int id;
  final int habitId;
  final DateTime logDate;
  final LogStatus status; 
  final double? actualValue;
  final DateTime? createdAt;

  DailyLogModel({
    required this.id,
    required this.habitId,
    required this.logDate,
    required this.status,
    this.actualValue,
    this.createdAt,
  });

  static LogStatus parseLogStatus(String statusString) {
    switch (statusString.toLowerCase()) {
      case "success":
        return LogStatus.success;
      case "neutral":
        return LogStatus.neutral;
      case "failed":
        return LogStatus.failed;
      default:
        return LogStatus.neutral;
    }
  }


  factory DailyLogModel.fromJson(Map<String, dynamic> json) {
    return DailyLogModel(
      id: json['id'],
      habitId: json['habit_id'],
      logDate: DateTime.parse(json['log_date']),
      status: parseLogStatus(json['status']),
      actualValue: json['actual_value']?.toDouble(), 
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'habit_id': habitId,
      'log_date': logDate.toIso8601String().substring(0, 10),
      'status': status,
      'actual_value': actualValue,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}