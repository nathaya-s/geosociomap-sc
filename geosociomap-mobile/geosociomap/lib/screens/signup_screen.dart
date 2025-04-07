import 'package:flutter/material.dart';

// import 'package:geosociomap/screens/home_screen.dart';
import 'package:geosociomap/screens/signin_screen.dart';
import 'package:geosociomap/screens/verify_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geosociomap/user_auth/firebase_auth_implement/firebase_auth_service.dart';
import 'package:geosociomap/components/components.dart';
import 'package:geosociomap/constants.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final FirebaseAuthService _auth = FirebaseAuthService();

  late String _email = '';
  late String _password = '';
  late final String _confirmPass = '';

  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _comfirmpasswordController =
      TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final bool _saving = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _comfirmpasswordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (isPopping) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const SigninScreen()),
          (route) => false,
        );
      },
      child: Scaffold(
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
                      'ลงทะเบียน',
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
                        decoration: kTextInputDecoration.copyWith(
                            hintText: 'รหััสผ่าน'),
                      ),
                    )),
                    const SizedBox(height: 15),
                    Align(
                        child: CustomTextField(
                      labelText: 'ยืนยันรหัสผ่าน',
                      controller: _comfirmpasswordController,
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
                        decoration: kTextInputDecoration.copyWith(
                            hintText: 'ยินยันหััสผ่าน'),
                      ),
                    )),
                    const SizedBox(height: 15),
                    Align(
                        child: GestureDetector(
                      onTap: _signup,
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
                                "ลงทะเบียน",
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
                                builder: (context) => const SigninScreen()),
                          );
                        },
                        child: const Text(
                          'มีบัญชีผู้ใช้แล้ว ? เข้าสู่ระบบ',
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
      ),
    );
  }

  Future<void> _signup() async {
    try {
      User? user = await _auth.createUserWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (user != null) {
        await user.sendEmailVerification();
      
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerifyScreen(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Signup Failed: ${e.toString()}")),
      );
    }
  }
}
