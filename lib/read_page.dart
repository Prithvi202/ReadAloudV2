import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:translator/translator.dart';

class ReadPage extends StatefulWidget {
  String scannedText;
  ReadPage({super.key, required this.scannedText});

  @override
  State<ReadPage> createState() => _ReadPageState();
}

class _ReadPageState extends State<ReadPage> {

  late FlutterTts flutterTts;
  int start = 0;
  int end = 0;

  @override
  void initState()
  {
    initTts();
    super.initState();
  }

  initTts()
  {
    flutterTts = FlutterTts();
    flutterTts.setProgressHandler((text, startOffset, endOffset, word) {
      setState(() {
        start = startOffset;
        end = endOffset;
      });
    });
  }

  @override
  void dispose()
  {
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    double magicNumber = width * 0.003;

    bool isSpeaking = false;

    speechFunction(String text) async
    {
      var translator = GoogleTranslator();
      Translation translation = await translator.translate(widget.scannedText);
      String langCode = translation.sourceLanguage.code;
      await flutterTts.setLanguage(langCode);
      await flutterTts.setPitch(0.8);
      if (isSpeaking == false) {
        await flutterTts.speak(text);
        isSpeaking = true;
      }
      else {
        await flutterTts.stop();
        isSpeaking = false;
      }
    }

    pauseFunction(int start, int end) async {
      await flutterTts.pause();
      isSpeaking = false;
      setState(() {
        this.start = start;
        this.end = end;
      });
    }

    stopFunction() async {
      await flutterTts.stop();
      start = 0;
      end = 0;
      isSpeaking = false;
      setState(() {});
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Read Text"),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),

      body: Container(
        width: width,
        height: height - (height / 7),
        color: Colors.black,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: magicNumber * 200,
              color: Colors.transparent,
              padding: EdgeInsets.symmetric(horizontal: magicNumber * 30, vertical: magicNumber * 10),
              child: SingleChildScrollView(
                child: RichText(
                textAlign: TextAlign.left,
                text: TextSpan(style: TextStyle(fontSize: magicNumber * 16), children: <TextSpan>[
                  TextSpan(
                      text: widget.scannedText != null && start != 0
                          ? widget.scannedText.substring(0, start)
                          : "",
                      style: TextStyle(color: Color.fromRGBO(150, 150, 150, 1))),
                  TextSpan(
                      text: widget.scannedText != null
                          ? widget.scannedText.substring(start, end)
                          : "",
                      style: TextStyle(color: Color.fromRGBO(240, 240, 240, 1), fontWeight: FontWeight.w600)),
                  TextSpan(
                      text: widget.scannedText != null ? widget.scannedText.substring(end) : "",
                      style: TextStyle(color: Color.fromRGBO(150, 150, 150, 1))),
                    ]
                  ),
                ),
              )
            ),

            SizedBox(height: magicNumber * 30),

            /*ElevatedButton(
              onPressed: () {
                speechFunction(widget.scannedText);
              }, 
              child: Text("Read")
            ),*/

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => speechFunction(widget.scannedText),
                  style: ElevatedButton.styleFrom(
                    elevation: 10,
                    backgroundColor: Colors.black,
                    padding: EdgeInsets.all(magicNumber * 10),
                    shadowColor: const Color.fromRGBO(255, 189, 66, 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(magicNumber * 5),
                          bottomRight: Radius.circular(magicNumber * 5),
                          topRight: Radius.circular(magicNumber * 25),
                          bottomLeft: Radius.circular(magicNumber * 25)),
                      side: const BorderSide(
                        width: 2.0,
                        color: Color.fromRGBO(255, 189, 66,
                            0.558), //Color.fromRGBO(169, 167, 167, 1),//
                      )
                    )
                  ), 
                  child: Icon(Icons.play_arrow, size: magicNumber * 35, color: Color.fromRGBO(255, 189, 66, 1)),
                ),
                ElevatedButton(
                  onPressed: () => pauseFunction(start, end),
                  style: ElevatedButton.styleFrom(
                    elevation: 10,
                    backgroundColor: Colors.black,
                    padding: EdgeInsets.all(magicNumber * 10),
                    shadowColor: const Color.fromRGBO(255, 189, 66, 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(magicNumber * 5),
                          bottomRight: Radius.circular(magicNumber * 5),
                          topRight: Radius.circular(magicNumber * 25),
                          bottomLeft: Radius.circular(magicNumber * 25)),
                      side: const BorderSide(
                        width: 2.0,
                        color: Color.fromRGBO(255, 189, 66,
                            0.558), //Color.fromRGBO(169, 167, 167, 1),//
                      )
                    )
                  ), 
                  child: Icon(Icons.pause_sharp, size: magicNumber * 35, color: Color.fromRGBO(255, 189, 66, 1)),
                ),
                ElevatedButton(
                  onPressed: () => stopFunction(),
                  style: ElevatedButton.styleFrom(
                    elevation: 10,
                    backgroundColor: Colors.black,
                    padding: EdgeInsets.all(magicNumber * 10),
                    shadowColor: const Color.fromRGBO(255, 189, 66, 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(magicNumber * 5),
                          bottomRight: Radius.circular(magicNumber * 5),
                          topRight: Radius.circular(magicNumber * 25),
                          bottomLeft: Radius.circular(magicNumber * 25)),
                      side: const BorderSide(
                        width: 2.0,
                        color: Color.fromRGBO(255, 189, 66,
                            0.558), //Color.fromRGBO(169, 167, 167, 1),//
                      )
                    )
                  ), 
                  child: Icon(Icons.stop_sharp, size: magicNumber * 35, color: Color.fromRGBO(255, 189, 66, 1)),
                ),
              ],
            )
            
          ],
        ),
      ),
    );
  }
}