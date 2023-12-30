import 'package:flutter/material.dart';
// import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      CameraDescription(
          name: '0',
          lensDirection: CameraLensDirection.back,
          sensorOrientation: 0),
      ResolutionPreset.medium,
    );

    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendFrame() async {
    if (!_controller.value.isInitialized) {
      return;
    }

    try {
      await _controller.startImageStream((image) {
        List<int> imageBytes = image.planes[0].bytes;
        String base64Image = base64Encode(imageBytes);

        _analyzeFrame(base64Image);
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> _analyzeFrame(String base64Image) async {
    final response = await http.post(
      Uri.parse('http://192.168.43.44:5000/analyze'),
      body: jsonEncode({'image': base64Image}),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      print(response.body);
    } else {
      print('Error: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Camera')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller);
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _sendFrame,
        child: Icon(Icons.camera),
      ),
    );
  }
}
