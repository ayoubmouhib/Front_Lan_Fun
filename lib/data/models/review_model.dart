class ReviewModel {
  const ReviewModel({
    required this.id,
    required this.reviewerName,
    required this.overallScore,
    required this.communicationScore,
    required this.helpfulnessScore,
    required this.patienceScore,
    required this.createdAt,
    this.comment,
  });

  final int id;
  final String reviewerName;
  final int overallScore;        // 1–5
  final int communicationScore;  // 1–5
  final int helpfulnessScore;    // 1–5
  final int patienceScore;       // 1–5
  final String? comment;
  final DateTime createdAt;

  String get reviewerInitials {
    final parts = reviewerName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return reviewerName.isNotEmpty ? reviewerName[0].toUpperCase() : '?';
  }

  double get averageScore =>
      (overallScore + communicationScore + helpfulnessScore + patienceScore) / 4;

  factory ReviewModel.fromJson(Map<String, dynamic> j) => ReviewModel(
        id:                 j['id'] as int,
        reviewerName:       (j['rater'] as Map<String, dynamic>?)?['name'] as String? ??
                            'Anonymous',
        overallScore:       j['overall_score'] as int? ?? 0,
        communicationScore: j['communication_score'] as int? ?? 0,
        helpfulnessScore:   j['helpfulness_score'] as int? ?? 0,
        patienceScore:      j['patience_score'] as int? ?? 0,
        comment:            j['comment'] as String?,
        createdAt:          j['created_at'] != null
                                ? DateTime.tryParse(j['created_at'] as String) ??
                                    DateTime.now()
                                : DateTime.now(),
      );
}
