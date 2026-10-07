import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'role_gate.dart'; // <--- เพิ่มบรรทัดนี้เพื่อเรียกใช้ RoleGate

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        // ถ้าล็อกอินแล้ว ให้ไปสแกนบทบาทผู้ใช้ที่ RoleGate
        if (snapshot.hasData && snapshot.data != null) {
          return RoleGate(user: snapshot.data!);
        }

        // ถ้ายังไม่ล็อกอิน ให้ไปหน้า Login
        return const LoginScreen();
      },
    );
  }
}