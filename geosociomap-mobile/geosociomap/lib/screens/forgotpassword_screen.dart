import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geosociomap/components/components.dart';
import 'package:geosociomap/components/toast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geosociomap/constants.dart';
import 'package:flutter/foundation.dart' show kIsWeb;


class ForgotpasswordScreen extends StatefulWidget {
  const ForgotpasswordScreen({super.key});

  @override
  State<ForgotpasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotpasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  late String _email;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: kIsWeb ? null : AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: kIsWeb ? Container(
          color: Colors.white,
          child:  Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'ตั้งค่ารหัสผ่านใหม่',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.lightBlue[700],
              ),
            ),
            const Text(
              'กรอกอีเมลของคุณเพื่อขอรับลิงก์รีเซ็ตรหัสผ่าน',
            ),
            const SizedBox(height: 24),
            CustomTextField(
              icon: Icon(Icons.email, color: Colors.lightBlue.shade700),
              labelText: 'Email',
              textField: TextField(
                  onChanged: (value) {
                    _email = value;
                  },
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                  decoration: kTextInputDecoration.copyWith(hintText: 'Email')),
              controller: _emailController,
          
            ),
            const SizedBox(height: 24),
            Center(
                child: SizedBox(
              width: 400,
              child: ElevatedButton(
                onPressed: () {
                  _sendPasswordResetEmail(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlue.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0), 
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12.0,
                  ), 
                ),
                child: Text(
                  'ยืนยัน',
                  style: GoogleFonts.sarabun(
                    textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white),
                  ),
                ),
              ),
            ))
          ],
        ),
      ),
    ) : Container(
          color: Colors.white,
          
          child:  Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ตั้งค่ารหัสผ่านใหม่',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.lightBlue[700],
              ),
            ),
            const Text(
              'กรอกอีเมลของคุณเพื่อขอรับลิงก์รีเซ็ตรหัสผ่าน',
            ),
            const SizedBox(height: 24),
            CustomTextField(
              icon: Icon(Icons.email, color: Colors.lightBlue.shade700),
              labelText: 'Email',
              textField: TextField(
                  onChanged: (value) {
                    _email = value;
                  },
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                  decoration: kTextInputDecoration.copyWith(hintText: 'Email')),
              controller: _emailController,
           
            ),
            const SizedBox(height: 24),
            Center(
                child: SizedBox(
              width: 400,
              child: ElevatedButton(
                onPressed: () {
                  _sendPasswordResetEmail(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlue.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12.0,
                  ), 
                ),
                child: Text(
                  'ยืนยัน',
                  style: GoogleFonts.sarabun(
                    textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white),
                  ),
                ),
              ),
            ))
          ],
        ),
      ),
    ));
  }

  void _sendPasswordResetEmail(BuildContext context) async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      showToast(message: 'Please enter your email address.');
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      showToast(
        message: 'Password reset email sent!',
      );
      Navigator.of(context).pop();
      _emailController.clear();
    } catch (e) {
      showToast(
        message: 'Failed to send password reset email. Please try again.',
      );
    }
  }

  
}

