import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'routes/app_router.dart';
import 'services/firebase_service.dart';
import 'styles/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pre-warm Google Fonts runtime caching
  GoogleFonts.config.allowRuntimeFetching = true;

  // Initialize Firebase live connection
  await FirebaseService.initialize();

  runApp(
    const ProviderScope(
      child: EduSphereApp(),
    ),
  );
}

class EduSphereApp extends ConsumerWidget {
  const EduSphereApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'EduSphere',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
