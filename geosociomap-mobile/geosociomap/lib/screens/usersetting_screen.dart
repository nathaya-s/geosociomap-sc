import 'package:flutter/material.dart';
import 'package:geosociomap/components/components.dart';
import 'package:geosociomap/screens/signin_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geosociomap/components/toast.dart';
import 'package:geosociomap/mongodb.dart';
import 'package:geosociomap/screens/auth_screen.dart';

class UserSettingsScreen extends StatefulWidget {
  const UserSettingsScreen({super.key});

  @override
  State<UserSettingsScreen> createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends State<UserSettingsScreen> {
  bool _isProcessing = false;
  // final MongoDBService mongoDBService = MongoDBService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text(
            'ตั้งค่าบัญชี',
            style: GoogleFonts.sarabun(
              textStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      showLogoutDialog(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        side: BorderSide(
                          color: Colors.lightBlue.shade700,
                          width: 1.0,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12.0,
                      ),
                    ),
                    child: Text(
                      'ออกจากระบบ',
                      style: GoogleFonts.sarabun(
                        textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _showDeleteAccountDialog(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        side: const BorderSide(
                          color: Colors.red,
                          width: 1.0,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12.0,
                      ),
                    ),
                    child: Text(
                      'ลบบัญชีผู้ใช้',
                      style: GoogleFonts.sarabun(
                        textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  void showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0), 
          ),
          title: Text(
            'ออกจากระบบ',
            style: GoogleFonts.sarabun(
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          content: Text(
            'คุณแน่ใจหรือไม่ว่าต้องการออกจากระบบ',
            style: GoogleFonts.sarabun(
              textStyle: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); 
              },
              child: Text(
                'ยกเลิก',
                style: GoogleFonts.sarabun(
                  textStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.lightBlue.shade700),
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const SigninScreen()),
                );
              },
              child: Text(
                'ยืนยัน',
                style: GoogleFonts.sarabun(
                  textStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.lightBlue.shade700),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'ลบบัญชีผู้ใช้',
            style: GoogleFonts.sarabun(
              textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black),
            ),
          ),
          content: Container(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'คุณแน่ใจว่าต้องการลบบัญชีของคุณใช่หรือไม่?',
                  style: GoogleFonts.sarabun(
                    textStyle: const TextStyle(fontSize: 14, color: Colors.black),
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextInput(
                  labelText: "รหัสผ่าน",
                  controller: _passwordController,
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); 
              },
              child: Text(
                'ยกเลิก',
                style: GoogleFonts.sarabun(
                  textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                _deleteAccount();
              },
              child: Text(
                'ยืนยัน',
                style: GoogleFonts.sarabun(
                  textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount() async {
    final User? user = _auth.currentUser;
    if (user == null) return;
    final MongoDBService mongoDBService = MongoDBService();

    setState(() {
      _isProcessing = true;
    });

    try {
      final AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _passwordController.text,
      );

      await user.reauthenticateWithCredential(credential);
      await user.delete();
      await mongoDBService.deleteUser(user.uid);

      showToast(message: 'Account deleted successfully');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const AuthPage()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      
      showToast(message: 'Failed to delete account: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
}
