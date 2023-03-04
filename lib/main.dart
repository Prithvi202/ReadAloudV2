import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:readaloud_v2/utils/animatedcapture.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final rearCam = cameras.first;
  runApp(MyApp(camera: rearCam));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;

  const MyApp({Key? key, required this.camera}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      home: InitApp(camera: camera),
    );
  }
}

class InitApp extends StatefulWidget {
  final CameraDescription camera;

  const InitApp({Key? key, required this.camera}) : super(key: key);

  @override
  State<InitApp> createState() => _InitAppState();
}

class _InitAppState extends State<InitApp> {

  late CameraController _controller;

  late double _minAvailableZoom;
  late double _maxAvailableZoom;

  late Future<void> _initControllerFuture;
  double _zoomLevel = 1.0;


  bool showFocusCircle = false;
  double x = 0;
  double y = 0;
  
  @override
  void initState()
  {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.max,
      enableAudio: false,
    );
    _initControllerFuture = _controller.initialize();
  }

  @override
  void dispose()
  {
    _controller.dispose();
    super.dispose();
  }

  void _onZoom(details)
  {
    _minAvailableZoom = 1.0;
    _maxAvailableZoom = 10.0;
    setState(() {
      /*
      _zoomLevel = zoomLevel;
      _controller.setZoomLevel(zoomLevel);
       */
      //_zoomLevel = (_zoomLevel * details.scale).clamp(_minAvailableZoom, _maxAvailableZoom);
      _zoomLevel += (details.scale - 1.0) * 0.02;
      _zoomLevel = _zoomLevel.clamp(_minAvailableZoom, _maxAvailableZoom);
      _controller.setZoomLevel(_zoomLevel);
    });
  }

  void _onCapturePressed() async
  {
    try {
      await _initControllerFuture;
      final img = await _controller.takePicture();
      final imgPath = img.path;
      //Navigator.of(context).push(MaterialPageRoute(builder: (_) => PreviewScreen(imagePath: imgPath));
    } catch (e) {
      print("Some error occured while taking pic! $e");
    }
  }

  Future<void> _onTap(TapUpDetails details) async {
    if(_controller.value.isInitialized) {
      showFocusCircle = true;
      x = details.localPosition.dx;
      y = details.localPosition.dy;

      double fullWidth = MediaQuery.of(context).size.width;
      double cameraHeight = fullWidth * _controller.value.aspectRatio;

      double xp = x / fullWidth;
      double yp = y / cameraHeight;

      Offset point = Offset(xp,yp);
      print("point : $point");

      // Manually focus
      await _controller.setFocusPoint(point);

      // Manually set light exposure
      //controller.setExposurePoint(point);

      setState(() {
        Future.delayed(const Duration(seconds: 2)).whenComplete(() {
          setState(() {
            showFocusCircle = false;
          });
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("ReadAloud V2"),
        centerTitle: true,
        backgroundColor: Colors.black26,
      ),
      body: FutureBuilder<void>(
        future: _initControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return GestureDetector(
                onTapUp: (details) {
                  _onTap(details);
                },
                onScaleStart: (details) {},
                onScaleUpdate: _onZoom,
                child: PreviewScreen(controller: _controller)
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

class PreviewScreen extends StatefulWidget {
  final CameraController controller;

  const PreviewScreen({Key? key, required this.controller}) : super(key: key);

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {

  bool flashOn = false;
  double value = 50;

  void toggleFlash()
  {
    setState(() {
      flashOn = !flashOn;
      if (flashOn) {
        widget.controller.setFlashMode(FlashMode.torch);
      } else {
        widget.controller.setFlashMode(FlashMode.off);
      }
    });
  }

  @override
  Widget build(BuildContext context) {

    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Stack(
      alignment: Alignment.bottomCenter,
      //mainAxisAlignment: MainAxisAlignment.start,
      //crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: height,
          color: Colors.black,//Colors.red,
          child: Container(
              margin: EdgeInsets.only(bottom: 90),
              width: width,
              height: height - (height / 7),
              child: ClipRRect(
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                  child: CameraPreview(widget.controller)
              ),
          ),
        ),
        Container(
          alignment: Alignment.bottomCenter,
          height: height / 9,
          decoration: BoxDecoration(
            //color: Colors.red,
            //borderRadius: BorderRadius.only(topLeft: Radius.circular(100), topRight: Radius.circular(100)),
          ),
          child: Container(
            //color: Colors.black38,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                // top-row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [

                    IconButton(
                        onPressed: () async {
                          final img = await ImagePicker().pickImage(source: ImageSource.gallery);
                          if (img != null) {
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => ImageScreen(img: File(img.path))));
                          }
                        },
                        icon: Image.asset('assets/icons/gallery.png', scale: 5.5, color: Colors.white),
                    ),


                    AnimatedIconButton(
                      firstImage: 'assets/icons/initIcon.png',
                      secondImage: 'assets/icons/endIcon.png',
                      duration: Duration(milliseconds: 300),
                      color: Colors.white,
                      audio: 'audio/capture_click.mp3',
                      cameraController: widget.controller,
                      scale: 3.5,
                    ),


                    IconButton(
                      onPressed: toggleFlash,
                      icon: flashOn ? Image.asset('assets/icons/flash_on.png', scale: 5.5, color: Colors.white) : Image.asset('assets/icons/flash_off.png', scale: 5.5, color: Colors.white),
                    ),
                  ],
                ),

                SizedBox(height: 10),

                // bottom-row
                /*
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.brightness_6_rounded, size: 20, color: Colors.white),
                    SizedBox(width: 40),
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 7,
                        thumbShape: SliderComponentShape.noThumb,
                        overlayShape: SliderComponentShape.noOverlay,
                        trackShape: RectangularSliderTrackShape(),

                      ),
                      child: Slider(
                          value: value,
                          min: 0,
                          max: 100,
                          onChanged: (value) => setState(() {
                            this.value = value;
                          }),
                      ),
                    )
                  ],
                )

                */

              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ImageScreen extends StatefulWidget {
  //final String imgPath;
  final File img;
  const ImageScreen({Key? key, required this.img}) : super(key: key);

  @override
  State<ImageScreen> createState() => _ImageScreenState();
}

class _ImageScreenState extends State<ImageScreen> {

  late File imgShow;

  List<File> regions = [];

  @override
  void initState()
  {
    super.initState();
    imgShow = widget.img;
  }

  Future<void> _selectRegion() async
  {
    final croppedImg = await ImageCropper().cropImage(
        sourcePath: widget.img.path,
        compressQuality: 100,
        aspectRatioPresets: Platform.isAndroid
        ? [
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio3x2,
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.ratio4x3,
          CropAspectRatioPreset.ratio16x9
        ]
        : [
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio3x2,
          CropAspectRatioPreset.ratio4x3,
          CropAspectRatioPreset.ratio5x3,
          CropAspectRatioPreset.ratio5x4,
          CropAspectRatioPreset.ratio7x5,
          CropAspectRatioPreset.ratio16x9
        ],
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.blue,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: true,
          )
        ]

        );

    if (croppedImg != null)
    {
        setState(() {
          regions.add(File(croppedImg.path));
          imgShow = File(croppedImg.path);
        });
        print("Region Added");
    }


  }

  @override
  Widget build(BuildContext context) {

    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Preview Screen", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black45,
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: () {
                setState(() {imgShow = widget.img;});
              },
              icon: Icon(Icons.replay, color: Colors.white)
          )
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                color: Colors.black,
                height: height - (height / 9),
                child: Image.file(imgShow, fit: BoxFit.fill),
              ),

              Container(
                margin: EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _selectRegion,
                      icon: Icon(Icons.crop),
                      label: Text("Get Regions"),
                    ),
                    SizedBox(width: 20),
                    ElevatedButton.icon(
                        onPressed: () {},
                        icon: Icon(Icons.sort_by_alpha),
                        label: Text("Recognize")
                    )
                  ],
                ),
              ),
            ]
          ),

          Container(
            height: 80,
            child: Center(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(vertical: 15),
                itemCount: regions.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {setState(() {imgShow = regions[index];});},
                    child: Container(
                      color: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(
                          children: [
                            Icon(Icons.aspect_ratio_outlined, size: 30.0, color: Colors.white),
                            SizedBox(height: 0),
                            Text("R$index", style: TextStyle(fontSize: 12.0, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}
