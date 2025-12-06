import 'package:cc98_ocean/controls/clickarea.dart';
import 'package:flutter/material.dart';

class StatusTitle extends StatelessWidget {
  final String title;
  final bool isLoading;
  final VoidCallback? onTap;

  const StatusTitle({
    Key? key,
    required this.title,
    this.onTap,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClickArea(
      onTap: onTap,
      child: Row(
        spacing: 12,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          if (isLoading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
        ],
      ),
    );
  }
}