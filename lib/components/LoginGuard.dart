import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ht_app/services/AuthService.dart';

class LoginGuard extends StatefulWidget {
  const LoginGuard({super.key, required this.child});

  final Widget child;

  @override
  State<LoginGuard> createState() => _LoginGuardState();
}

class _LoginGuardState extends State<LoginGuard> {
  final AuthService _firebase = AuthService();
  UserCredential? _credential;

  @override
  void initState() {
    login();
    super.initState();
  }

  void login() async {
    var credential = await _firebase.signInWithGoogle();

    setState(() {
      _credential = credential;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _credential != null
          ? widget.child
          : Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text("Logging in..."),
                    SizedBox(height: 20),
                    CircularProgressIndicator(value: null),
                  ]),
            ),
    );
  }
}
