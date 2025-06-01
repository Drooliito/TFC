import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qrstock/themes/colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;

  Future<void> _loginWithEmail(BuildContext context) async {
    try {
      // Login Firebase
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      String error;
      switch (e.code) {
        case 'missing-email':
          error = 'Enter the email.';
          break;
        case 'too-many-requests':
          error = 'Too many failed attempts. Please try again later.';
          break;
        default:
          error = 'Failed to log in. Please try again.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), duration: Duration(seconds: 2)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backGreen,
      appBar: AppBar(
        leading: Icon(Icons.qr_code),
        title: const Text('QRStock'),
        backgroundColor: barGreen,
        titleTextStyle: TextStyle(
          color: black,
          fontWeight: FontWeight.bold,
          fontSize: 18.0,
        ),
        titleSpacing: -15,
      ),
      body: Container(
        child: Column(
          children: [
            SizedBox(height: 20),

            Expanded(
              child: Center(
                child: Container(
                  width: 300,
                  decoration: BoxDecoration(
                    border: Border.all(color: Color.fromRGBO(178, 229, 178, 1)),
                    borderRadius: BorderRadius.circular(10),
                    color: darkGreen,
                  ),
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'LOGIN',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: blue,
                        ),
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: white,
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 10,
                          ),
                        ),
                        onSubmitted: (_) => _loginWithEmail(context),
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: white,
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureText
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureText = !_obscureText;
                              });
                            },
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 10,
                          ),
                        ),
                        obscureText: _obscureText,
                        onSubmitted: (_) => _loginWithEmail(context),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => _loginWithEmail(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          foregroundColor: white,
                        ),
                        child: const Text('Login'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
