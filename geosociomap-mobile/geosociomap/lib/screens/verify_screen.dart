import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geosociomap/screens/home_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geosociomap/components/toast.dart';
import 'package:geosociomap/mongodb.dart';

class VerifyScreen extends StatefulWidget {
  final String email;
  final String password;

  const VerifyScreen({super.key, required this.email, required this.password});

  @override
  _VerifyScreenScreenState createState() => _VerifyScreenScreenState();
}

class _VerifyScreenScreenState extends State<VerifyScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final MongoDBService mongoDBService = MongoDBService();
  User? user;
  bool isVerified = false;

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
    _checkEmailVerification();
  }

  @override
  Widget build(BuildContext context) {
    String email = widget.email ?? 'default@example.com';

    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        body: Container(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Image Placeholder
                SizedBox(
                  height: 150,
                  width: 150,
                  child: Icon(Icons.email,
                      size: 100, color: Colors.lightBlue.shade700),
                ),
                const SizedBox(height: 20),
                Text(
                  'กรุณายืนยันอีเมลของคุณ',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.lightBlue.shade700,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'We sent a confirmation email to:',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.email,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Check your email and click on the confirmation link to continue.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                Center(
                    child: SizedBox(
                  width: 400,
                  child: ElevatedButton(
                    onPressed: () async {
                      await _sendVerificationEmail(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(8.0), // Rounded corners
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12.0,
                      ), // Padding inside the button
                    ),
                    child: Text(
                      'ส่งอีกครั้ง',
                      style: GoogleFonts.prompt(
                        textStyle: const TextStyle(
                            fontSize: 16,
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

  Future<void> _checkEmailVerification() async {
    while (!user!.emailVerified) {
      await user!.reload();
      user = _auth.currentUser;
      await Future.delayed(const Duration(seconds: 2));
    }
    // await mongoDBService.connect();
    print("insertData : Start");
    try {
      await mongoDBService.insertData(user!.uid, widget.email);
    } catch (e) {
      print('Error during email verification: $e');
    
    }
    // await mongoDBService.closeConnection();
    print("insertData : Done");
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  Future<void> _sendVerificationEmail(BuildContext context) async {
    User? user = _auth.currentUser;

    if (user == null) {
      showToast(message: 'User is not logged in. Please log in first.');
      return;
    }

    try {
      if (!user.emailVerified) {
        await user.sendEmailVerification();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent!'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your email is already verified.'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send verification email. Please try again.'),
        ),
      );
    }
  }
}
