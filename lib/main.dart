import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:readaloud_v2/utils/animatedcapture.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
    [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]
  );
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
                child: PreviewScreen(controller: _controller, zoomLevel: _zoomLevel)
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
  final double zoomLevel;

  const PreviewScreen({Key? key, required this.controller, required this.zoomLevel}) : super(key: key);

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {

  bool flashOn = false;
  //double value = 50;

  double _minExposureOffset = -2.0, _maxExposureOffset = 2.0;
  late double _currentExposureOffset = 0.0;

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
          color: Colors.transparent,
          height: height / 10,
          margin: EdgeInsets.only(bottom: 100.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [

                  Icon(Icons.wb_sunny_outlined, size: 20, color: Colors.white),

                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 5,
                      inactiveTrackColor: Colors.white.withOpacity(0.2),
                      activeTrackColor: Colors.white,
                      thumbColor: Colors.white,
                      minThumbSeparation: 10,
                      inactiveTickMarkColor: Colors.white.withOpacity(0.3),
                      thumbShape: RoundSliderThumbShape(pressedElevation: 0, enabledThumbRadius: 3, elevation: 0),
                    ),
                    child: Slider(
                      min: _minExposureOffset,
                      max: _maxExposureOffset,
                      value: _currentExposureOffset, 
                      divisions: 16,
                      onChanged: (_currentExposureOffset) {
                        setState(() {
                          this._currentExposureOffset = _currentExposureOffset;
                          print(_currentExposureOffset.toStringAsFixed(2));
                          widget.controller.setExposureOffset(_currentExposureOffset);
                        });
                      },
                    ),
                  ),

                  Text(_currentExposureOffset >= 0 ? "+ ${_currentExposureOffset.toStringAsFixed(2)}" : "- ${_currentExposureOffset.abs().toStringAsFixed(2)}", style: TextStyle(color: Colors.white, fontSize: 15.0)),

                ],
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.zoom_in, color: Colors.white, size: 18.0),
                  SizedBox(width: 5.0),
                  Text("${widget.zoomLevel.toStringAsFixed(2)}x", style: TextStyle(fontSize: 13.0, color: Colors.white)),
                ],
              ),

            ],
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
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => ImageScreen(img: File(img.path), isGallery: true)));
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
                      customMethod: () {
                        // this function is called within a setState function anyways
                        setState(() {
                          widget.controller.setFlashMode(FlashMode.off);
                          if (flashOn) flashOn = !flashOn;
                        });
                        
                      },
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
  final bool isGallery;
  const ImageScreen({Key? key, required this.img, required this.isGallery}) : super(key: key);

  @override
  State<ImageScreen> createState() => _ImageScreenState();
}

class _ImageScreenState extends State<ImageScreen> {

  late File imgShow;

  // array of regions
  List<File> regions = [];
  // array of strings from regions
  List<String> stringFromRegion = [];

  // list detection language
  List<String> langs = ["Latin", "Devanagari", "Japanese", "Korean"];

  // current detection language
  late String currLang;
  int currLangIndex = 0;

  @override
  void initState()
  {
    super.initState();
    imgShow = widget.img;
    currLang = langs[0];
    regions.add(imgShow);
  }

  // get partitions of base image [region-wise split]
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
          CropAspectRatioPreset.ratio16x9,
        ],
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Select Regions',
            
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            cropFrameColor: Colors.red,
            activeControlsWidgetColor: Colors.teal,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            dimmedLayerColor: Colors.black45,
          )
        ]

        );

    if (croppedImg != null)
    {
        setState(() {
          if (regions[0] == widget.img) {
            regions[0] = File(croppedImg.path);
          }
          else {
            regions.add(File(croppedImg.path));
          }
          imgShow = File(croppedImg.path);
        });
        print("Region Added");
    }
  }

  Future<String> getTextFromImage(File image) async
  {

    TextRecognitionScript lang;
    print(currLang);
    if (currLang == "Latin")  lang = TextRecognitionScript.latin;
    else if (currLang == "Devanagari")  lang = TextRecognitionScript.devanagiri;
    else if (currLang == "Japanese")  lang = TextRecognitionScript.japanese;
    else if (currLang == "Korean")  lang = TextRecognitionScript.korean;
    else lang = TextRecognitionScript.latin;

    // main logic
    var inputImg = InputImage.fromFile(image);
    var textDetector = GoogleMlKit.vision.textRecognizer(script: lang);
    RecognizedText recog_string = await textDetector.processImage(inputImg);
    await textDetector.close();

    String scannedText = "";
    for (TextBlock block in recog_string.blocks)
    {
      for (TextLine line in block.lines)
      {
        scannedText = "$scannedText${line.text}\n";
      }
    }

    return scannedText;

    /*
    setState(() {
      if (stringFromRegion.length > regions.length) {
        stringFromRegion.clear();
        stringFromRegion[0] = scannedText;
      } else {
        stringFromRegion.add(scannedText);
      }
    });
    */

  }

