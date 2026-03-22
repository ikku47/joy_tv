import 'package:flutter/material.dart';
import 'package:dpad/dpad.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const JoyTVApp());
}

class JoyTVApp extends StatelessWidget {
  const JoyTVApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DpadNavigator(
      enabled: true,
      child: MaterialApp(
        title: 'Joy TV',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const HomeScreen(),
      ),
    );
  }
}
