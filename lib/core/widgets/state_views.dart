import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Shared loading state — every async screen renders this while fetching.
class LoadingView extends StatelessWidget {
  final String message;
  const LoadingView({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.rainCyan),
          const SizedBox(height: AppSpacing.xxl),
          Text(message, style: AppTypography.label(size: 12)),
        ],
      ),
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
