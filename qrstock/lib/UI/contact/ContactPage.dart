import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../themes/Colors.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  _ContactPageState createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  // Funtion to send mails using API
  Future<void> _sendEmail() async {
    if (_formKey.currentState!.validate()) {
      try {
        final url = Uri.parse(
          'https://apiemail-production-961d.up.railway.app/send-email',
        );

        final response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "name": _nameController.text,
            "email": _emailController.text,
            "message": _messageController.text,
          }),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Mail sent successfully")));
          _nameController.clear();
          _emailController.clear();
          _messageController.clear();
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Error: ${response.body}")));
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backGreen,
      body: Column(
        children: [
          SizedBox(height: 20),
          Expanded(
            child: Center(
              child: Container(
                width: 700,
                height: 455,
                decoration: BoxDecoration(
                  border: Border.all(color: Color.fromRGBO(178, 229, 178, 1)),
                  borderRadius: BorderRadius.circular(10),
                  color: darkGreen,
                ),
                padding: EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'CONTACT US',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: blue,
                        ),
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: white,
                          labelText: "Name",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 10,
                          ),
                        ),
                        validator:
                            (value) =>
                                value!.isEmpty ? "Enter your name" : null,
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: white,
                          labelText: "Email",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 10,
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator:
                            (value) =>
                                value!.contains("@")
                                    ? null
                                    : "Enter a valid email",
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: white,
                          labelText: "Message",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.message),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 10,
                          ),
                        ),
                        maxLines: 4,
                        validator:
                            (value) =>
                                value!.isEmpty ? "Enter your message" : null,
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _sendEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          foregroundColor: white,
                        ),
                        child: Text("Send Message"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
