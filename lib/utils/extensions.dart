import 'package:intl/intl.dart';

extension StringDateExtensions on String? {
  String? get releaseYear {
    if (this == null) return null;
    final value = this!.trim();
    if (value.isEmpty) return null;

    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed.year.toString();

    final yearMatch = RegExp(r'^(\d{4})').firstMatch(value);
    return yearMatch?.group(1);
  }

  String asFullDate({String fallback = 'Unknown Date'}) {
    if (this == null) return fallback;
    final value = this!.trim();
    if (value.isEmpty) return fallback;

    final parsed = DateTime.tryParse(value);
    if (parsed != null) return DateFormat('MMM d, yyyy').format(parsed);

    return value;
  }
}
