extension StringExtensions on String? {
  bool get isNullOrEmpty => this == null || this!.trim().isEmpty;
  bool get isNotNullOrEmpty => !isNullOrEmpty;

  String orDefault([String defaultValue = '']) =>
      isNullOrEmpty ? defaultValue : this!;
}

extension MapExtensions on Map<String, dynamic>? {
  String getString(String key, [String defaultValue = '']) =>
      (this?[key]?.toString() ?? defaultValue);

  int getInt(String key, [int defaultValue = 0]) {
    final val = this?[key];
    if (val is int) return val;
    if (val is double) return val.toInt();
    if (val is String) return int.tryParse(val) ?? defaultValue;
    return defaultValue;
  }

  double getDouble(String key, [double defaultValue = 0.0]) {
    final val = this?[key];
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? defaultValue;
    return defaultValue;
  }

  bool getBool(String key, [bool defaultValue = false]) {
    final val = this?[key];
    if (val is bool) return val;
    if (val is String) return val.toLowerCase() == 'true';
    return defaultValue;
  }
}