/*
  String generateDisplayText()
  {
    String outString = "";
    for (int i=0; i<regions.length; i++)
    {
      getTextFromImage(regions[i]);
    }

    for (int x=0; x<stringFromRegion.length; x++)
    {
      outString += stringFromRegion[x];
    }
    
    print("length of regions: " + regions.length.toString());
    print("length of stringregions: " + stringFromRegion.length.toString());
    return outString;
  }
*/

  @override
  Widget build(BuildContext context) {

    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
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
                child: Image.file(imgShow, fit: imgShow != widget.img ?  BoxFit.contain : BoxFit.fill),
              ),

              Container(
                margin: EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 12.0,
                        backgroundColor: Colors.black,
                        shadowColor: const Color.fromRGBO(255, 189, 66, 1),
                        //backgroundColor: Color.fromRGBO(212, 182, 9, 0.903),
                        shape: const CircleBorder(
                          side: BorderSide(
                            width: 2.0, 
                            color: Color.fromRGBO(255, 189, 66, 0.358)
                          )
                        ),
                        padding: EdgeInsets.all(15.0),
                      ),
                      onPressed: _selectRegion,
                      child: Icon(Icons.crop, color: Color.fromRGBO(255, 189, 66, 1), size: 25.0),
                      //label: Text("Get Regions"),
                    ),
                    
                    SizedBox(width: 20),

                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          //backgroundColor: Color.fromRGBO(212, 182, 9, 0.903),
                          elevation: 12.0,
                          backgroundColor: Colors.black,
                          shadowColor: Color.fromRGBO(255, 189, 66, 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(30)),
                            side: BorderSide(width: 2.0, color: Color.fromRGBO(255, 189, 66, 0.358)),
                          ),
                          padding: EdgeInsets.all(15.0),
                        ),
                        onPressed: () {
                          setState(() {
                            if (currLangIndex < 3) {
                              currLangIndex += 1;
                            } else {
                              currLangIndex = 0;
                            }
                            currLang = langs[currLangIndex];
                          });
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.translate, color: Color.fromRGBO(255, 189, 66, 1), size: 25.0),
                            SizedBox(width: 10.0),
                            Text(currLang, style: TextStyle(color: Color.fromRGBO(255, 189, 66, 1), fontSize: 15.0)),
                          ],
                        ),
                    ),

                    SizedBox(width: 20),

                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          elevation: 12.0,
                          backgroundColor: Colors.black,
                          shadowColor: Color.fromRGBO(255, 189, 66, 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(30)),
                            side: BorderSide(width: 2.0, color: Color.fromRGBO(255, 189, 66, 0.358)),
                          ),
                          padding: EdgeInsets.all(15.0),
                        ),
                        onPressed: () async {

                          String outputString = "";
                          for (int i=0; i<regions.length; i++)
                          {
                            outputString += await getTextFromImage(regions[i]);
                          }

                          showModalBottomSheet(
                            context: context,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                            ),
                            isScrollControlled: true,
                            builder: (context) => outputModal(outputString),
                          ); 
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.sort_by_alpha, color: Color.fromRGBO(255, 189, 66, 1), size: 25.0),
                            SizedBox(width: 10.0),
                            Text("Detect", style: TextStyle(color: Color.fromRGBO(255, 189, 66, 1), fontSize: 15.0)),
                          ],
                        ),
                    ),
                    
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
                            Icon(Icons.aspect_ratio_outlined, size: 30.0, color: Colors.white.withOpacity(0.7)),
                            SizedBox(height: 0),
                            Text("R$index", style: TextStyle(fontSize: 12.0, color: Colors.white.withOpacity(0.3))),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              )
            ),
          )
        ],
      ),
    );
  }

  /*
  Widget outputModal(String outputString) => Container(
    height: 200,
    padding: EdgeInsets.only(top: 20, bottom: 30, left: 20, right: 20),
    decoration: BoxDecoration(
      color: Color.fromRGBO(20, 20, 20, 1),
      borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
    ),
    child: SingleChildScrollView(
      child: DefaultTextStyle(
        style: TextStyle(color: Colors.white, fontSize: 18.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            //Text(outputString.isEmpty ? "No Text Detected" : outputString),
            TextField()
          ],
        ),
      ),
    ),
  );
  */

  
  Widget outputModal(String outputString) {
    TextEditingController controller = TextEditingController();
    ScrollController _scrollController = ScrollController();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: 400,
        padding: EdgeInsets.only(top: 20, bottom: 20, left: 20, right: 20),
        decoration: BoxDecoration(
          color: Color.fromRGBO(20, 20, 20, 1),
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: DefaultTextStyle(
          style: TextStyle(color: Colors.white, fontSize: 18.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
    
            Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
                  PhysicalModel(
                    elevation: 12.0,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(5), bottomRight: Radius.circular(5), topRight: Radius.circular(25), bottomLeft: Radius.circular(25)),
                    color: Colors.transparent,//const Color.fromRGBO(255, 189, 66, 1),
                    shadowColor: const Color.fromRGBO(255, 189, 66, 1),//Color.fromRGBO(169, 167, 167, 1),//
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 3,
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.all(15),
                        shadowColor: const Color.fromRGBO(255, 189, 66, 1),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(topLeft: Radius.circular(5), bottomRight: Radius.circular(5), topRight: Radius.circular(25), bottomLeft: Radius.circular(25)),
                          side: BorderSide(
                              width: 2.0,
                              color: Color.fromRGBO(255, 189, 66, 0.558),//Color.fromRGBO(169, 167, 167, 1),//
                          ),
                        ),
                      ),
                      onPressed: () {
                      
                        //isSpeaking ? stop() : speak(scannedText);
                      
                      },
                      child: const Icon(
                          Icons.transcribe_outlined,
                          color: Color.fromRGBO(255, 189, 66, 1), //Color.fromRGBO(255, 252, 252, 1),//
                          size: 25.0
                        ),
                    ),
                  ),

                  PhysicalModel(
                    elevation: 12.0,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(5), bottomRight: Radius.circular(5), topRight: Radius.circular(25), bottomLeft: Radius.circular(25)),
                    color: Colors.transparent,
                    shadowColor: const Color.fromRGBO(255, 189, 66, 1),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 3,
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.all(15),
                        shadowColor: const Color.fromRGBO(255, 189, 66, 1),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(topLeft: Radius.circular(5), bottomRight: Radius.circular(5), topRight: Radius.circular(25), bottomLeft: Radius.circular(25)),
                          side: BorderSide(
                              width: 2.0,
                              color: Color.fromRGBO(255, 189, 66, 0.558)),
                        ),
                      ),
                      onPressed: () => {
                        /*
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TranslatePage(scannedText: scannedText),
                          ),
                        )
                        */
                      },
                      child: const Icon(Icons.translate,
                          color: Color.fromRGBO(255, 189, 66, 1), size: 25.0),
                    ),
                  ),


                  PhysicalModel(
                    elevation: 12.0,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(5), bottomRight: Radius.circular(5), topRight: Radius.circular(25), bottomLeft: Radius.circular(25)),
                    color: Colors.transparent,
                    shadowColor: const Color.fromRGBO(255, 189, 66, 1),
    
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 3,
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.all(15),
                        shadowColor: const Color.fromRGBO(255, 189, 66, 1),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(topLeft: Radius.circular(5), bottomRight: Radius.circular(5), topRight: Radius.circular(25), bottomLeft: Radius.circular(25)),
                          side: BorderSide(
                              width: 2.0,
                              color: Color.fromRGBO(255, 189, 66, 0.558)),
                        ),
                      ),
                      onPressed: () => {},
                      child: const Icon(Icons.text_snippet_outlined,
                          color: Color.fromRGBO(255, 189, 66, 1), size: 25.0),
                    ),
                  ),
                ],
              ),
    
              // sizedbox for UI design
              SizedBox(height: 20.0),
    
              // for text below..
              outputString.isNotEmpty ? Expanded(
                child: SizedBox(
                  width: 280,
                  child: Scrollbar(
                    isAlwaysShown: true,
                    controller: _scrollController,
                    child: TextFormField(
                      initialValue: outputString,
                      scrollController: _scrollController,
                      keyboardType: TextInputType.multiline,
                      onChanged: (value) {
                        setState(() {
                          outputString = value;  
                        });
                      },
                      style: TextStyle(color: Colors.white),
                      maxLines: null,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color.fromRGBO(255, 189, 66, 0.7), width: 2)),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color.fromRGBO(255, 189, 66, 0.2), width: 2)),
                        hintText: '',
                      ),
                    ),
                  ),
                ),
              ) : Text("No text detected"),

              SizedBox(height: 20.0),

              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 3,
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.all(15),
                    shadowColor: const Color.fromRGBO(255, 189, 66, 1),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      side: BorderSide(
                          width: 2.0,
                          color: Color.fromRGBO(255, 189, 66, 0.558)),
                    ),
                  ),
                  onPressed: () async{
                    await Clipboard.setData(ClipboardData(text: outputString));
                  },
                  child: const Text("Copy to Clipboard", style: TextStyle(color: Color.fromRGBO(255, 189, 66, 1), fontSize: 14.0)),
                ),
              
            ],
          ),
        ),
      ),
    );
  }

}
