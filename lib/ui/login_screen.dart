import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login Jabat Kopi')),
      body: Column(
        children: [
          const TextField(decoration: InputDecoration(labelText: 'Username')),
          const TextField(decoration: InputDecoration(labelText: 'Password'), obscureText: true),
          ElevatedButton(
            onPressed: () {},
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }
}
