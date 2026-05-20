import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/bootstrap_app.dart';
import 'core/debug_log.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    logDebug('FlutterError: ${details.exceptionAsString()}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    logDebug('Uncaught: $error\n$stack');
    return true;
  };

  runApp(const ProviderScope(child: BootstrapApp()));
}
