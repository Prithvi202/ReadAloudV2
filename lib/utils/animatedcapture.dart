/*
import 'package:flutter/material.dart';

class CaptureButton extends StatefulWidget {
  const CaptureButton({Key? key}) : super(key: key);

  @override
  State<CaptureButton> createState() => _CaptureButtonState();
}

class _CaptureButtonState extends State<CaptureButton> {

  int _currIndex = 0;

  @override
  Widget build(BuildContext context) {
    return
      /*IconButton(
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) => RotationTransition(
            turns: child.key == ValueKey('initIcon')
                ? Tween<double>(begin: 1, end: 0.75).animate(anim)
                : Tween<double>(begin: 0.75, end: 1).animate(anim),
            child: FadeTransition(opacity: anim, child: child),
          ),
          child: _currIndex == 0
              //? Icon(Icons.close, key: const ValueKey('initIcon'))
              //: Icon(Icons.arrow_back, key: const ValueKey('endIcon')),

            ? Image.asset("assets/icons/initIcon.png", key: const ValueKey('initIcon'))
            : Image.asset("assets/icons/endIcon.png", key: const ValueKey('endIcon')),

          ),
        onPressed: () {
          setState(() {
            _currIndex = _currIndex == 0 ? 1 : 0;
            print(_currIndex);
          });
        },
        //progress: progress
    );*/
      IconButton(
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 1000),
          transitionBuilder: (child, animation) {
            return RotationTransition(
              turns: TweenSequence(
                <TweenSequenceItem<double>>[
                  TweenSequenceItem<double>(
                    tween: Tween<double>(
                      begin: 0.0,
                      end: 0.4,
                    ),
                    weight: 0.2,
                  ),
                  TweenSequenceItem<double>(
                    tween: Tween<double>(
                      begin: 0.4,
                      end: 1,
                    ),
                    weight: 0.2,
                  ),
                ],
              ).animate(animation),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          child: _currIndex == 0
              ? Image.asset(
            "assets/icons/initIcon.png",
            key: const ValueKey('initIcon'),
          )
              : Image.asset(
            "assets/icons/endIcon.png",
            key: const ValueKey('endIcon'),
          ),
        ),
        onPressed: () {
          setState(() {
            _currIndex = _currIndex == 0 ? 1 : 0;
            print(_currIndex);
          });
        },
      );

  }
}

 */

import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:readaloud_v2/main.dart';

class AnimatedIconButton extends StatefulWidget {
  final String firstImage;
  final String secondImage;
  final Duration duration;
  final Color color;
  final double scale;
  final String audio;
  final CameraController? cameraController;

  AnimatedIconButton({
    Key? key,
    required this.firstImage,
    required this.secondImage,
    required this.duration,
    required this.color,
    this.scale = 2.5,
    this.audio = "",
    this.cameraController,
  }) : super(key: key);

  @override
  _AnimatedIconButtonState createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<AnimatedIconButton>
    with SingleTickerProviderStateMixin {
  bool _showFirstImage = true;
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<double> _opacityAnimation;
  late CameraController cameraController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _controller.reverse();
        } else if (status == AnimationStatus.dismissed) {
          setState(() {
            _showFirstImage = true;
          });
        } else {
          setState(() {
            _showFirstImage = false;
          });
        }
      });
    _opacityAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.5),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: Tween(begin: 0.0, end: 0.4).animate(_controller),
      child: TextButton(
        style: ButtonStyle(
          overlayColor: MaterialStateProperty.all(Colors.transparent),
        ),
        child: Stack(
          children: [
            FadeTransition(
              opacity: _opacityAnimation,
              child: Image.asset(widget.firstImage, scale: widget.scale, color: widget.color),
            ),
            FadeTransition(
              opacity: _animation,
              child: Image.asset(widget.secondImage, scale: widget.scale, color: widget.color),
            ),
          ],
        ),
        onPressed: () async {
          if (_controller.isCompleted || _controller.isDismissed) {
            _controller.forward();
          }

          if (widget.audio != "")
          {
            AudioPlayer().play(AssetSource(widget.audio));
          }

          if (widget.cameraController != null)
          {
            final capturedImage = await widget.cameraController?.takePicture();
            final capImgPath = capturedImage!.path;
            Future.delayed(const Duration(milliseconds: 300), () {
              //Navigator.of(context).push(MaterialPageRoute(builder: (_) => ImageScreen(imgPath: capImgPath)));
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => ImageScreen(img: File(capturedImage.path))));
            });
          }
        },
      ),
    );
  }
}
