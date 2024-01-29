import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'LoginPage.dart';
import 'user_data_provider.dart';

class GoogleSignInPage extends StatefulWidget {
  final CameraDescription? camera;

  GoogleSignInPage({Key? key, this.camera}) : super(key: key);

  @override
  _GoogleSignInPageState createState() => _GoogleSignInPageState();
}

class _GoogleSignInPageState extends State<GoogleSignInPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => signin()); // Trigger sign-in automatically
  }

  Future signin() async {
    GoogleSignInAccount? user;
    bool isLoggedIn = await getLoginState();

    if (isLoggedIn) {
      // Attempt silent login
      user = await GoogleSignInApi.signInSilently();
    } else {
      // Regular login
      user = await GoogleSignInApi.login();
    }

    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Signed in Failed')));
      setLoginState(false);
    } else {
      setLoginState(true);
      await user.clearAuthCache();
      final GoogleSignInAuthentication googleAuth = await user.authentication;

      Provider.of<UserDataProvider>(context, listen: false).setUserData(
        UserData(
          displayName: user.displayName ?? "",
          accessToken: googleAuth.accessToken ?? "",
          sheetID: "",
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => LoginPage(camera: widget.camera),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Google Sign In'),
      ),
      body: Center(
        child:
            CircularProgressIndicator(), // Show a loading indicator while signing in
      ),
    );
  }
}

class GoogleSignInApi {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['https://www.googleapis.com/auth/spreadsheets'],
  );

  static Future<GoogleSignInAccount?> login() async {
    // Sign out any existing accounts
    await _googleSignIn.signOut();

    try {
      final account = await _googleSignIn.signIn();
      if (account != null) {
        // Authentication successful
        return account;
      }
    } catch (error) {
      print('Google Sign-In Error: $error');
    }
    return null;
  }

  static Future<GoogleSignInAccount?> signInSilently() async {
    try {
      return await _googleSignIn.signInSilently();
    } catch (error) {
      print('Google Sign-In Error: $error');
      return null;
    }
  }
}

Future<void> testAccessTokenWithGoogleSheets(
    GoogleSignInAccount user, String sheetId) async {
  String accessToken = (await user.authentication).accessToken!;
  final url =
      Uri.parse('https://sheets.googleapis.com/v4/spreadsheets/$sheetId');

  var response = await http.get(
    url,
    headers: {
      'Authorization': 'Bearer $accessToken',
    },
  );

  // Check if the token is expired or invalid
  if (response.statusCode == 401) {
    // Clear the token cache
    await user.clearAuthCache();

    // Re-authenticate to get a new access token
    final GoogleSignInAuthentication newAuth = await user.authentication;
    accessToken = newAuth.accessToken!;

    // Retry the API call with the new token
    response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );
  }

  if (response.statusCode == 200) {
    print('Connection to Google Sheets API successful');
  } else {
    // Handle errors.
    print(
        'Connection to Google Sheets API failed, status code: ${response.statusCode}, body: ${response.body}');
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
