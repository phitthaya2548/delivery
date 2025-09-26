import 'dart:io';

import 'package:deliveryrpoject/pages/login.dart';
import 'package:deliveryrpoject/pages/rider/widgets/bottom_rider.dart';
import 'package:deliveryrpoject/pages/sesstionstore.dart';
import 'package:deliveryrpoject/pages/user/widgets/bottom_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
 
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Color(0xFFFD8700),
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Delivery Project',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        textTheme: GoogleFonts.promptTextTheme(),
      ),
      home: const SplashBootstrap(),
    );
  }
}

class SplashBootstrap extends StatefulWidget {
  const SplashBootstrap({super.key});
  @override
  State<SplashBootstrap> createState() => _SplashBootstrapState();
}

class _SplashBootstrapState extends State<SplashBootstrap> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.delayed(const Duration(milliseconds: 200));

    final auth = SessionStore.getAuth();
    if (auth != null) {
      final role = auth['role'] as String?;
      if (role == 'RIDER') {
        Get.offAll(() => BottomRider());
      } else {
        Get.offAll(() => BottomUser());
      }
    } else {
      Get.offAll(() => const Login());
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
