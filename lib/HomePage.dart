import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Camera_page.dart';
import 'Defines.dart';
import 'ProfilePage.dart';
import 'user_data_provider.dart';

class HomePage extends StatefulWidget {
  final CameraDescription? camera;
  final String? username;
  final String? Name;
  final String? Auth;

  const HomePage({
    Key? key,
    required this.Auth,
    this.Name,
    this.camera,
    required this.username,
  }) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late List<Widget> _pages;
  CameraDescription? _camera;
  List<String> _appBarTitles = [];

  @override
  void initState() {
    super.initState();
    _camera = widget.camera; // Initialize with the widget's camera

    if (_camera == null) {
      initializeCamera();
    } else {
      setupPages();
    }
  }

  Future<void> initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final firstCamera = cameras.first;

      setState(() {
        _camera = firstCamera; // Update the state variable
        setupPages();
      });
    } catch (e) {
      print("Failed to initialize camera: $e");
    }
  }

  void setupPages() {
    _selectedIndex = 0;
    if (widget.Auth == 'Authorized') {
      _pages = [
        HomeScreen(),
        CameraPage(camera: _camera!),
        ProfilePage(
            username: widget.username, Name: widget.Name, Auth: widget.Auth),
      ];
      _appBarTitles = ['Home', 'Capture&Identify', 'Profile'];
    } else {
      _pages = [
        CameraPage(camera: _camera!),
        ProfilePage(
            username: widget.username, Name: widget.Name, Auth: widget.Auth),
      ];
      _appBarTitles = ['Capture&Identify', 'Profile'];
    }
  }

  void _onItemTapped(int index) {
    print("Before setState in _onItemTapped: _selectedIndex: $index");
    setState(() {
      _selectedIndex = index;
    });
    print("After setState in _onItemTapped: _selectedIndex = $_selectedIndex");
  }

  @override
  Widget build(BuildContext context) {
    print("In build: _selectedIndex = $_selectedIndex");
    return Scaffold(
      appBar: _selectedIndex != 3 // Check if the Registration tab is selected
          ? AppBar(
              title: Text(_appBarTitles[_selectedIndex]),
              titleTextStyle: GoogleFonts.satisfy(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              backgroundColor: primaryVariantColor,
            )
          : null, // Set appBar to null if Registration tab is selected
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: widget.Auth == 'Authorized'
            ? <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Image.asset('images/Camera_icon.png',
                      width: 30, height: 30),
                  label: 'Camera',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ]
            : <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Image.asset('images/Camera_icon.png',
                      width: 30, height: 30),
                  label: 'Camera',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<int> Data = [];
  List<int> visitorData = [];
  List<String> visitorDate = [];
  bool isShowingMainData = true;

  //final gsheets = GSheets(credentials);
  Timer? _fetchTimer;

  @override
  void initState() {
    super.initState();
    fetchData();
    Timer.periodic(Duration(seconds: 30), (Timer t) => fetchData());
  }

  @override
  void dispose() {
    _fetchTimer?.cancel();
    loadLocalData();
    super.dispose();
  }

  Future<void> loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? dataString = prefs.getString('Data');
    final String? visitorDataString = prefs.getString('visitorData');
    final String? visitorDateString = prefs.getString('visitorDate');

    if (dataString != null) {
      setState(() {
        Data = List<int>.from(json.decode(dataString));
      });
    }
    if (visitorDataString != null) {
      setState(() {
        visitorData = List<int>.from(json.decode(visitorDataString));
      });
    }
    if (visitorDateString != null) {
      setState(() {
        visitorDate = List<String>.from(json.decode(visitorDateString));
      });
    }
  }

  Future<void> saveDataLocally() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('Data', json.encode(Data));
    prefs.setString('visitorData', json.encode(visitorData));
    prefs.setString('visitorDate', json.encode(visitorDate));
  }

  Future<void> fetchData() async {
    final prefs = await SharedPreferences.getInstance();
    UserData? userData =
        Provider.of<UserDataProvider>(context, listen: false).userData;

    if (userData == null ||
        userData.accessToken.isEmpty ||
        userData.sheetID.isEmpty) {
      print("User data or access token or sheetID is not available");
      return;
    }
    if (await Provider.of<UserDataProvider>(context, listen: false)
        .signInSilentlyIfNeeded()) {
      Provider.of<UserDataProvider>(context, listen: false)
          .userData!
          .accessToken;
    }

    String accessToken = userData.accessToken;
    final spreadsheetId = userData.sheetID;

    final ranges = [
      'Processing%20Data(101)%21F2%3AF', // Column 6
      'Processing%20Data(101)%21G2%3AG', // Column 7
      'Processing%20Data(101)%21J2%3AJ', // Column 10
    ];

    try {
      List<List<String>> columnData = [];

      for (final range in ranges) {
        final url = Uri.parse(
            'https://sheets.googleapis.com/v4/spreadsheets/$spreadsheetId/values:batchGet?ranges=$range&access_token=$accessToken');

        final response = await http.get(url);

        if (response.statusCode != 200) {
          throw Exception(
              'Failed to fetch data from Google Sheets. Status Code: ${response.statusCode}');
        }

        final data = jsonDecode(response.body);
        final results = data['valueRanges']?.first['values'] ?? [];
        //print('Result $range: $results');

        List<String> column = [];

        if (results.isNotEmpty) {
          for (final row in results) {
            if (row.isNotEmpty) {
              final value = row[0];
              if (value != null && value is String) {
                column.add(value);
              } else {
                print('Column Data is not a String');
              }
            }
          }
        } else {
          print('No data available in $range');
        }

        columnData.add(column);
      }

      // Process and store the fetched data as needed
      List<int> visitorData =
          columnData[0].map((e) => int.tryParse(e) ?? 0).toList();
      List<String> visitorDate = columnData[1];
      List<int> Data = columnData[2].map((e) => int.tryParse(e) ?? 0).toList();

      print('VisitorDataList: $visitorData');
      print('VisitorDateList: $visitorDate');
      print('DataList: $Data');

      await prefs.setString('Data', json.encode(columnData[2]));
      await prefs.setString('visitorData', json.encode(columnData[0]));
      await prefs.setString('visitorDate', json.encode(columnData[1]));

      if (mounted) {
        setState(() {
          // Filter out 0 values from visitorData and corresponding dates in visitorDate
          List<int> filteredVisitorData = [];
          List<String> filteredVisitorDate = [];

          for (int i = 0; i < visitorData.length; i++) {
            if (visitorData[i] != 0 && i < visitorDate.length) {
              filteredVisitorData.add(visitorData[i]);
              filteredVisitorDate.add(visitorDate[i]);
            }
          }

          this.visitorData = filteredVisitorData;
          this.visitorDate = filteredVisitorDate;
          this.Data = Data; // Assuming Data does not need filtering
        });
      }
    } catch (e) {
      // Fetch failed, use the cached data if available
      print('Failed to fetch data: $e');
      final String? dataString = prefs.getString('Data');
      final String? visitorDataString = prefs.getString('visitorData');
      final String? visitorDateString = prefs.getString('visitorDate');

      if (dataString != null &&
          visitorDataString != null &&
          visitorDateString != null) {
        setState(() {
          Data = List<int>.from(json.decode(dataString));
          visitorData = List<int>.from(json.decode(visitorDataString));
          visitorDate = List<String>.from(json.decode(visitorDateString));
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine which data set to display based on isShowingMainData flag
    final List<int> currentData = isShowingMainData ? Data : visitorData;
    final List<String> currentDates = isShowingMainData ? [] : visitorDate;

    // Generate the list of widgets to display in the ListView
    List<Widget> listItems = [];
    if (isShowingMainData) {
      // Generate list items for main data
      listItems =
          Data.asMap().entries.where((entry) => entry.value > 0).map((entry) {
        return _buildListItem(
            '${getHourLabel(entry.key)}', entry.value.toString());
      }).toList();
    } else {
      // Generate list items for visitor data
      for (int i = 0; i < visitorData.length; i++) {
        listItems.add(
            _buildListItem(currentDates[i], visitorData[i].toStringAsFixed(1)));
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                color: Colors.black,
                icon: Icon(Icons.arrow_left),
                onPressed: () {
                  setState(() {
                    isShowingMainData = !isShowingMainData;
                  });
                },
              ),
              IconButton(
                color: Colors.black,
                icon: Icon(Icons.arrow_right),
                onPressed: () {
                  setState(() {
                    isShowingMainData = !isShowingMainData;
                  });
                },
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(top: 50),
            child: SizedBox(
              height: 200,
              child: MyBarGraph(data: currentData, dates: currentDates),
            ),
          ),
          Expanded(
            child: Container(
              margin: EdgeInsets.all(8), // spacing from the screen edges
              decoration: BoxDecoration(
                color: Colors.white, // Background color of the box
                borderRadius: BorderRadius.circular(8), // rounded corners
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3), // position of shadow
                  ),
                ],
              ),
              child: ListView(
                children: listItems,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(String label, String value) {
    return Column(
      children: [
        ListTile(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(color: Colors.black)),
              Text(value, style: TextStyle(color: Colors.black)),
            ],
          ),
        ),
        _vagueDivider(),
      ],
    );
  }

  String getHourLabel(int hour) {
    List<String> labels = ["Registered", "Unregistered", "Visitors"];
    return labels[hour % 24];
  }
}

class MyBarGraph extends StatefulWidget {
  final List<int> data;
  final List<String> dates;

  const MyBarGraph({Key? key, required this.data, this.dates = const []})
      : super(key: key);

  @override
  State<MyBarGraph> createState() => _MyBarGraphState();
}

class _MyBarGraphState extends State<MyBarGraph> {
  @override
  Widget build(BuildContext context) {
    int maxYValue = widget.data.isEmpty
        ? 10 // Default value if data is empty
        : widget.data.reduce(max) + 5; // Adding a buffer of 5

    final filteredData =
        widget.data.asMap().entries.where((entry) => entry.value > 0).toList();

    List<BarChartGroupData> barGroups = List.generate(
      filteredData.length,
      (index) {
        var entry = filteredData[index];
        return BarChartGroupData(
          x: entry.key,
          barRods: [
            BarChartRodData(
              width: 30,
              color: Colors.grey[800]!,
              borderRadius: BorderRadius.circular(4),
              toY: entry.value.toDouble(),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxYValue.toDouble(),
                color: Colors.grey[200]!,
              ),
            ),
          ],
        );
      },
    );

    double chartWidth = filteredData.length * 50.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        width: chartWidth,
        child: AspectRatio(
          aspectRatio: 1.7,
          child: BarChart(
            BarChartData(
              maxY: maxYValue.toDouble(),
              minY: 0,
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                show: true,
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return getTitles(value, meta);
                    },
                    reservedSize: 30,
                  ),
                ),
              ),
              barGroups: barGroups,
            ),
          ),
        ),
      ),
    );
  }

  Widget getTitles(double value, TitleMeta meta) {
    if (widget.dates.isNotEmpty && value.toInt() < widget.dates.length) {
      // Parse the date string and then format it to exclude the year
      DateTime date =
          DateFormat('dd/MM/yyyy').parse(widget.dates[value.toInt()]);
      String formattedDate =
          DateFormat('dd/MM').format(date); // Format without the year

      return SideTitleWidget(
        axisSide: meta.axisSide,
        space: 16,
        child: Text(formattedDate,
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 12)),
      );
    } else {
      // Default labels for the main data
      const style = TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      );
      switch (value.toInt()) {
        case 0:
          return Text('R', style: style);
        case 1:
          return Text('U', style: style);
        case 2:
          return Text('V', style: style);
        // Add more cases as needed for your labels
        default:
          return Text('', style: style);
      }
    }
  }
}

Widget _vagueDivider() {
  return Divider(
    color: Colors.grey[300],
    thickness: 1, // Thin line
    indent: 20,
    endIndent: 20,
  );
}
