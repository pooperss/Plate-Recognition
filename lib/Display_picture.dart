import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'Debouncer.dart';
import 'Defines.dart';
import 'user_data_provider.dart';

class DisplayPictureScreen extends StatefulWidget {
  final String imagePath;

  const DisplayPictureScreen({Key? key, required this.imagePath})
      : super(key: key);

  @override
  _DisplayPictureScreenState createState() => _DisplayPictureScreenState();
}

class _DisplayPictureScreenState extends State<DisplayPictureScreen> {
  late File _imageFile;
  String? recognizedText;
  String? registration;
  late Future<void> textRecognitionFuture;
  final TextEditingController textController = TextEditingController();
  final debouncer = Debouncer(milliseconds: 1500);

  @override
  void initState() {
    super.initState();
    _imageFile = File(widget.imagePath);
    textRecognitionFuture = _recognizeTextFromImage();
    textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (textController.text != recognizedText) {
      recognizedText = textController.text;
      debouncer.run(() => queryPlateNumber(recognizedText!));
    }
  }

  Future<void> queryPlateNumber(String plateNumber) async {
    UserData? userData =
        Provider.of<UserDataProvider>(context, listen: false).userData;
    if (await Provider.of<UserDataProvider>(context, listen: false)
        .signInSilentlyIfNeeded()) {
      Provider.of<UserDataProvider>(context, listen: false)
          .userData!
          .accessToken;
    }
    final accessToken = userData?.accessToken;
    final sheetID = userData?.sheetID;
    final urlPlates = Uri.parse(
        'https://sheets.googleapis.com/v4/spreadsheets/$sheetID/values/Plates(101)');
    final response = await http.get(
      urlPlates,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );

    registration = 'Unregistered';
    String dateStr = DateFormat('dd/MM/yyyy').format(DateTime.now());

    if (accessToken == null || sheetID == null) {
      print('Access token or Sheet ID is null');
      return;
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final values = data['values'] as List<dynamic>?;
      if (values != null) {
        for (final row in values) {
          if (row.isNotEmpty && row[0] == plateNumber) {
            final Registration = row[1];
            setState(() {
              registration = Registration;
            });
            print('Registration: $Registration');
            break;
          }
        }
      }
    } else {
      print('Request failed with status: ${response.statusCode}.');
    }

    final urlProcessingData = Uri.parse(
        'https://sheets.googleapis.com/v4/spreadsheets/$sheetID/values/Processing%20Data(101)');
    final response2 = await http.get(urlProcessingData, headers: {
      'Authorization': 'Bearer $accessToken',
      'Accept': 'application/json',
    });

    if (response2.statusCode == 200) {
      final data = jsonDecode(response2.body);
      final values = data['values'] as List<dynamic>?;

      if (values != null) {
        for (final row in values) {
          if (row.isNotEmpty && row[1] == plateNumber) {
            final DateFormat inputFormat = DateFormat('dd/MM/yyyy');
            final DateTime date = inputFormat.parse(row[2]);
            final String currentDateStr = inputFormat.format(DateTime.now());
            if (inputFormat.format(date) == currentDateStr) {
              registration = "Visitors";
              setState(() {
                registration = registration;
              });
              print('Registration set to Visitor');
              break;
            }
          }
        }
      }

      setState(() {
        registration = registration;
      });
      print('Registration: $registration');
    } else {
      print('Request failed with status: ${response.statusCode}.');
    }

    int nextRow = await findNextAvailableRow(sheetID, accessToken);
    String range = 'Data(101)!A$nextRow:C$nextRow';

    final urlData = Uri.parse(
        'https://sheets.googleapis.com/v4/spreadsheets/$sheetID/values/$range?valueInputOption=USER_ENTERED');
    print("For Data(101) updates date: $dateStr");
    final Map<String, dynamic> body = {
      'values': [
        [dateStr, plateNumber, registration]
      ]
    };

    final response3 = await http.put(
      urlData,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response3.statusCode == 200) {
      print('Data updated in the sheet');
    } else {
      print('Failed to update data in the sheet: ${response3.body}');
    }
  }

  //              1qrsUMwGR7Ikbgi-flZibRU6-48VLnaOYPzDGesXMzag

  Future<int> findNextAvailableRow(String sheetID, String accessToken) async {
    final url = Uri.parse(
        'https://sheets.googleapis.com/v4/spreadsheets/$sheetID/values/Data(101)!A2:A');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final values = data['values'] as List<dynamic>? ?? [];
      for (int i = 0; i < values.length; i++) {
        if (values[i].isEmpty) {
          return i + 2; // Sheets API is 1-indexed, and we start from row 2
        }
      }
      return values.length + 2; // Return the next row number
    } else {
      throw Exception('Failed to load column data');
    }
  }

  Future<void> _recognizeTextFromImage() async {
    try {
      final InputImage inputImage = InputImage.fromFilePath(widget.imagePath);
      final TextRecognizer textRecognizer =
          TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);
      print('Recognized Text: ${recognizedText.text}');

      // Remove spaces and new lines from recognizedText
      String formattedText = recognizedText.text.replaceAll(RegExp(r'\s+'), '');

      // Convert the formattedText to uppercase
      formattedText = formattedText.toUpperCase();

      setState(() {
        this.recognizedText =
            formattedText; // Set formattedText to this.recognizedText
      });
      textRecognizer.close();
      await queryPlateNumber(formattedText);
    } catch (e) {
      print('Error recognizing text: $e');
    }
    textController.text = recognizedText!;
  }

  @override
  void dispose() {
    textController.removeListener(_onTextChanged);
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.black),
        title: Text(
          'Plate Number',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder(
          future: textRecognitionFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return Column(
                children: <Widget>[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Image.file(
                        _imageFile,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  SizedBox(height: 16.0),
                  if (recognizedText != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: textController,
                              decoration: InputDecoration(
                                labelText: 'Recognized Plate',
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12.0, vertical: 20.0),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: primaryColor, width: 2.0),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                              style: TextStyle(fontSize: 22.0),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              '$registration',
                              style: TextStyle(
                                fontSize: 20,
                                color: registration == 'Registered'
                                    ? Colors.yellow
                                    : (registration == 'Unregistered'
                                        ? Colors.white
                                        : (registration == 'Visitors'
                                            ? Colors.green
                                            : primaryVariantColor)),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                ],
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style:
                      TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              );
            } else {
              return Center(
                  child: CircularProgressIndicator(color: primaryColor));
            }
          },
        ),
      ),
    );
  }
}
