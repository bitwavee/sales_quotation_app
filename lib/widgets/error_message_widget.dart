import 'package:flutter/material.dart';

class ErrorMessageWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final Color backgroundColor;
  final Color textColor;

  const ErrorMessageWidget({
    Key? key,
    required this.message,
    this.onRetry,
    this.backgroundColor = const Color(0xFFFF6B6B),
    this.textColor = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: backgroundColor),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: backgroundColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: backgroundColor),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}
