import 'package:flutter/foundation.dart';

/// Thrown when a network feature cannot get data. [message] is user-facing.
class ServiceException implements Exception {
  const ServiceException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Identifies the app to the free community APIs, as their usage policies ask.
/// Browsers forbid setting this header, so it is skipped on the web.
Map<String, String> get apiHeaders =>
    kIsWeb ? const {} : const {'User-Agent': 'Ghumo/1.0 (github.com/umar2334/Ghumo)'};
