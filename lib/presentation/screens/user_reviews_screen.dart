import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../config/theme.dart';
import '../../data/datasources/remote/api_client.dart';
import '../../data/datasources/remote/matching_api.dart';
import '../../data/models/review_model.dart';
import '../../data/repositories/matching_repository.dart';

class UserReviewsScreen extends StatefulWidget {
  const UserReviewsScreen({super.key});

  @override
  State<UserReviewsScreen> createState() => _UserReviewsScreenState();
}

class _UserReviewsScreenState extends State<UserReviewsScreen> {
  final _reviews      = <ReviewModel>[].obs;
  final _isLoading    = true.obs;
  final _sortBy       = 'newest'.obs;    // newest | highest | lowest
  final _filterRating = Rx<int?>(null);  // null = all, 1-5 = specific star

  late final MatchingRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = MatchingRepository(MatchingApi(ApiClient.instance));
    _loadReviews();
  }

  // ─── Load ──────────────────────────────────────────────────────────────────

  Future<void> _loadReviews() async {
    _isLoading.value = true;
    try {
      final res = await _repo.getMyRatings(limit: 100);
      final list = (res['reviews'] as List<dynamic>? ?? [])
          .map((j) => ReviewModel.fromJson(j as Map<String, dynamic>))
          .toList();
      _reviews.assignAll(list);
    } catch (_) {
      _reviews.clear();
    } finally {
      _isLoading.value = false;
    }
  }

  List<ReviewModel> get _sorted {
    var list = _reviews.toList();
    if (_filterRating.value != null) {
      list = list.where((r) => r.overallScore == _filterRating.value).toList();
    }
    switch (_sortBy.value) {
      case 'highest':
        list.sort((a, b) => b.overallScore.compareTo(a.overallScore));
      case 'lowest':
        list.sort((a, b) => a.overallScore.compareTo(b.overallScore));
      default:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return list;
  }

  double get _averageRating {
    if (_reviews.isEmpty) return 0;
    return _reviews.fold(0.0, (s, r) => s + r.overallScore) / _reviews.length;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Obx(() {
        if (_isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: _loadReviews,
          color: AppColors.primary,
          child: CustomScrollView(
            slivers: [
              // ── App bar + rating header ────────────────────────────
              _ReviewsSliverAppBar(
                averageRating: _averageRating,
                reviewCount: _reviews.length,
              ),

              // ── Sort + filter controls ─────────────────────────────
              if (_reviews.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Obx(() => _SortFilterRow(
                          sortBy: _sortBy.value,
                          filterRating: _filterRating.value,
                          onSortChanged: (v) => _sortBy.value = v,
                          onFilterChanged: (v) => _filterRating.value = v,
                        )),
                  ),
                ),

                // Rating distribution bar chart
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _RatingDistribution(
                        reviews: _reviews, isDark: isDark),
                  ),
                ),

                // Review list
                SliverPadding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  sliver: Obx(() {
                    final items = _sorted;
                    if (items.isEmpty) {
                      return SliverToBoxAdapter(
                        child: _NoMatchState(
                            filterRating: _filterRating.value),
                      );
                    }
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ReviewCard(
                              review: items[i], isDark: isDark),
                        ),
                        childCount: items.length,
                      ),
                    );
                  }),
                ),
              ] else
                SliverFillRemaining(
                  child: _EmptyReviews(isDark: isDark),
                ),
            ],
          ),
        );
      }),
    );
  }
}

// ─── Sliver app bar ───────────────────────────────────────────────────────────

class _ReviewsSliverAppBar extends StatelessWidget {
  const _ReviewsSliverAppBar({
    required this.averageRating,
    required this.reviewCount,
  });
  final double averageRating;
  final int reviewCount;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: reviewCount > 0 ? 200 : 140,
      pinned: true,
      automaticallyImplyLeading: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      leading: BackButton(onPressed: Get.back),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration:
              const BoxDecoration(gradient: AppColors.primaryGradient),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'My Reviews',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reviewCount > 0
                        ? '$reviewCount review${reviewCount != 1 ? 's' : ''} from your partners'
                        : 'Reviews from your language partners',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                  if (reviewCount > 0) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          averageRating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _StarRow(rating: averageRating, size: 18),
                            const SizedBox(height: 4),
                            Text(
                              '$reviewCount reviews',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Sort + Filter row ────────────────────────────────────────────────────────

class _SortFilterRow extends StatelessWidget {
  const _SortFilterRow({
    required this.sortBy,
    required this.filterRating,
    required this.onSortChanged,
    required this.onFilterChanged,
  });
  final String sortBy;
  final int? filterRating;
  final ValueChanged<String> onSortChanged;
  final ValueChanged<int?> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Sort dropdown
        _SortButton(
          current: sortBy,
          onChanged: onSortChanged,
        ),
        const Spacer(),
        // Rating filter chips
        ...List.generate(5, (i) {
          final star = 5 - i;
          final active = filterRating == star;
          return Padding(
            padding: const EdgeInsets.only(left: 4),
            child: GestureDetector(
              onTap: () =>
                  onFilterChanged(active ? null : star),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.amber
                      : Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded,
                        size: 12,
                        color: active
                            ? Colors.white
                            : AppColors.amber),
                    const SizedBox(width: 2),
                    Text(
                      '$star',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: active
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton(
      {required this.current, required this.onChanged});
  final String current;
  final ValueChanged<String> onChanged;

  String get _label => switch (current) {
        'highest' => 'Highest first',
        'lowest'  => 'Lowest first',
        _         => 'Newest first',
      };

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sort_rounded, size: 14),
            const SizedBox(width: 6),
            Text(_label,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down_rounded, size: 16),
          ],
        ),
      ),
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'newest',  child: Text('Newest first')),
        PopupMenuItem(value: 'highest', child: Text('Highest first')),
        PopupMenuItem(value: 'lowest',  child: Text('Lowest first')),
      ],
    );
  }
}

