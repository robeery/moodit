
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'viewmodel/home_viewmodel.dart';
import 'view/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  // Keep the status bar icons white. Without an AppBar nothing sets this, so
  // the platform default would draw dark icons.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  ));
  await dotenv.load(fileName: '.env');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    this.homeViewModel,
  });

  final HomeViewModel? homeViewModel;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mood Edit',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      builder: (context, child) {
        // Reapplies the light style every frame. The imperative call in main()
        // gets overridden by the framework on Android 15+ edge-to-edge.
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          child: child!,
        );
      },
      home: HomeScreen(viewModel: homeViewModel),
    );
  }
}
