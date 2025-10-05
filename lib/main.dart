import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/home/presentation/pages/splash_page.dart';
import 'package:provider/provider.dart';
import 'core/services/saved_images_provider.dart';
import 'core/services/token_provider.dart';
import 'core/services/main_navigation_provider.dart';
import 'core/services/profile_provider.dart';
import 'core/services/prompts_provider.dart';
import 'core/services/purchase_provider.dart';
import 'core/services/spin_provider.dart';
import 'core/services/stats_provider.dart';
import 'core/services/add_prompt_provider.dart';
import 'core/services/halloween_prompt_provider.dart';
import 'core/services/prompt_input_provider.dart';
import 'core/services/in_app_purchase_service.dart';
import 'core/services/quick_actions_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize in-app purchase service
  await InAppPurchaseService.initialize();

  // Initialize quick actions
  await QuickActionsService.initialize();

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
        ChangeNotifierProvider(create: (_) => MainNavigationProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => PromptsProvider()),
        ChangeNotifierProvider(create: (_) => PurchaseProvider()),
        ChangeNotifierProvider(create: (_) => SpinProvider()),
        ChangeNotifierProvider(create: (_) => StatsProvider()),
        ChangeNotifierProvider(create: (_) => AddPromptProvider()),
        ChangeNotifierProvider(create: (_) => HalloweenPromptProvider()),
        ChangeNotifierProvider(create: (_) => PromptInputProvider()),
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
