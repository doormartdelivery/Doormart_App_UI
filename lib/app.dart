import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/routes.dart';
import 'core/theme.dart';
import 'providers/app_state.dart';
import 'features/delivery/providers/delivery_provider.dart';
import 'views/user/splash_screen.dart';

class DoormartDeliveryApp extends StatelessWidget {
  const DoormartDeliveryApp({super.key});

  static final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState()..bootstrap(),
      child: ChangeNotifierProvider(
        create: (_) => DeliveryProvider(),
        child: Consumer<AppState>(
          builder: (context, state, child) => MaterialApp(
            title: 'Doormart Delivery',
            debugShowCheckedModeBanner: false,
            scaffoldMessengerKey: scaffoldMessengerKey,
            theme: AppTheme.lightTheme,
            initialRoute: SplashScreen.routeName,
            onGenerateRoute: (settings) =>
                AppRoutes.onGenerateRoute(context, settings),
          ),
        ),
      ),
    );
  }
}
