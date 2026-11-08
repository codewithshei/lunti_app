import 'dart:async';

import 'package:flutter/material.dart';

import 'package:admin_dashboard/models/review.dart';
import 'package:admin_dashboard/services/admin_database.dart';
import 'package:admin_dashboard/theme.dart';
import 'package:admin_dashboard/widgets/admin_data_table.dart';
import 'package:admin_dashboard/widgets/admin_ui.dart';

/// Reviews Management: every customer review across the catalog in one table,
/// filterable by star rating, with moderate/delete moderation actions.
class ReviewsPage extends StatefulWidget {
  const ReviewsPage({super.key, this.database});

  /// Optional override used by widget tests.
  final AdminDatabase? database;

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  /// Upper bound on the initial load before the page stops spinning.
  static const _loadTimeout = Duration(seconds: 10);

  late final AdminDatabase _database = widget.database ?? AdminDatabase();

  /// Null means "All"; otherwise a 1-5 star filter.
  int? _ratingFilter;

  Timer? _timeoutTimer;
  bool _timedOut = false;

  @override
  void initState() {
    super.initState();
    _armTimeout();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _armTimeout() {
    _timeoutTimer?.cancel();
    _timedOut = false;
    _timeoutTimer = Timer(_loadTimeout, () {
      if (mounted) setState(() => _timedOut = true);
    });
  }

  void _retry() => setState(_armTimeout);

  /// Turns the raw stream error into something actionable for the admin.
  String _errorMessage(Object? error) {
    final text = '$error';
    if (text.contains('index')) {
      return 'The reviews query needs a Firestore collection-group index for '
          '`reviews`. Create it in the Firebase console, then retry.';
    }
    if (text.contains('permission')) {
      return 'You do not have permission to read customer reviews.';
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AdminReview>>(
      stream: _database.watchAllReviews(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _timeoutTimer?.cancel();
          _timedOut = false;
        }

        final all = snapshot.data ?? const <AdminReview>[];
        final reviews = _ratingFilter == null
            ? all
            : all.where((review) => review.rating == _ratingFilter).toList();
        final loading =
            snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData;

        return ListView(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
          children: [
            AdminPageHeader(
              title: 'Reviews',
              subtitle: 'Customer reviews across every product, newest first.',
            ),
            const SizedBox(height: 20),
            _RatingFilter(
              selected: _ratingFilter,
              onChanged: (value) => setState(() => _ratingFilter = value),
            ),
            const SizedBox(height: 16),
            if (snapshot.hasError)
              _ErrorCard(
                message: _errorMessage(snapshot.error),
                onRetry: _retry,
              )
            else if (loading)
              _timedOut
                  ? _TimeoutCard(onRetry: _retry)
                  : const AdminCard(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    )
            else if (reviews.isEmpty)
              AdminEmptyState(
                icon: Icons.star_outline,
                title: all.isEmpty ? 'No reviews yet' : 'No matching reviews',
                message: all.isEmpty
                    ? 'Reviews submitted in the LUNTI app appear here in real time.'
                    : 'Try a different star rating.',
              )
            else
              AdminCard(
                padding: EdgeInsets.zero,
                child: AdminDataTable(
                  columns: const [
                    AdminTableColumn('Product'),
                    AdminTableColumn('Customer'),
                    AdminTableColumn('Rating'),
                    AdminTableColumn('Comment'),
                    AdminTableColumn('Date'),
                    AdminTableColumn('Actions'),
                  ],
                  rows: [
                    for (final review in reviews)
                      AdminTableRow([
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 190),
                          child: Text(
                            review.productName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 170),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                review.userName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                review.userId,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AdminColors.muted,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _Stars(rating: review.rating),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: Text(
                            review.text,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 130),
                          child: Text(
                            formatDate(review.createdAt),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton.icon(
                              onPressed: () => _toggleModerated(review),
                              icon: Icon(
                                review.moderated
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 16,
                              ),
                              label: Text(
                                review.moderated ? 'Unmute' : 'Moderate',
                              ),
                            ),
                            IconButton(
                              tooltip: 'Delete review',
                              onPressed: () => _delete(review),
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: AdminColors.danger,
                              ),
                            ),
                          ],
                        ),
                      ]),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _toggleModerated(AdminReview review) async {
    try {
      await _database.setReviewModerated(review, moderated: !review.moderated);
      if (!mounted) return;
      _showMessage(
        review.moderated
            ? 'Review restored to the shop.'
            : 'Review hidden from the shop.',
      );
    } catch (_) {
      if (!mounted) return;
      _showMessage('Could not update the review. Please try again.');
    }
  }

  Future<void> _delete(AdminReview review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete review?'),
        content: Text(
          'The review by ${review.userName} on "${review.productName}" will be '
          'permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AdminColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _database.deleteReview(review);
      if (!mounted) return;
      _showMessage('Review deleted.');
    } catch (_) {
      if (!mounted) return;
      _showMessage('Could not delete the review. Please try again.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

/// All + 5/4/3/2/1 star filter chips.
class _RatingFilter extends StatelessWidget {
  const _RatingFilter({required this.selected, required this.onChanged});

  final int? selected;
  final ValueChanged<int?> onChanged;

  static const _options = <int?>[null, 5, 4, 3, 2, 1];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        for (final option in _options)
          _FilterChip(
            label: option == null ? 'All' : '$option Stars',
            selected: selected == option,
            onTap: () => onChanged(option),
          ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AdminColors.sage : AdminColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AdminColors.sage : AdminColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AdminColors.ink : AdminColors.text,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Read-only 1-5 star row used in the rating column.
class _Stars extends StatelessWidget {
  const _Stars({required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var star = 1; star <= 5; star++)
          Icon(
            star <= rating ? Icons.star_rounded : Icons.star_border_rounded,
            size: 18,
            color: star <= rating ? AdminColors.warning : AdminColors.muted,
          ),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Could not load reviews',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(color: AdminColors.muted, fontSize: 12),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try again'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Shown when the initial load runs past [_ReviewsPageState._loadTimeout].
class _TimeoutCard extends StatelessWidget {
  const _TimeoutCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Still loading reviews',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'This is taking longer than expected. Reviews may still be syncing, '
            'or the Firestore collection-group index for `reviews` has not '
            'been created yet.',
            style: TextStyle(
              color: AdminColors.muted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
