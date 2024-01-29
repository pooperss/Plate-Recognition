import 'dart:convert';

import 'package:http/http.dart' as http;

import 'user_data_provider.dart';

Future<String> setupSheets(UserData userData, String spreadsheetId) async {
  print('Access Token: ${userData.accessToken}');
  print('Spreadsheet ID: $spreadsheetId');

  final headers = {
    'Authorization': 'Bearer ${userData.accessToken}',
    'Content-Type': 'application/json',
  };

  Future<List<String>> getExistingSheets() async {
    final url = Uri.parse(
        'https://sheets.googleapis.com/v4/spreadsheets/$spreadsheetId');
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<String> existingSheets = [];
      for (var sheet in data['sheets']) {
        existingSheets.add(sheet['properties']['title']);
      }
      return existingSheets;
    } else {
      print(
          'Failed to retrieve sheets: ${response.statusCode}, ${response.body}');
      throw Exception('Failed to retrieve existing sheets');
    }
  }

  Future<bool> createSheet(String title) async {
    final url = Uri.parse(
        'https://sheets.googleapis.com/v4/spreadsheets/$spreadsheetId:batchUpdate');
    final response = await http.post(
      url,
      headers: headers,
      body: json.encode({
        "requests": [
          {
            "addSheet": {
              "properties": {
                "title": title,
              }
            }
          }
        ]
      }),
    );

    return response.statusCode == 200;
  }

  Future<bool> setupDataSheet() async {
    // Insert headers in A1:C1
    final headersUrl = Uri.parse(
        'https://sheets.googleapis.com/v4/spreadsheets/$spreadsheetId/values/Data(101)!A1:C1?valueInputOption=USER_ENTERED');
    var headersResponse = await http.put(
      headersUrl,
      headers: headers,
      body: json.encode({
        "values": [
          ["Date", "Plate", "State"]
        ],
        "majorDimension": "ROWS"
      }),
    );

    if (headersResponse.statusCode != 200) {
      print(
          'Failed to insert headers for Data(101) setup: ${headersResponse.body}');
      return false;
    }

    // Insert formula in I1
    final formulaUrl = Uri.parse(
        'https://sheets.googleapis.com/v4/spreadsheets/$spreadsheetId/values/Data(101)!I1?valueInputOption=USER_ENTERED');
    var formulaResponse = await http.put(
      formulaUrl,
      headers: headers,
      body: json.encode({
        "values": [
          ["=INDEX(COUNTIFS(C2:C53436, UNIQUE(C2:C53436)), ,)"]
        ],
        "majorDimension": "ROWS"
      }),
    );

    if (formulaResponse.statusCode != 200) {
      print('Failed to insert formula: ${formulaResponse.body}');
      return false;
    }

    return true;
  }

  Future<bool> setupPlatesSheet() async {
    final headersUrl = Uri.parse(
        'https://sheets.googleapis.com/v4/spreadsheets/$spreadsheetId/values/Plates(101)!A1:C3?valueInputOption=USER_ENTERED');
    var headersResponse = await http.put(
      headersUrl,
      headers: headers,
      body: json.encode({
        "values": [
          ["Plates", "Registration", "BLK/UNIT"], // Header Row
          ["SDN7484U", "Registered", "#08-74"],  // Example Row 1
          ["SGD7687S", "Unregistered", "#09-23"]  // Example Row 2
        ],
        "majorDimension": "ROWS"
      }),
    );

    if (headersResponse.statusCode != 200) {
      print(
          'Failed to insert headers and example data into Plates(101): ${headersResponse.statusCode}, ${headersResponse.body}');
      return false;
    }
    print('Headers and example data inserted into Plates(101) successfully.');
    return true;
  }


  Future<bool> insertInitialData(UserData userData, String spreadsheetId) async {
    final range = 'Auth(101)!A1:D3';
    final url = Uri.parse(
        'https://sheets.googleapis.com/v4/spreadsheets/$spreadsheetId/values/$range?valueInputOption=USER_ENTERED');

    final headers = {
      'Authorization': 'Bearer ${userData.accessToken}',
      'Content-Type': 'application/json',
    };

    final body = json.encode({
      "values": [
        ["Username", "Password", "Name", "Authorization"],
        ["abc", "123", "Tom", "Authorized"],
        ["asd", "asd", "Tim", "Unauthorized"]
      ],
    });

    final response = await http.put(url, headers: headers, body: body);
    return response.statusCode == 200;
  }

  Future<bool> insertDataInVisitorsSheet(String spreadsheetId) async {
    final dataUrl = Uri.parse(
        'https://sheets.googleapis.com/v4/spreadsheets/$spreadsheetId/values/Visitors(101)!A2:E2?valueInputOption=USER_ENTERED');
    var dataResponse = await http.put(
      dataUrl,
      headers: headers,
      body: json.encode({
        "values": [
          ["19/01/2024 13:35:58", "pixelated1103@gmail.com", "SDN7484", "Tim", "19/01/2024"]
        ],
        "majorDimension": "ROWS"
      }),
    );

    if (dataResponse.statusCode != 200) {
      print(
          'Failed to insert data into Visitors(101): ${dataResponse.statusCode}, ${dataResponse.body}');
      return false;
    }
    print('Data inserted into Visitors(101) successfully.');
    return true;
  }


  Future<bool> setupProcessingDataSheet() async {
    final headersUrl = Uri.parse(
        'https://sheets.googleapis.com/v4/spreadsheets/$spreadsheetId/values/Processing%20Data(101)!A1:J1?valueInputOption=USER_ENTERED');
    var headersResponse = await http.put(
      headersUrl,
      headers: headers,
      body: json.encode({
        "values": [
          [
            "",
            "Plate(Visitors)",
            "TXT based date(Visitors)",
            "",
            "Daily Visitors(Visitors)",
            "Count(Visitors)",
            "TXT Daily Visitors(Visitors)",
            "",
            "Status(Data)",
            ""
          ]
        ],
        "majorDimension": "ROWS"
      }),
    );

    if (headersResponse.statusCode != 200) {
      print(
          'Failed to insert headers into Processing Data(101): ${headersResponse.statusCode}, ${headersResponse.body}');
      return false;
    }

    final formulasUrl = Uri.parse(
        'https://sheets.googleapis.com/v4/spreadsheets/$spreadsheetId/values/Processing%20Data(101)!B2:J2?valueInputOption=USER_ENTERED');
    var formulasResponse = await http.put(
      formulasUrl,
      headers: headers,

    body: json.encode({
      "values": [
        [
          "=ARRAYFORMULA(INDIRECT(\"'Visitors(101)'!C2:C5033\"))",
          "=ARRAYFORMULA(IF(LEN(INDIRECT(\"'Visitors(101)'!E2:E5034\")), TEXT(INDIRECT(\"'Visitors(101)'!E2:E5034\"), \"DD/MM/YYYY\"), \"\"))",
          "",
          "=UNIQUE(FILTER(INDIRECT(\"'Visitors(101)'!E2:E5034\"), NOT(ISBLANK(INDIRECT(\"'Visitors(101)'!E2:E5034\")))))",
          "=INDEX(COUNTIFS(INDIRECT(\"'Visitors(101)'!E2:E5034\"), UNIQUE(INDIRECT(\"'Visitors(101)'!E2:E5034\"))), ,)",
          "=ARRAYFORMULA(IF(LEN(INDIRECT(\"E2:E5033\")), TEXT(INDIRECT(\"E2:E5033\"), \"DD/MM/YYYY\"), \"\"))",
              "",
          "=UNIQUE('Data(101)'!C2:C52523)",
          "=INDEX(COUNTIFS('Data(101)'!A2:A, TODAY(), 'Data(101)'!C2:C, UNIQUE('Data(101)'!C2:C)), ,)"
        ]
      ],
      "majorDimension": "ROWS"
    }),
    );
    if (formulasResponse.statusCode != 200) {
      print(
          'Failed to insert formulas into Processing Data(101): ${formulasResponse.statusCode}, ${formulasResponse.body}');
      return false;
    }

    print('Processing Data(101) sheet setup successfully.');
    return true;
  }

  const requiredSheets = [
    'Plates(101)',
    'Data(101)',
    'Processing Data(101)',
    'Auth(101)'
  ];

  try {
    final existingSheets = await getExistingSheets();
    bool sheetsCreated = false;

    for (var title in requiredSheets) {
      if (!existingSheets.contains(title)) {
        bool success = await createSheet(title);
        if (!success) {
          print("Error creating sheet: $title");
          return 'Failed to setup sheets';
        }
        sheetsCreated = true;
        print("Created sheet: $title");
      }
      /*if (existingSheets.contains("Visitors(101)")) {
        bool dataInserted = await insertDataInVisitorsSheet(spreadsheetId);
        if (!dataInserted) {
          print("Failed to insert initial data into Visitors(101) sheet.");
          return 'Failed to insert initial data in Visitors(101)';
        }
      }*/
      if (title == 'Data(101)') {
        bool dataSheetSetupSuccess = await setupDataSheet();
        if (!dataSheetSetupSuccess) {
          print("Error setting up 'Data(101)' sheet.");
          return 'Failed to setup Data sheets';
        }
      }

      if (title == 'Plates(101)') {
        bool platesSheetSetupSuccess = await setupPlatesSheet();
        if (!platesSheetSetupSuccess) {
          print("Error setting up 'Plates(101)' sheet.");
          return 'Failed to setup Plates sheets';
        }
      }

      if (title == "Auth(101)") {
        bool dataInserted = await insertInitialData(userData, spreadsheetId);
        if (!dataInserted) {
          print("Failed to insert initial data into Auth(101) sheet.");
          return 'Failed to insert initial data';
        }
      }

      if (title == 'Processing Data(101)') {
        bool processSheetSetupSuccess = await setupProcessingDataSheet();
        if (!processSheetSetupSuccess) {
          print("Error setting up 'Processing Data(101)' sheet.");
          return 'Failed to setup Processing Data sheets';
        }
      }
    }

    if (sheetsCreated) {
      return 'Sheets setup complete';
    } else {
      return 'Sheets already exist';
    }
  } catch (e) {
    print('Error setting up sheets: $e');
    return 'Failed to setup sheets';
  }
}
