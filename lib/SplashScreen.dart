import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'GoogleSignInPage.dart';

class SplashScreen extends StatefulWidget {
  final CameraDescription camera;

  SplashScreen({Key? key, required this.camera}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(
      Duration(seconds: 3),
      () => Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (BuildContext context) =>
              GoogleSignInPage(camera: widget.camera),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset(
              'images/P.png',
              width: 200,
              height: 200,
            ),
          ],
        ),
      ),
    );
  }
}
