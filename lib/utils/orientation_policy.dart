import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'log_util.dart';

class OrientationPolicy {
  static const double _handheldBreakpoint = 600;

  static bool isHandheld(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide < _handheldBreakpoint;
  }

  static Future<void> enterPlayback({String source = 'unknown'}) {
    logI('enterPlayback from $source -> landscape', tag: 'Orientation');
    return SystemChrome.setPreferredOrientations(
      const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ],
    );
  }

  static Future<void> restoreAfterPlayback({
    required bool isHandheldDevice,
    String source = 'unknown',
  }) {
    if (isHandheldDevice) {
      logI('restoreAfterPlayback from $source -> portrait', tag: 'Orientation');
      return SystemChrome.setPreferredOrientations(
        const [
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ],
      );
    }

    logI('restoreAfterPlayback from $source -> landscape', tag: 'Orientation');
    return SystemChrome.setPreferredOrientations(
      const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ],
    );
  }
}
