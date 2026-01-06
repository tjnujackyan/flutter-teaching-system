// AI功能相关数据模型
import 'dart:convert';

/// 薄弱点数据模型
class WeakPoint {
  final String knowledgePoint;
  final String category;
  final double accuracy;
  final String severity; // high/medium/low
  final int questionCount;
  final String? analysis;

  WeakPoint({
    required this.knowledgePoint,
    required this.category,
    required this.accuracy,
    required this.severity,
    required this.questionCount,
    this.analysis,
  });

  factory WeakPoint.fromJson(Map<String, dynamic> json) {
    return WeakPoint(
      knowledgePoint: json['knowledgePoint'] ?? '',
      category: json['category'] ?? '',
      accuracy: (json['accuracy'] ?? 0).toDouble(),
      severity: json['severity'] ?? 'medium',
      questionCount: json['questionCount'] ?? 0,
      analysis: json['analysis'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'knowledgePoint': knowledgePoint,
      'category': category,
      'accuracy': accuracy,
      'severity': severity,
      'questionCount': questionCount,
      'analysis': analysis,
    };
  }
}

/// 优势点数据模型
class StrongPoint {
  final String knowledgePoint;
  final double accuracy;
  final int questionCount;
  final String? praise;

  StrongPoint({
    required this.knowledgePoint,
    required this.accuracy,
    required this.questionCount,
    this.praise,
  });

  factory StrongPoint.fromJson(Map<String, dynamic> json) {
    return StrongPoint(
      knowledgePoint: json['knowledgePoint'] ?? '',
      accuracy: (json['accuracy'] ?? 0).toDouble(),
      questionCount: json['questionCount'] ?? 0,
      praise: json['praise'],
    );
  }
}

/// 学习习惯数据模型
class LearningHabits {
  final String? consistency;
  final String? efficiency;
  final String? preferredStudyTime;
  final int? consistencyScore;

  LearningHabits({
    this.consistency,
    this.efficiency,
    this.preferredStudyTime,
    this.consistencyScore,
  });

  factory LearningHabits.fromJson(Map<String, dynamic> json) {
    return LearningHabits(
      consistency: json['consistency'],
      efficiency: json['efficiency'],
      preferredStudyTime: json['preferredStudyTime'],
      consistencyScore: json['consistencyScore'],
    );
  }
}

/// AI分析结果数据模型
class AIAnalysisResult {
  final int analysisId;
  final int studentId;
  final String timeRange;
  final Map<String, dynamic> dataStats;
  final List<WeakPoint> weakPoints;
  final List<StrongPoint> strongPoints;
  final LearningHabits learningHabits;
  final String aiSuggestions;
  final String generatedAt;

  AIAnalysisResult({
    required this.analysisId,
    required this.studentId,
    required this.timeRange,
    required this.dataStats,
    required this.weakPoints,
    required this.strongPoints,
    required this.learningHabits,
    required this.aiSuggestions,
    required this.generatedAt,
  });

  factory AIAnalysisResult.fromJson(Map<String, dynamic> json) {
    // 处理可能是字符串的 JSON 字段
    dynamic parseJsonField(dynamic field) {
      if (field is String) {
        try {
          return jsonDecode(field);
        } catch (e) {
          return field;
        }
      }
      return field;
    }

    final weakPointsData = parseJsonField(json['weakPoints']);
    final strongPointsData = parseJsonField(json['strongPoints']);
    final learningHabitsData = parseJsonField(json['learningHabits']);

    return AIAnalysisResult(
      analysisId: json['id'] ?? json['analysisId'] ?? 0,
      studentId: json['studentId'] ?? 0,
      timeRange: json['timeRange'] ?? '',
      dataStats: {
        'quizCount': json['quizCount'] ?? 0,
        'assignmentCount': json['assignmentCount'] ?? 0,
        'totalQuestions': json['totalQuestions'] ?? 0,
        'correctQuestions': json['correctQuestions'] ?? 0,
        'accuracy': json['accuracy'] ?? 0.0,
      },
      weakPoints: (weakPointsData is List)
              ? weakPointsData.map((e) => WeakPoint.fromJson(e)).toList()
              : [],
      strongPoints: (strongPointsData is List)
              ? strongPointsData.map((e) => StrongPoint.fromJson(e)).toList()
              : [],
      learningHabits: (learningHabitsData is Map)
          ? LearningHabits.fromJson(Map<String, dynamic>.from(learningHabitsData))
          : LearningHabits(),
      aiSuggestions: json['improvementSuggestions'] ?? json['aiSuggestions'] ?? '',
      generatedAt: json['createdAt'] ?? json['generatedAt'] ?? '',
    );
  }
}

/// 分析请求模型
class AnalysisRequest {
  final String analysisType;
  final String timeRange;
  final String? startDate;
  final String? endDate;

  AnalysisRequest({
    required this.analysisType,
    required this.timeRange,
    this.startDate,
    this.endDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'analysisType': analysisType,
      'timeRange': timeRange,
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
    };
  }
}

