import 'package:flutter/material.dart';
// import 'package:geosociomap/pages/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geosociomap/components/toast.dart';
// import 'package:google_fonts/google_fonts.dart';
import 'package:geosociomap/components/components.dart';
import 'package:geosociomap/constants.dart';
import 'package:geosociomap/screens/forgotpassword_screen.dart';
import 'package:geosociomap/screens/signup_screen.dart';
import 'package:geosociomap/screens/Verify_screen.dart';
import 'package:geosociomap/screens/Home_screen.dart';
import 'package:geosociomap/user_auth/firebase_auth_implement/firebase_auth_service.dart';
import 'package:geosociomap/mongodb.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final FirebaseAuthService _auth = FirebaseAuthService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final MongoDBService mongoDBService = MongoDBService();

  late String _email;
  late String _password;
  final bool _saving = false;

  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  // final _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          
          Container(
            height: MediaQuery.of(context).size.height * 0.53,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                    'assets/images/image.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
 
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 500,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'เข้าสู่ระบบ',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF699BF7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const SizedBox(height: 20),
                
                  Align(
                      child: CustomTextField(
                    labelText: 'Email',
                    controller: _emailController,
                    icon: const Icon(Icons.email, color: Color(0xFF699BF7)),
                    textField: TextField(
                        onChanged: (value) {
                          _email = value;
                        },
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                        decoration:
                            kTextInputDecoration.copyWith(hintText: 'Email')),
                  )),
                  const SizedBox(height: 15),
                
                  Align(
                      child: CustomTextField(
                    labelText: 'รหัสผ่าน',
                    controller: _passwordController,
                    icon: const Icon(Icons.lock, color: Color(0xFF699BF7)),
                    obscureText: true,
                    textField: TextField(
                      obscureText: true,
                      onChanged: (value) {
                        _password = value;
                      },
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                      decoration:
                          kTextInputDecoration.copyWith(hintText: 'รหััสผ่าน'),
                    ),
                  )),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 400,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const ForgotpasswordScreen()),
                          );
                        },
                        child: const Text(
                          'ลืมรหัสผ่าน',
                          style: TextStyle(
                            color: Color.fromARGB(255, 129, 171, 251), 
                            fontSize: 14, 
                            fontWeight: FontWeight.bold, 
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                      child: GestureDetector(
                    onTap: _signIn,
                    child: Container(
                      width: 400,
                      height: 45,
                      decoration: BoxDecoration(
                        color: const Color(0xFF699BF7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 5,
                            ),
                            Text(
                              "เข้าสู่ระบบ",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )),
                  const SizedBox(height: 10),
          
                  Align(
                    alignment: Alignment.center,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SignUpScreen()),
                        );
                      },
                      child: const Text(
                        'ยังไม่มีบัญชีผู้ใช้ ? ลงทะเบียน',
                        style: TextStyle(
                          color: Color.fromARGB(255, 129, 171, 251),
                          fontSize: 14, 
                          fontWeight: FontWeight.bold, 
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signIn() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        await user.reload();
        user = FirebaseAuth.instance.currentUser;

        if (user != null && !user.emailVerified) {
          showToast(message: 'Please verify your email before signing in.');

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VerifyScreen(
                email: email,
                password: password,
              ),
            ),
          );
          // await FirebaseAuth.instance.signOut();
        } else {
          // await mongoDBService.connect();
          // await mongoDBService.insertData(user!.uid, email);
          // await mongoDBService.closeConnection();

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          ); 
        }
      }
    } catch (e) {
   
      showToast(
          message: 'Failed to sign in. Please check your email and password.');
    }
  }
}
