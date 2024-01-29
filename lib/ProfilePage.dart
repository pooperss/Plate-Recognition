import 'package:flutter/material.dart';

import 'LoginPage.dart';

class ProfilePage extends StatelessWidget {
  final String? username;
  final String? Name;
  final String? Auth;

  ProfilePage({this.username, this.Name, this.Auth});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              'Welcome, $Name!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Card(
              child: ListTile(
                title: Text('Username'),
                subtitle: Text('$username'),
                leading: Icon(Icons.person),
              ),
            ),
            Card(
              child: ListTile(
                title: Text('Authentication Status'),
                subtitle: Text('$Auth'),
                leading: Icon(Icons.verified_user),
              ),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => LoginPage()),
                (Route<dynamic> route) => false,
              ),
              child: Text('Logout'),
              style: ElevatedButton.styleFrom(primary: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
