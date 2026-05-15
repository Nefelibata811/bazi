import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import 'app/app.dart';
import 'features/auth/application/auth_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final hash = html.window.location.hash ?? '';
  final fragment = Uri.base.fragment;
  if (hash.contains('type=recovery') || fragment.contains('type=recovery')) {
    markPendingPasswordRecovery();
  }

  await Supabase.initialize(
    url: 'https://iczcdybxotqzwatyvqdm.supabase.co',
    anonKey: 'sb_publishable_C1tZZqL3i-HYl3D-a8-6uA_DyzgVgV6',
  );

  runApp(const BaziApp());
}
