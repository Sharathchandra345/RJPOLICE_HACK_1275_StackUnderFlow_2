import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  ARSession? arSession;
  ARModel? groupOfPeople;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      CameraDescription(
        name: '0',
        lensDirection: CameraLensDirection.back,
        sensorOrientation: 0,
      ),
      ResolutionPreset.medium,
    );

    _initializeControllerFuture = _controller.initialize();
    arSession = ARSession();
    groupOfPeople = ARModel("person_.gltf");
  }

  @override
  void dispose() {
    _controller.dispose();
    arSession?.dispose();
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
    try {
      final response = await http.post(
        Uri.parse('http://192.168.29.44:5000/analyze'),
        body: jsonEncode({'image': base64Image}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        // Place the 3D model if desired.
        arSession?.placeModel(groupOfPeople!);
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('AR Camera')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                ARView(
                  onARViewCreated: (arView) {
                    arSession?.start();
                  },
                ),
                CameraPreview(_controller),
              ],
            );
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