// ─── Rating distribution ──────────────────────────────────────────────────────

class _RatingDistribution extends StatelessWidget {
  const _RatingDistribution(
      {required this.reviews, required this.isDark});
  final List<ReviewModel> reviews;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final counts = List.generate(5, (i) {
      final star = 5 - i;
      return reviews.where((r) => r.overallScore == star).length;
    });
    final max = counts.isEmpty
        ? 1
        : counts.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppColors.darkOutline : AppColors.lightOutline),
      ),
      child: Column(
        children: List.generate(5, (i) {
          final star  = 5 - i;
          final count = counts[i];
          final pct   = max > 0 ? count / max : 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Text('$star',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                const Icon(Icons.star_rounded,
                    color: AppColors.amber, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 8,
                      backgroundColor: isDark
                          ? AppColors.darkSurfaceVariant
                          : AppColors.lightSurfaceVariant,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.amber),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 20,
                  child: Text(
                    '$count',
                    style: Theme.of(context).textTheme.labelSmall,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ─── Review card ──────────────────────────────────────────────────────────────

class _ReviewCard extends StatefulWidget {
  const _ReviewCard({required this.review, required this.isDark});
  final ReviewModel review;
  final bool isDark;

  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.review;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDark
            ? AppColors.darkSurface
            : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isDark
              ? AppColors.darkOutline
              : AppColors.lightOutline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────────────────────
          Row(
            children: [
              // Avatar
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: AppColors.purpleGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    r.reviewerInitials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.reviewerName,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    _StarRow(rating: r.overallScore.toDouble(), size: 14),
                  ],
                ),
              ),
              Text(
                _dateLabel(r.createdAt),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.4),
                    ),
              ),
            ],
          ),

          // ── Score breakdown ──────────────────────────────────────
          const SizedBox(height: 12),
          Row(
            children: [
              _ScoreBadge(label: 'Communication', score: r.communicationScore),
              const SizedBox(width: 6),
              _ScoreBadge(label: 'Helpfulness', score: r.helpfulnessScore),
              const SizedBox(width: 6),
              _ScoreBadge(label: 'Patience', score: r.patienceScore),
            ],
          ),

          // ── Comment ──────────────────────────────────────────────
          if (r.comment != null && r.comment!.isNotEmpty) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Text(
                r.comment!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                      height: 1.5,
                    ),
                maxLines: _expanded ? null : 3,
                overflow: _expanded
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
              ),
            ),
            if (r.comment!.length > 120)
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Text(
                  _expanded ? 'Show less' : 'Show more',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  String _dateLabel(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays < 1) return 'Today';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ─── Score badge ──────────────────────────────────────────────────────────────

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.label, required this.score});
  final String label;
  final int score;

  @override
  Widget build(BuildContext context) {
    final color = score >= 4
        ? AppColors.success
        : score == 3
            ? AppColors.amber
            : AppColors.error;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(
              '$score/5',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: color.withValues(alpha: 0.7),
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Star row ─────────────────────────────────────────────────────────────────

class _StarRow extends StatelessWidget {
  const _StarRow({required this.rating, this.size = 16});
  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < rating.floor();
        final half   = !filled && i < rating;
        return Icon(
          filled
              ? Icons.star_rounded
              : half
                  ? Icons.star_half_rounded
                  : Icons.star_outline_rounded,
          color: AppColors.amber,
          size: size,
        );
      }),
    );
  }
}

// ─── Empty states ─────────────────────────────────────────────────────────────

class _EmptyReviews extends StatelessWidget {
  const _EmptyReviews({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star_outline_rounded,
                  size: 52, color: AppColors.amber),
            ),
            const SizedBox(height: 24),
            Text(
              'No reviews yet',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              'Complete language sessions and ask your partners to rate you. Reviews will appear here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.45),
                  ),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.info, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Reviews are collected automatically after each completed session. The more you practice, the more reviews you receive!',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.info),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoMatchState extends StatelessWidget {
  const _NoMatchState({required this.filterRating});
  final int? filterRating;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text(
          filterRating != null
              ? 'No $filterRating-star reviews'
              : 'No reviews match the filter',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.4),
              ),
        ),
      ),
    );
  }
}
