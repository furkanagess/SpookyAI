import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/home/presentation/pages/splash_page.dart';
import 'package:provider/provider.dart';
import 'core/services/saved_images_provider.dart';
import 'core/services/token_provider.dart';
import 'core/services/in_app_purchase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize in-app purchase service
  await InAppPurchaseService.initialize();

  runApp(const GhostfaceApp());
}

class GhostfaceApp extends StatelessWidget {
  const GhostfaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SavedImagesProvider()..load()),
        ChangeNotifierProvider(create: (_) => TokenProvider()..loadBalance()),
      ],
      child: MaterialApp(
        title: 'SpookyAI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const SplashPage(),
      ),
    );
  }
}
