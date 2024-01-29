import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> showInstructionsDialog(BuildContext context,
    {bool checkFlag = true}) async {
  final prefs = await SharedPreferences.getInstance();
  bool showInstructions = prefs.getBool('showInstructions') ?? true;

  if (checkFlag && !showInstructions) return;

  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Instructions'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text(
                "Host",
                style: TextStyle(fontSize: 25),
              ),
              Text(
                  "1. Create a Google Form for visitor registration with fields: Plates (Short-answer), Name (Short-answer), and Date (Multiple choice). Additional fields are optional after the mandatory plate, name, and date. "),
              Image.asset('images/instruction1.png'),
              SizedBox(height: 20),
              Text(
                  "2. Navigate to Settings > Collect email addresses by default > Verified."),
              Image.asset('images/instruction2.png'),
              SizedBox(height: 20),
              Text(
                  "3. Under 'Responses', choose 'Link to Sheets'. Name your sheet and create it. 12"),
              Image.asset('images/instruction3.png'),
              SizedBox(height: 10),
              Image.asset('images/instruction4.png'),
              SizedBox(height: 20),
              Text(
                  "4. Rename the sheet tab to 'Visitors (101)' and share this sheet with the gmail accounts you created."),
              Image.asset('images/instruction5.png'),
              SizedBox(height: 10),
              Image.asset('images/instruction6.png'),
              SizedBox(height: 20),
              Text(
                  "5. Note down the Sheet ID from the URL for login purposes. "),
              Image.asset('images/instruction7.png'),
              SizedBox(height: 20),
              Text(
                  "6. Enter the Sheet ID into your app with the create_key (username: create, password: create). "),
              Image.asset('images/instruction8.png'),
              SizedBox(height: 20),
              Text(
                  "7. Successful login will automate the creation of relevant pages in the sheet. "),
              Image.asset('images/instruction9.png'),
              SizedBox(height: 20),
              Text(
                  "8. Hosts now have the ability to assign passwords to users directly on the Auth(101) page. "),
              Text(
                "User",
                style: TextStyle(fontSize: 25),
              ),
              Text(
                  "1. The host will create a Google account for each user and initially log in on their behalf, as the account passwords are to remain confidential and unknown to the users. Following this initial setup, users can independently access the app using the Sheet ID, username, and password specified by the host on the Auth(101) page "),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text("Don't show this again"),
            onPressed: () async {
              await prefs.setBool('showInstructions', false);
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('Close'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
