import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'GoogleSignInPage.dart';
import 'HomePage.dart';
import 'instructions_page.dart';
import 'setupSheets.dart';
import 'user_data_provider.dart';

class LoginPage extends StatefulWidget {
  final CameraDescription? camera;
  final bool connectionWarning;

  const LoginPage({Key? key, this.camera, this.connectionWarning = false})
      : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isRememberMeChecked = false;
  final storage = FlutterSecureStorage();
  bool _isLoading = false;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _sheetsIdController = TextEditingController();

  String? _authenticatedUsername;
  String? _Name;
  String? _Authorized;

  @override
  void initState() {
    super.initState();
    _loadCredentials();
    _showInstructionsIfNeeded();
  }

  Future<void> _showInstructionsIfNeeded() async {
    await showInstructionsDialog(context);
  }

  Future<void> _loadCredentials() async {
    String? savedUsername = await storage.read(key: 'username');
    String? savedPassword = await storage.read(key: 'password');
    String? savedSheetID = await storage.read(key: 'sheetID');
    if (savedUsername != null &&
        savedPassword != null &&
        savedSheetID != null) {
      setState(() {
        _usernameController.text = savedUsername;
        _passwordController.text = savedPassword;
        _sheetsIdController.text = savedSheetID;
        _isRememberMeChecked = true;
      });
    }
  }

  Future<bool> checkCredentials(String username, String password,
      String spreadsheetId, String accessToken) async {
    if (await Provider.of<UserDataProvider>(context, listen: false)
        .signInSilentlyIfNeeded()) {
      Provider.of<UserDataProvider>(context, listen: false)
          .userData!
          .accessToken;
    }
    final uri = Uri.parse(
        'https://sheets.googleapis.com/v4/spreadsheets/$spreadsheetId/values/Auth(101)');
    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data.containsKey('values') && data['values'] != null) {
        final values = data['values'] as List<dynamic>;

        for (final row in values) {
          if (row.isNotEmpty && row[0] == username && row[1] == password) {
            _authenticatedUsername = username;
            _Name = row[2];
            _Authorized = row[3];
            print('Name:$_Name, Authorization:$_Authorized');
            return true;
          }
        }
      } else {
        print('No values found in the sheet');
      }
    } else {
      print(
          'Failed to retrieve sheet data: ${response.statusCode}, ${response.body}');
    }

    return false;
  }

  Future<void> logout() async {
    await GoogleSignInApi.logout();
    await setLoginState(false); // Update the login state
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => GoogleSignInPage(camera: widget.camera),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.connectionWarning)
                      Container(
                        padding: EdgeInsets.all(16),
                        color: Colors.red,
                        child: Text(
                          "No Internet Connection. Please check your network settings.",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    Text(
                      "Platespot",
                      style: GoogleFonts.satisfy(
                          fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 40),
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: "Username",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Password",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: _sheetsIdController,
                      decoration: InputDecoration(
                        labelText: "Sheets ID",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.insert_drive_file),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 20.0), // Example padding
                      child: CheckboxListTile(
                        title: Text("Remember me"),
                        value: _isRememberMeChecked,
                        onChanged: (bool? value) {
                          setState(() {
                            _isRememberMeChecked = value ?? false;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: Colors.white, // Background color
                        onPrimary: Colors.black, // Text color
                        fixedSize:
                            Size(120.0, 8), // Specific size of the button
                      ),
                      onPressed: () async {
                        setState(() {
                          _isLoading = true; // Start loading
                        });

                        final String username = _usernameController.text;
                        final String password = _passwordController.text;
                        final String spreadsheetId = _sheetsIdController.text;

                        // Retrieve the UserData from the provider
                        UserData? userData = Provider.of<UserDataProvider>(
                                context,
                                listen: false)
                            .userData;

                        if (userData != null) {
                          Provider.of<UserDataProvider>(context, listen: false)
                              .setUserData(
                            UserData(
                              displayName: userData.displayName,
                              accessToken: userData.accessToken,

                              sheetID: spreadsheetId,
                            ),
                          );

                          if (username == 'create' && password == 'create') {
                            // Special setup login
                            String setupResult =
                                await setupSheets(userData, spreadsheetId);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('$setupResult')),
                            );
                          } else {
                            bool credentialsValid = await checkCredentials(
                              username,
                              password,
                              spreadsheetId,
                              userData.accessToken,
                            );
                            final cameras = await availableCameras();
                            if (credentialsValid) {
                              if (_isRememberMeChecked) {
                                await storage.write(
                                    key: 'username', value: username);
                                await storage.write(
                                    key: 'password', value: password);
                                await storage.write(
                                    key: 'sheetID', value: spreadsheetId);
                              }
                              else {
                                await storage.delete(key: 'username');
                                await storage.delete(key: 'password');
                                await storage.delete(key: 'sheetID');
                                await storage.write(key: 'rememberMe', value: 'false');
                              }
                              print('Login successful');
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => HomePage(
                                    camera: widget.camera,
                                    username: _usernameController
                                        .text, // or _authenticatedUsername
                                    Name: _Name,
                                    Auth: _Authorized,
                                  ),
                                ),
                              );
                            } else {
                              print('Invalid credentials');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('Invalid username, password or sheet ID')),
                              );
                            }
                          }
                        } else {
                          print('User data is not available.');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Access token expired')),
                          );
                        }
                        setState(() {
                          _isLoading = false; // Stop loading
                        });
                      },
                      child: Text("Login"),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        primary: Colors.white, // Background color
                        onPrimary: Colors.black, // Text color
                        fixedSize: Size(120, 8),
                      ),
                      icon: FaIcon(
                        FontAwesomeIcons.google,
                        color: Colors.red,
                      ),
                      label: Text('Logout'),
                      onPressed: logout,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Center(child: CircularProgressIndicator()), // Loading indicator
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showInstructionsDialog(context, checkFlag: false),
        child: Icon(Icons.help_outline),
        tooltip: 'Show Instructions',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class GoogleSignInApi {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['https://www.googleapis.com/auth/spreadsheets'],
  );

  static Future<GoogleSignInAccount?> signInSilently() async {
    try {
      return await _googleSignIn.signInSilently();
    } catch (error) {
      print('Error during silent sign-in: $error');
      return null;
    }
  }

  static Future<void> logout() async {
    await _googleSignIn.signOut();
  }
}

Future<void> setLoginState(bool isLoggedIn) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('isLoggedIn', isLoggedIn);
}

Future<bool> getLoginState() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('isLoggedIn') ?? false;
}
