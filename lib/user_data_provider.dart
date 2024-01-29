import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Model Class for User Data
class UserData {
  final String displayName;
  final String accessToken;
  final String sheetID;

  UserData({
    required this.displayName,
    required this.accessToken,
    required this.sheetID,
  });
}

// Provider Class for User Data
class UserDataProvider extends ChangeNotifier {
  UserData? _userData;
  DateTime? _lastSignInTime;

  UserData? get userData => _userData;

  void setUserData(UserData userData) {
    _userData = userData;
    notifyListeners();
  }

  Future<bool> signInSilentlyIfNeeded() async {
    final now = DateTime.now();
    if (_lastSignInTime == null ||
        now.difference(_lastSignInTime!).inHours >= 1) {
      final account = await GoogleSignInApi.signInSilently();
      if (account != null) {
        await account.clearAuthCache();
        final GoogleSignInAuthentication googleAuth =
            await account.authentication;
        _userData = UserData(
          displayName: _userData?.displayName ?? "",
          accessToken: googleAuth.accessToken!,
          sheetID: _userData?.sheetID ?? "",
        );
        _lastSignInTime = now;
        notifyListeners();
        print('New Token generated');
        return true;
      }
      return false;
    }
    print('Less than an Hour');
    return true;
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
}
