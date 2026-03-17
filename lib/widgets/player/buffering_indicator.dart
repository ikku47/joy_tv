import 'package:flutter/material.dart';

class BufferingIndicator extends StatelessWidget {
  const BufferingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Loading stream…',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.45),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
