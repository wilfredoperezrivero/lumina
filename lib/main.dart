import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Removed page imports moved to router.dart

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  // Listen for incoming links for password reset
  final initialLink = await getInitialLink();
  if (initialLink != null && initialLink.contains('type=recovery')) {
    runApp(
        const ProviderScope(child: LuminaApp(initialRoute: '/reset-password')));
    return;
  }
  runApp(const ProviderScope(child: LuminaApp()));
}

class LuminaApp extends ConsumerWidget {
  final String? initialRoute;
  const LuminaApp({super.key, this.initialRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Lumina',
      routerConfig: buildRouter(initialRoute),
    );
  }
}
