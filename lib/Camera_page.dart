import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'Display_picture.dart';
import 'RectPainter.dart';

class CameraPage extends StatefulWidget {
  final CameraDescription camera;

  const CameraPage({Key? key, required this.camera}) : super(key: key);

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  double _currentZoomLevel = 1.0;
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.high);
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return GestureDetector(
                    onScaleUpdate: (ScaleUpdateDetails details) async {
                      final maxZoomLevel = await _controller.getMaxZoomLevel();
                      final minZoomLevel = await _controller.getMinZoomLevel();

                      double newZoomLevel = _currentZoomLevel * details.scale;
                      newZoomLevel =
                          newZoomLevel.clamp(minZoomLevel, maxZoomLevel);

                      if (newZoomLevel != _currentZoomLevel) {
                        _currentZoomLevel = newZoomLevel;
                        await _controller.setZoomLevel(_currentZoomLevel);
                        setState(() {});
                      }
                    },
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: CameraPreview(_controller),
                    ),
                  );
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: Container(
                width: 300,
                height: 100,
                child: Stack(
                  children: [
                    CustomPaint(
                      painter: RectPainter(),
                      child: Container(), // Added this line
                    ),
                    Center(
                      child: Text(
                        '+',
                        style: TextStyle(
                          fontSize: 30, // Adjust font size as needed
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.camera),
        onPressed: () async {
          try {
            await _initializeControllerFuture;
            final image = await _controller.takePicture();

            // Display the crop widget
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => CropImageScreen(imagePath: image.path),
              ),
            );
          } catch (e) {
            print(e);
          }
        },
      ),
    );
  }
}

class CropImageScreen extends StatefulWidget {
  final String imagePath;

  const CropImageScreen({Key? key, required this.imagePath}) : super(key: key);

  @override
  _CropImageScreenState createState() => _CropImageScreenState();
}

class _CropImageScreenState extends State<CropImageScreen> {
  final _cropController = CropController();
  Uint8List? imageBytes;
  bool _isCropping = false;
  double left = 0.1; // 10% from the left
  double top = 500; // 25% from the top
  double width = 700; // 80% of the image width
  double height = 240; // 50% of the image height

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final file = File(widget.imagePath);
      imageBytes = await file.readAsBytes();
      setState(() {});
    } catch (e) {
      print("Error loading image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.black),
        backgroundColor: Colors.white,
        title: Text(
          'Crop Image',
          style: TextStyle(color: Colors.black),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.check),
            onPressed: () {
              if (!_isCropping && imageBytes != null) {
                _cropImage();
              }
            },
          ),
        ],
      ),
      body: imageBytes == null
          ? Center(child: CircularProgressIndicator())
          : Crop(
              image: imageBytes!,
              controller: _cropController,
              initialArea: Rect.fromLTWH(left, top, width, height),
              onCropped: (croppedData) {
                _onCropComplete(croppedData);
              },
              interactive: true,
            ),
    );
  }

  void _cropImage() {
    setState(() {
      _isCropping = true;
    });
    _cropController.crop();
  }

  Future<void> _onCropComplete(Uint8List croppedData) async {
    // Get a temporary directory to save the cropped image
    final directory = await getTemporaryDirectory();
    final imagePath =
        '${directory.path}/cropped_image_${DateTime.now().millisecondsSinceEpoch}.png';

    // Save the cropped image data to a file
    File imageFile = File(imagePath);
    await imageFile.writeAsBytes(croppedData);

    // Navigate to DisplayPictureScreen with the path of the saved image
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => DisplayPictureScreen(imagePath: imageFile.path),
      ),
    );
  }
}
