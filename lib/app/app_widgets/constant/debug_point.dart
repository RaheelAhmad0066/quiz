import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart' as foundation;

class DebugPoint {
  static final _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      // ignore: deprecated_member_use
      printTime: false,
    ),
  );

  static log(dynamic value) {
    if (foundation.kDebugMode) {
      _logger.i(value);
    }
  }

  static error(dynamic value) {
    if (foundation.kDebugMode) {
      _logger.e(value);
    }
  }

  static warning(dynamic value) {
    if (foundation.kDebugMode) {
      _logger.w(value);
    }
  }

  static debug(dynamic value) {
    if (foundation.kDebugMode) {
      _logger.d(value);
    }
  }
}

// import 'package:get/get.dart';
// import 'package:flutter/foundation.dart' as foundation;

// class DebugPoint {
//   static log(dynamic value) {
//     if (foundation.kDebugMode) {
//       Get.log("$value");
//     }
//   }
// }
