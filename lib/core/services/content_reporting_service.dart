import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Report categories for different types of content violations
enum ReportCategory {
  inappropriate(
    'Inappropriate Content',
    'Content that is sexually explicit, violent, or otherwise inappropriate',
  ),
  hateful(
    'Hateful Content',
    'Content that promotes hatred, discrimination, or harassment',
  ),
  harmful(
    'Harmful Content',
    'Content that could cause harm, self-harm, or dangerous activities',
  ),
  spam('Spam or Misleading', 'Content that is spam, misleading, or fraudulent'),
  copyright(
    'Copyright Violation',
    'Content that violates intellectual property rights',
  ),
  other('Other', 'Other policy violations or concerns');

  const ReportCategory(this.displayName, this.description);

  final String displayName;
  final String description;
}

/// Report reasons for more specific categorization
enum ReportReason {
  // Inappropriate Content
  sexualContent('Sexual Content', ReportCategory.inappropriate),
  violence('Violence or Gore', ReportCategory.inappropriate),
  drugUse('Drug or Substance Use', ReportCategory.inappropriate),

  // Hateful Content
  hateSpeech('Hate Speech', ReportCategory.hateful),
  discrimination('Discrimination', ReportCategory.hateful),
  harassment('Harassment or Bullying', ReportCategory.hateful),

  // Harmful Content
  selfHarm('Self-Harm Content', ReportCategory.harmful),
  dangerousActivities('Dangerous Activities', ReportCategory.harmful),
  misinformation('Misinformation', ReportCategory.harmful),

  // Spam
  spam('Spam Content', ReportCategory.spam),
  misleading('Misleading Information', ReportCategory.spam),

  // Copyright
  copyright('Copyright Infringement', ReportCategory.copyright),
  trademark('Trademark Violation', ReportCategory.copyright),

  // Other
  other('Other Policy Violation', ReportCategory.other);

  const ReportReason(this.displayName, this.category);

  final String displayName;
  final ReportCategory category;
}

/// Report data structure
class ContentReport {
  final String id;
  final String prompt;
  final Uint8List? imageBytes;
  final ReportCategory category;
  final ReportReason reason;
  final String? additionalDetails;
  final DateTime timestamp;
  final String? imageId; // For saved images

  ContentReport({
    required this.id,
    required this.prompt,
    this.imageBytes,
    required this.category,
    required this.reason,
    this.additionalDetails,
    required this.timestamp,
    this.imageId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'prompt': prompt,
      'imageBytes': imageBytes != null ? base64Encode(imageBytes!) : null,
      'category': category.name,
      'reason': reason.name,
      'additionalDetails': additionalDetails,
      'timestamp': timestamp.toIso8601String(),
      'imageId': imageId,
    };
  }

  factory ContentReport.fromJson(Map<String, dynamic> json) {
    return ContentReport(
      id: json['id'],
      prompt: json['prompt'],
      imageBytes: json['imageBytes'] != null
          ? base64Decode(json['imageBytes'])
          : null,
      category: ReportCategory.values.firstWhere(
        (e) => e.name == json['category'],
      ),
      reason: ReportReason.values.firstWhere((e) => e.name == json['reason']),
      additionalDetails: json['additionalDetails'],
      timestamp: DateTime.parse(json['timestamp']),
      imageId: json['imageId'],
    );
  }
}

/// Service for handling content reporting functionality
/// Required by Google Play Console AI-Generated Content Policy
class ContentReportingService {
  static const String _reportsKey = 'content_reports';
  static const String _reportCountKey = 'report_count';
  static const int _maxReportsPerDay = 10;
  static const int _maxReportsPerHour = 3;

