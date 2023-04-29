import 'dart:io';

import 'package:edge_detection/edge_detection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'dart:async';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:url_launcher/url_launcher.dart';


class ScannerApp extends StatefulWidget {
  const ScannerApp({Key? key}) : super(key: key);

  @override
  State<ScannerApp> createState() => _ScannerAppState();
}

class _ScannerAppState extends State<ScannerApp> {

  // storing image path [usually string but here, it's of type Future<String> Function()
  // hence using var to dynamically assign type of data
  // to view the cropped image file, we use Image.file(File(imgPath))
  List<File> arrayOfImages = [];
  var imgPath;

  Future<void> getImage() async {

    bool isCameraGranted = await Permission.camera.request().isGranted;
    if (!isCameraGranted) {
      isCameraGranted = await Permission.camera.request() == PermissionStatus.granted;
    }

    if (!isCameraGranted) {
      // Have not permission to camera
      return;
    }

    // Generate filepath for saving
    String imagePath = join((await getApplicationSupportDirectory()).path,
        '${(DateTime
            .now()
            .millisecondsSinceEpoch / 1000).round()}.jpeg');

    try {
      //Make sure to await the call to detectEdge.
      bool success = await EdgeDetection.detectEdge(imagePath,
        canUseGallery: true,
        androidScanTitle: 'Scan Document',
        // use custom localizations for android
        androidCropTitle: 'Crop',
        androidCropBlackWhiteTitle: 'B/W Scan',
        androidCropReset: 'Original',
      );
      if (success) {
        imgPath = imagePath;
        arrayOfImages.add(File(imgPath));
      }
    } catch (e) {
      print(e);
    }

    if (!mounted) return;

