import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/routes.dart';
import 'core/theme.dart';
import 'providers/app_state.dart';
import 'views/user/user_home_screen.dart';

class DoormartDeliveryApp extends StatelessWidget {
  const DoormartDeliveryApp({super.key});

  static final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState()..bootstrap(),
      child: MaterialApp(
        title: 'Doormart Delivery',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: scaffoldMessengerKey,
        theme: AppTheme.lightTheme,
        initialRoute: UserHomeScreen.routeName,
        routes: AppRoutes.routes,
      ),
    );
  }
}
