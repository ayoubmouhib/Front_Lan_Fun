import 'package:flutter/material.dart';

class AchievementModel {
  const AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.progress,
    required this.total,
    this.unlockedAt,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int progress;
  final int total;
  final DateTime? unlockedAt;

  bool get unlocked => progress >= total;

  double get fraction => total > 0 ? (progress / total).clamp(0.0, 1.0) : 0;
}
