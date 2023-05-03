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

  final FlutterTts flutterTts = FlutterTts();

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
              height: 200,
              margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
              child: ListView(
                children: [
                  SelectableText(
                    widget.scannedText,
                    textAlign: TextAlign.justify,
                    style: TextStyle(
                        fontSize: 18, color: Colors.white.withOpacity(0.6)),
                    showCursor: true,
                    cursorColor: Colors.grey[200],
                    cursorRadius: const Radius.circular(6),
                    scrollPhysics: const ClampingScrollPhysics(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                speechFunction(widget.scannedText);
              }, 
              child: Text("Read")
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}