    setState(() {});
  }

  Future<void> launchPdf(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  // menu options list for dropdown - pageformat
  final List<String> pageFormatList = ['A4', 'A3', 'Standard', 'Letter', 'Legal', 'A5'];

  @override
  Widget build(BuildContext context) {

    // custom func calls
    // old function
    var pdf = pw.Document();

    Future<File> compress(File img, int quality) async {
      File compFile = await FlutterNativeImage.compressImage(img.path, quality: quality);
      return compFile;
    }

    createPDFfromImages(String? pageFormat) {

      // adding some compression features over here in future..
      //

      // types of pageFormats [map]
      // access as pageFormats[key]
      var pageFormats = {
        'A4': PdfPageFormat.a4,
        'A3': PdfPageFormat.a3,
        'A5': PdfPageFormat.a5,
        'Legal': PdfPageFormat.legal,
        'Letter': PdfPageFormat.letter,
        'Standard': PdfPageFormat.standard,
      };

      for (var img in arrayOfImages) {
        final image = pw.MemoryImage(img.readAsBytesSync());
        pdf.addPage(pw.Page(
            pageFormat: pageFormats[pageFormat],
            build: (pw.Context context) {
              return pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain));
            }
        ));
      }
      // compress property of pdf
    }


    savePDF(BuildContext context, String? fname) async {

      bool isStorageGranted = await Permission.storage.request().isGranted;
      if (!isStorageGranted) {
        isStorageGranted = await Permission.storage.request() == PermissionStatus.granted;
      }

      if (!isStorageGranted) {
        // Have not permission to camera
        return;
      }

      try {
        String path = "/storage/emulated/0/Download";
        final file = File('$path/$fname.pdf');
        await file.writeAsBytes(await pdf.save());
        print("doc saved..");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Saved to\n${path}/${fname}.pdf", style: TextStyle(color: Colors.white)), elevation: 3.0, backgroundColor: Colors.black));
        //showPrintMessage('saved to docs..');
      } catch (e){
        print(e);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$e", style: TextStyle(color: Colors.white)), elevation: 3.0, backgroundColor: Colors.black));
      }
    }

    // alert box custom dialog
    Future<void> showCustomPopup(BuildContext context) async {
      final TextEditingController _textFieldController = TextEditingController();
      String? codeDialog;
      String? valueText;
      String? activePF = pageFormatList.first;

      await showDialog(
          context: context,
          builder: (context) {
            return StatefulBuilder(
                builder: (context, setState) {
                  return AlertDialog(
                    alignment: Alignment.center,
                    title: const Text('Create PDF'),

                    content: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                            onChanged: (value) {setState(() {valueText = value;});},
                            controller: _textFieldController,
                            decoration:InputDecoration(
                              hintText: "Enter filename",
                              prefixIcon: Icon(Icons.edit_document),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(color: Color.fromRGBO(255, 189, 66, 1)),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(Icons.close),
                                onPressed: () {_textFieldController.text = ""; valueText = "";},
                              ),
                            )
                        ),

                        SizedBox(height: 10.0),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,

                          children: [
                            Text("Page Format:"),
                            DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: activePF,
                                items: pageFormatList.map(buildPageLayoutItems).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    activePF = value;
                                  });
                                  setState(() {});
                                  print(activePF);
                                },
                              ),
                            ),
                          ],
                        ),

                      ],
                    ),
                    actions: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          MaterialButton(
                            color: Colors.red,
                            textColor: Colors.white,
                            child: const Text('CANCEL'),
                            onPressed: () {
                              setState(() {
                                Navigator.pop(context);
                              });
                            },
                          ),
                          MaterialButton(
                            color: Colors.green,
                            textColor: Colors.white,
                            child: const Text('OK'),
                            onPressed: () {

                              if (valueText == null)
                              {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Enter a filename first..", style: TextStyle(color: Colors.white)), elevation: 3.0, backgroundColor: Colors.black));
                              }

                              else
                              {
                                setState(() {
                                  codeDialog = valueText;
                                  createPDFfromImages(activePF);
                                  savePDF(context, valueText);
                                  Navigator.pop(context);
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  );
                }
            );
          });
    }
    // end of alert box


    // width and height
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Color.fromRGBO(20,20,20,1),

      // this is for the scan button always present in the bottom of the scaffold
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton:

      Container(
        margin: EdgeInsets.only(bottom: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            arrayOfImages.isNotEmpty ?
            PhysicalModel(
              elevation: 12.0,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(5), bottomRight: Radius.circular(5), topRight: Radius.circular(25), bottomLeft: Radius.circular(25)),
              color: Colors.transparent,//const Color.fromRGBO(255, 189, 66, 1),
              shadowColor: const Color.fromRGBO(255, 189, 66, 1),//Color.fromRGBO(169, 167, 167, 1),//
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 3,
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 5),
                  shadowColor: const Color.fromRGBO(255, 189, 66, 1),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(35), bottomRight: Radius.circular(5), topRight: Radius.circular(35), bottomLeft: Radius.circular(35)),
                    side: BorderSide(
                      width: 2.0,
                      color: Color.fromRGBO(255, 189, 66, 0.558),//Color.fromRGBO(169, 167, 167, 1),//
                    ),
                  ),
                ),
                onPressed: () {
                  /*reset function - init screen, no docs scanned..*/
                  arrayOfImages.clear();
                  imgPath = null;
                  setState(() {});
                },
                child: const Icon(
                    Icons.replay_outlined,
                    color: Color.fromRGBO(255, 189, 66, 1), //Color.fromRGBO(255, 252, 252, 1),//
                    size: 25.0
                ),
              ),
            ) : const SizedBox.shrink(),

            PhysicalModel(
              elevation: 12.0,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(5), bottomRight: Radius.circular(5), topRight: Radius.circular(25), bottomLeft: Radius.circular(25)),
              color: Colors.transparent,//const Color.fromRGBO(255, 189, 66, 1),
              shadowColor: const Color.fromRGBO(255, 189, 66, 1),//Color.fromRGBO(169, 167, 167, 1),//
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 3,
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  shadowColor: const Color.fromRGBO(255, 189, 66, 1),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(5), bottomRight: Radius.circular(5), topRight: Radius.circular(25), bottomLeft: Radius.circular(25)),
                    side: BorderSide(
                      width: 2.0,
                      color: Color.fromRGBO(255, 189, 66, 0.558),//Color.fromRGBO(169, 167, 167, 1),//
                    ),
                  ),
                ),
                onPressed: getImage,
                child: Row(
                  children: [
                    const Icon(
                        Icons.document_scanner_outlined,
                        color: Color.fromRGBO(255, 189, 66, 1), //Color.fromRGBO(255, 252, 252, 1),//
                        size: 25.0
                    ),
                    SizedBox(width: 10),
                    Text("Scan", style: TextStyle(color: Color.fromRGBO(255, 189, 66, 1))),
                  ],
                ),
              ),
            ),
            arrayOfImages.isNotEmpty ?
            PhysicalModel(
              elevation: 12.0,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(5), bottomRight: Radius.circular(5), topRight: Radius.circular(25), bottomLeft: Radius.circular(25)),
              color: Colors.transparent,//const Color.fromRGBO(255, 189, 66, 1),
              shadowColor: const Color.fromRGBO(255, 189, 66, 1),//Color.fromRGBO(169, 167, 167, 1),//
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 3,
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.all(15),
                  shadowColor: const Color.fromRGBO(255, 189, 66, 1),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(35), bottomRight: Radius.circular(35), topRight: Radius.circular(35), bottomLeft: Radius.circular(5)),
                    side: BorderSide(
                      width: 2.0,
                      color: Color.fromRGBO(255, 189, 66, 0.558),//Color.fromRGBO(169, 167, 167, 1),//
                    ),
                  ),
                ),
                onPressed: () {
                  /*PDF function call here*/
                  /*
                    createPDFfromImages();
                    savePDF(context);
                    */
                  showCustomPopup(context);
                },
                child: const Icon(
                    Icons.picture_as_pdf_outlined,
                    color: Color.fromRGBO(255, 189, 66, 1), //Color.fromRGBO(255, 252, 252, 1),//
                    size: 25.0
                ),
              ),
            ) : const SizedBox.shrink(),
          ],
        ),
      ),

      /*Container(
        margin: EdgeInsets.all(10),
        height: 50,
        width: 100,
        child: ElevatedButton(
          onPressed: getImage,
          child: Center(
            child: Text("Scan"),
          ),
        ),
      ),*/

      appBar: AppBar(
        centerTitle: true,
        title: Text("PDF Scan", style: TextStyle(color: Color.fromRGBO(255, 189, 66, 1), fontSize: 22.0)),
        backgroundColor: Color.fromRGBO(30, 30, 30, 1),
      ),
      body: Column(
        mainAxisAlignment: arrayOfImages.isNotEmpty ? MainAxisAlignment.start : MainAxisAlignment.center,
        crossAxisAlignment:  CrossAxisAlignment.center,
        children: [
          /*
          Text("Cropped Img Path"),
          SizedBox(height: 10),
          Text(arrayOfImages.toString()),
          SizedBox(height: 20),
          imgPath == null ? Text("") : Image.file(arrayOfImages[0]),

           */

          // end of upper string thingy

          arrayOfImages.isEmpty ? const Center(child: Text("Scan some documents first!", style: TextStyle(color: Color.fromRGBO(255, 189, 66, 1), fontSize: 15.0)))
              : Padding(
            padding: EdgeInsets.symmetric(vertical: 30, horizontal: 15),
            child: ReorderableGridView.count(
              shrinkWrap: true,
              onReorder: (oldPos, newPos) {
                File image = arrayOfImages.removeAt(oldPos);
                arrayOfImages.insert(newPos, image);
                setState(() {});
              },
              crossAxisCount: 3,
              childAspectRatio: 0.7,
              children: arrayOfImages.map((File imageSelected) => IntrinsicHeight(
                key: ValueKey(imageSelected.path),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: (){arrayOfImages.remove(imageSelected); setState(() {});}, icon: Icon(Icons.delete, size: 20.0, color: Color.fromRGBO(167, 164, 164, 1))),
                    SizedBox(height: 4),
                    Image.file(imageSelected, fit: BoxFit.cover, height: 90),
                    SizedBox(height: 5),
                    Text("Page ${(arrayOfImages.indexOf(imageSelected) + 1).toString()}", style: TextStyle(fontSize: 12, color: Color.fromRGBO(219, 189, 59, 1.0)))
                  ],
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

DropdownMenuItem<String> buildPageLayoutItems(String item) => DropdownMenuItem(
  value: item,
  child: Text(item, style: TextStyle()),
);


