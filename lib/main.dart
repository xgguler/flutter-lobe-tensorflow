import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';
import 'package:image/image.dart' as img;

void main() => runApp(MaterialApp(
      home: HomeScreen(),
    ));

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File pickedImage;
  bool isImageLoaded = false;

  List _result;

  String name = "";
  String confidence = "";

  getImageFromGallery() async {
    var tempStore = await ImagePicker().getImage(source: ImageSource.gallery);

    setState(() {
      pickedImage = File(tempStore.path);
      isImageLoaded = true;
      applyModelOnImage(pickedImage);
    });
  }

  applyModelOnImage(File file) async {
    var imageBytes = file.readAsBytesSync();
    img.Image oriImage = img.decodeJpg(imageBytes);
    var resultOnImage = await Tflite.runModelOnBinary(
      binary: imageToByteListFloat32(oriImage, 224, 127.5, 127.5), // required
      numResults: 2, // defaults to 5
      threshold: 0.05, // defaults to 0.1
      asynch: true, // defaults to true
    );

    setState(() {
      _result = resultOnImage;
      name = _result[0]["label"];
      confidence =
          (_result[0]["confidence"] * 100).toString().substring(0, 5) + "%";
      print('result');
      print(_result);
    });
  }

  Uint8List imageToByteListFloat32(
      img.Image image, int inputSize, double mean, double std) {
    var convertedBytes = Float32List(1 * inputSize * inputSize * 3);
    var buffer = Float32List.view(convertedBytes.buffer);

    int pixelIndex = 0;
    for (var i = 0; i < inputSize; i++) {
      for (var j = 0; j < inputSize; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = (img.getRed(pixel) - mean) / std;
        buffer[pixelIndex++] = (img.getGreen(pixel) - mean) / std;
        buffer[pixelIndex++] = (img.getBlue(pixel) - mean) / std;
      }
    }
    return convertedBytes.buffer.asUint8List();
  }

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }

  loadModel() async {
    var result = await Tflite.loadModel(
      labels: "assets/saved_model.txt",
      model: "assets/saved_model.tflite",
    );

    print(result);
  }

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Lobe AI - Tensorflow Lite',
        ),
      ),
      body: Container(
        child: Column(
          children: [
            SizedBox(
              height: 30,
            ),
            isImageLoaded
                ? Center(
                    child: AspectRatio(
                      aspectRatio: 224 / 224,
                      child: Container(
                        decoration: BoxDecoration(
                            image: DecorationImage(
                          image: FileImage(File(pickedImage.path)),
                          alignment: FractionalOffset.topCenter,
                          fit: BoxFit.fitWidth,
                        )),
                      ),
                    ),
                  )
                : Container(),
            SizedBox(
              height: 30,
            ),
            Text('Name: $name\nConfidence: $confidence')
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: getImageFromGallery,
        child: Icon(Icons.photo_album),
      ),
    );
  }
}
