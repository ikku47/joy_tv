import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PlayerClock extends StatelessWidget {
  final DateTime now;
  final bool isMobile;

  const PlayerClock({
    super.key,
    required this.now,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          DateFormat('HH:mm').format(now),
          style: TextStyle(
            fontSize: isMobile ? 18 : 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          DateFormat('EEE, dd MMM').format(now),
          style: TextStyle(
            fontSize: isMobile ? 10 : 11,
            color: Colors.white.withOpacity(0.5),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}
