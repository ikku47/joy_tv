import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class EmptyState extends StatelessWidget {
  final String query;
  const EmptyState({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 44, color: Colors.white.withOpacity(0.2)),
            const SizedBox(height: 14),
            Text(
              query.isEmpty ? 'No channels found' : 'No results for "$query"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        color: AppTheme.primaryColor,
      ),
    );
  }
}

class ComingSoon extends StatelessWidget {
  const ComingSoon({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.construction_rounded,
            size: 40, color: Colors.white.withOpacity(0.18)),
        const SizedBox(height: 12),
        Text(
          'Coming soon',
          style: TextStyle(
            fontSize: 15,
            color: Colors.white.withOpacity(0.35),
          ),
        ),
      ],
    );
  }
}