  /// Submit a content report
  static Future<bool> submitReport({
    required String prompt,
    Uint8List? imageBytes,
    required ReportCategory category,
    required ReportReason reason,
    String? additionalDetails,
    String? imageId,
  }) async {
    try {
      // Check rate limiting
      if (!await _checkRateLimit()) {
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      final reports = await _getReports();

      final report = ContentReport(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        prompt: prompt,
        imageBytes: imageBytes,
        category: category,
        reason: reason,
        additionalDetails: additionalDetails,
        timestamp: DateTime.now(),
        imageId: imageId,
      );

      reports.add(report);

      // Save reports
      final reportsJson = reports.map((r) => r.toJson()).toList();
      await prefs.setString(_reportsKey, jsonEncode(reportsJson));

      // Update report count for rate limiting
      await _incrementReportCount();

      if (kDebugMode) {
        print('Content report submitted: ${report.id}');
        print('Category: ${category.displayName}');
        print('Reason: ${reason.displayName}');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error submitting content report: $e');
      }
      return false;
    }
  }

  /// Get all submitted reports
  static Future<List<ContentReport>> getReports() async {
    return await _getReports();
  }

  /// Clear all reports (for testing or user request)
  static Future<void> clearReports() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_reportsKey);
    await prefs.remove(_reportCountKey);
  }

  /// Check if user can submit more reports (rate limiting)
  static Future<bool> canSubmitReport() async {
    return await _checkRateLimit();
  }

  /// Get report statistics
  static Future<Map<String, int>> getReportStats() async {
    final reports = await _getReports();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisHour = DateTime(now.year, now.month, now.day, now.hour);

    int todayCount = 0;
    int hourCount = 0;
    Map<ReportCategory, int> categoryCounts = {};

    for (final report in reports) {
      if (report.timestamp.isAfter(today)) {
        todayCount++;
      }
      if (report.timestamp.isAfter(thisHour)) {
        hourCount++;
      }

      categoryCounts[report.category] =
          (categoryCounts[report.category] ?? 0) + 1;
    }

    return {
      'total': reports.length,
      'today': todayCount,
      'thisHour': hourCount,
      'maxPerDay': _maxReportsPerDay,
      'maxPerHour': _maxReportsPerHour,
    };
  }

  /// Get reports by category
  static Future<List<ContentReport>> getReportsByCategory(
    ReportCategory category,
  ) async {
    final reports = await _getReports();
    return reports.where((r) => r.category == category).toList();
  }

  /// Get recent reports (last 24 hours)
  static Future<List<ContentReport>> getRecentReports() async {
    final reports = await _getReports();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return reports.where((r) => r.timestamp.isAfter(yesterday)).toList();
  }

  // Private helper methods

  static Future<List<ContentReport>> _getReports() async {
    final prefs = await SharedPreferences.getInstance();
    final reportsJson = prefs.getString(_reportsKey);

    if (reportsJson == null) {
      return [];
    }

    try {
      final List<dynamic> reportsList = jsonDecode(reportsJson);
      return reportsList.map((json) => ContentReport.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing reports: $e');
      }
      return [];
    }
  }

  static Future<bool> _checkRateLimit() async {
    final prefs = await SharedPreferences.getInstance();
    final reportCountJson = prefs.getString(_reportCountKey);

    if (reportCountJson == null) {
      return true;
    }

    try {
      final Map<String, dynamic> reportCount = jsonDecode(reportCountJson);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final thisHour = DateTime(now.year, now.month, now.day, now.hour);

      // Check daily limit
      final lastReportDate = DateTime.tryParse(
        reportCount['lastReportDate'] ?? '',
      );
      if (lastReportDate != null && lastReportDate.isAfter(today)) {
        final todayCount = reportCount['todayCount'] ?? 0;
        if (todayCount >= _maxReportsPerDay) {
          return false;
        }
      }

      // Check hourly limit
      final lastReportHour = DateTime.tryParse(
        reportCount['lastReportHour'] ?? '',
      );
      if (lastReportHour != null && lastReportHour.isAfter(thisHour)) {
        final hourCount = reportCount['hourCount'] ?? 0;
        if (hourCount >= _maxReportsPerHour) {
          return false;
        }
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking rate limit: $e');
      }
      return true;
    }
  }

  static Future<void> _incrementReportCount() async {
    final prefs = await SharedPreferences.getInstance();
    final reportCountJson = prefs.getString(_reportCountKey);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisHour = DateTime(now.year, now.month, now.day, now.hour);

    Map<String, dynamic> reportCount = {};

    if (reportCountJson != null) {
      try {
        reportCount = jsonDecode(reportCountJson);
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing report count: $e');
        }
      }
    }

    // Reset daily count if new day
    final lastReportDate = DateTime.tryParse(
      reportCount['lastReportDate'] ?? '',
    );
    if (lastReportDate == null || !lastReportDate.isAfter(today)) {
      reportCount['todayCount'] = 1;
      reportCount['lastReportDate'] = today.toIso8601String();
    } else {
      reportCount['todayCount'] = (reportCount['todayCount'] ?? 0) + 1;
    }

    // Reset hourly count if new hour
    final lastReportHour = DateTime.tryParse(
      reportCount['lastReportHour'] ?? '',
    );
    if (lastReportHour == null || !lastReportHour.isAfter(thisHour)) {
      reportCount['hourCount'] = 1;
      reportCount['lastReportHour'] = thisHour.toIso8601String();
    } else {
      reportCount['hourCount'] = (reportCount['hourCount'] ?? 0) + 1;
    }

    await prefs.setString(_reportCountKey, jsonEncode(reportCount));
  }
}
