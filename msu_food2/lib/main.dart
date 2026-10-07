import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/auth_gate.dart';
import 'services/auth_service.dart';

// นำค่านี้มาจาก Firebase Console ตามข้อ 3.6
const String kServerClientId =
    '433426198932-f3uqe77kipa9v1rdiopj15s0u19t8a43.apps.googleusercontent.com';

Future<void> main() async {
  // เตรียมส่วนเชื่อมต่อกับระบบปฏิบัติการให้พร้อม
  // จำเป็นเมื่อต้องเรียกโค้ดฝั่ง Native ก่อน runApp() จะทำงาน
  WidgetsFlutterBinding.ensureInitialized();

  // เช็กว่ามีการ Initialize Firebase ไปแล้วหรือยัง ป้องกัน Duplicate App Error
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (error, stackTrace) {
    debugPrint('Firebase initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
    rethrow;
  }
  // เตรียม GoogleSignIn ให้พร้อม ต้องทำก่อนเรียก authenticate()
  await AuthService.init(kServerClientId);

  runApp(const MsuFoodApp());
}

class MsuFoodApp extends StatelessWidget {
  final Widget? home;

  const MsuFoodApp({super.key, this.home});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MSU Food',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFFFDF7),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5D9C91),
          primary: const Color(0xFF5D9C91),
          secondary: const Color(0xFFFFBFA3),
          surface: const Color(0xFFFFFDF7),
          onSurface: const Color(0xFF2D3142),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFFDF7),
          foregroundColor: Color(0xFF2D3142),
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFECE9E1)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFECE9E1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFECE9E1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFF5D9C91), width: 1.5),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        useMaterial3: true,
      ),
      // สามส่วนนี้ทำให้กล่องโต้ตอบมาตรฐานแสดงเป็นภาษาไทย
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('th'), Locale('en')],
      locale: const Locale('th'),
      home: home ?? const AuthGate(),
    );
  }
}
