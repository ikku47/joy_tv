import 'dart:convert';
import 'dart:developer' as dev;

const bool inProduction = bool.fromEnvironment('dart.vm.product');

void logD(String msg, {String tag = 'App'}) {
  if (inProduction) return;
  dev.log(msg, name: tag);
}

void logI(String msg, {String tag = 'App'}) {
  if (inProduction) return;
  dev.log(msg, name: tag);
}

void logW(String msg, {String tag = 'App'}) {
  if (inProduction) return;
  dev.log('WARN: $msg', name: tag);
}

void logE(
  String msg, {
  String tag = 'App',
  Object? error,
  StackTrace? stackTrace,
}) {
  if (inProduction) return;
  dev.log(msg, name: tag, error: error, stackTrace: stackTrace);
}

String? fmtJson(dynamic value) {
  try {
    return const JsonEncoder.withIndent('  ').convert(value);
  } catch (_) {
    return null;
  }
}

void logJson(
  String label,
  dynamic raw, {
  String tag = 'App',
  int chunkSize = 1800,
}) {
  if (inProduction) return;

  String jsonString;
  if (raw is String) {
    jsonString = raw;
  } else {
    try {
      jsonString = jsonEncode(raw);
    } catch (_) {
      jsonString = raw?.toString() ?? '';
    }
  }

  String output = jsonString;
  try {
    output = fmtJson(jsonDecode(jsonString)) ?? jsonString;
  } catch (_) {
    output = jsonString;
  }

  final totalChunks = (output.length / chunkSize).ceil();
  logD('$label: length=${output.length}, chunks=$totalChunks', tag: tag);

  for (var i = 0; i < output.length; i += chunkSize) {
    final end = (i + chunkSize < output.length) ? i + chunkSize : output.length;
    final chunkIndex = (i ~/ chunkSize) + 1;
    logD('$label: chunk $chunkIndex/$totalChunks\n${output.substring(i, end)}', tag: tag);
  }
}
