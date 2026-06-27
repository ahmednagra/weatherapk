import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Shared loading state — shimmer skeleton cards plus a status label.
class LoadingView extends StatelessWidget {
  final String message;
  const LoadingView({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl, AppSpacing.xxl, AppSpacing.xxl, AppSpacing.xxl),
      children: [
        Center(child: Text(message, style: AppTypography.label(size: 12))),
        const SizedBox(height: AppSpacing.xxl),
        for (var i = 0; i < 4; i++) ...[
          const _SkeletonCard(),
          const SizedBox(height: AppSpacing.xl),
        ],
      ],
    );
  }
}

/// A single shimmering placeholder card.
class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.cardBorder),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 1200.ms,
          color: AppColors.rainCyan.withOpacity(AppSpacing.opacityLight),
        );
  }
}

/// Shared error state with a retry affordance.
class ErrorView extends StatelessWidget {
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;
  const ErrorView({
    super.key,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off, color: AppColors.textMuted, size: 40),
          const SizedBox(height: AppSpacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(message,
                textAlign: TextAlign.center,
                style: AppTypography.label(size: 11)),
          ),
          const SizedBox(height: AppSpacing.xxl),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.rainCyan,
                foregroundColor: AppColors.bg),
            onPressed: onRetry,
            child: Text(retryLabel),
          ),
        ],
      ),
    );
  }
}

/// Shared empty state for sections with no data to show.
class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  const EmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.textFaint, size: 32),
          const SizedBox(height: AppSpacing.xl),
          Text(message, style: AppTypography.label(size: 11)),
        ],
      ),
    );
  }
}
