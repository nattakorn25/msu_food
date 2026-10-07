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
} catch (e) {
  print("Firebase initialize error or already initialized: $e");
}
  // เตรียม GoogleSignIn ให้พร้อม ต้องทำก่อนเรียก authenticate()
  await AuthService.init(kServerClientId);

  runApp(const MsuFoodApp());
}

class MsuFoodApp extends StatelessWidget {
  const MsuFoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MSU Food',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF0F6E6E),
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
      home: const AuthGate(),
    );
  }
}