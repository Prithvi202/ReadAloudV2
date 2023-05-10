import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TextSumm {
  final String apiKey;

  TextSumm(this.apiKey);

  Future<String> summarizeText(String text) async {
    final url = Uri.parse('https://api.meaningcloud.com/summarization-1.0');

    final payload = {
      'key': apiKey,
      'txt': text,
      'sentences': '7',
    };

    final response = await http.get(url.replace(queryParameters: payload));

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);

      if (jsonResponse.containsKey('summary')) {
        return jsonResponse['summary'];
      } else {
        throw Exception('Summary not found in response');
      }
    } else {
      throw Exception('Failed to summarize text');
    }
  }
}

class Textsummary extends StatefulWidget {
  final String outputText;

  const Textsummary({Key? key, required this.outputText}) : super(key: key);

  @override
  State<Textsummary> createState() => _TextsummaryState();
}


class _TextsummaryState extends State<Textsummary> {

  String summaryText = '';
/*
  @override
  void initState () {
    summTxt();
    super.initState();
  }
*/
  TextSumm summ = TextSumm('d3f52fb2c7253b2090cc47119e703757');
  Future<void> summTxt() async {
    //return await(summ.summarizeText(widget.outputText));
    summaryText = await(summ.summarizeText(widget.outputText));
    print(summaryText);
    setState(() {});
  }
  @override
  Widget build(BuildContext context) {

    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text("Summarize Text"),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: Container(
        color: Color.fromRGBO(20, 20, 20, 1),
        height: height,
        width: width,
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 30.0),
              const Text('Captured Text',
                  style: TextStyle(
                      fontSize: 20.0, color: Color.fromRGBO(255, 190, 70, 1))),
              // const SizedBox(height: 20.0),
              if (widget.outputText != "")
                Container(
                  height: 250,
                  margin:
                  const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                  child: ListView(
                    children: [
                      SelectableText(
                        widget.outputText,
                        textAlign: TextAlign.left,
                        style: TextStyle(
                            fontSize: 20, color: Colors.white.withOpacity(0.6)),
                        showCursor: true,
                        cursorColor: Colors.grey[200],
                        cursorRadius: const Radius.circular(6),
                        scrollPhysics: const ClampingScrollPhysics(),
                      ),
                    ],
                  ),
                ),
              if (widget.outputText == "")
                Text('No text detected..\n',
                    textAlign: TextAlign.justify,
                    style: TextStyle(
                        fontSize: 18, color: Colors.white.withOpacity(0.4))),

              const SizedBox(height: 20),

              Center(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    elevation: 10,
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.all(15),
                    side: const BorderSide(width: 1, color: Color.fromRGBO(255, 189, 66, 1)),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    shadowColor: const Color.fromRGBO(255, 189, 66, 1),
                  ),
                  onPressed: summTxt,
                  child: const Text("Summarize",
                      style: TextStyle(
                          color: Color.fromRGBO(255, 189, 66, 1),
                          fontSize: 18.0)),
                ),
              ),

              const SizedBox(height: 20),

              Container(
                  height: 250,
                  margin:
                  const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                  child: ListView(
                    children: [
                      SelectableText(
                        summaryText,
                        textAlign: TextAlign.left,
                        style: TextStyle(
                            fontSize: 20, color: Colors.white.withOpacity(0.6)),
                        showCursor: true,
                        cursorColor: Colors.grey[200],
                        cursorRadius: const Radius.circular(6),
                        scrollPhysics: const ClampingScrollPhysics(),
                      ),
                    ],
                  ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}

