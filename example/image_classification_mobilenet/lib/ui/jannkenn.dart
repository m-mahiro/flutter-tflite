import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_classification_mobilenet/helper/image_classification_helper.dart';

class JannkennScreen extends StatefulWidget {
  final dynamic camera;

  const JannkennScreen({super.key, required this.camera});

  @override
  State<StatefulWidget> createState() => _JannkennScreenState();
}


class _JannkennScreenState extends State<JannkennScreen> with WidgetsBindingObserver {
  late CameraController cameraController;
  late ImageClassificationHelper imageClassificationHelper;
  String jannkennMessage = '最初はグー！';
  String buttonMessage = 'Play Jannkenn!';
  Map<String, double>? classification;
  bool _isProcessing = false;
  bool _isPlaying = false;
  bool _doAnalysis = false;
  // bool _showDetail = true;

  String path_rock = 'assets/images/janken_gu.png';
  String path_scissor = 'assets/images/janken_choki.png';
  String path_paper = 'assets/images/janken_pa.png';
  String path_rock_shadow = 'assets/images/janken_gu_shadow.png';
  String path_hand_asset = '';

  String opponentHand = '';
  List<MapEntry<String, double>> battleClassification = [];
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    initCamera();
    imageClassificationHelper = ImageClassificationHelper();
    imageClassificationHelper.initHelper();
    super.initState();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.paused:
        cameraController.stopImageStream();
        break;
      case AppLifecycleState.resumed:
        if (!cameraController.value.isStreamingImages) {
          await cameraController.startImageStream(imageAnalysis);
        }
        break;
      default:
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    cameraController.dispose();
    imageClassificationHelper.close();
    super.dispose();
  }

  // init camera
  void initCamera() {
    cameraController = CameraController(widget.camera, ResolutionPreset.medium,
        imageFormatGroup: Platform.isIOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.yuv420);
    cameraController.initialize().then((value) {
      cameraController.startImageStream(imageAnalysis);
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> imageAnalysis(CameraImage cameraImage) async {
    // if image is still analyze, skip this frame
    if (_isProcessing || !_doAnalysis) {
      return;
    }
    _isProcessing = true;
    classification = await imageClassificationHelper.inferenceCameraFrame(cameraImage);
    _isProcessing = false;
    if (mounted) {
      setState(() {});
    }
  }

  Widget cameraWidget(context) {
    var camera = cameraController.value;
    // fetch screen size
    final size = MediaQuery.of(context).size;

    // calculate scale depending on screen and camera ratios
    // this is actually size.aspectRatio / (1 / camera.aspectRatio)
    // because camera preview size is received as landscape
    // but we're calculating for portrait orientation
    var scale = size.aspectRatio * camera.aspectRatio;

    // to prevent scaling down, invert the value
    if (scale < 1) scale = 1 / scale;

    return Transform.scale(
      scale: scale,
      child: Center(
        child: CameraPreview(cameraController),
      ),
    );
  }


   void startJannkenn() async {
    setState(() {
      battleClassification = [];
      _isPlaying = true;
      _doAnalysis = true;
      jannkennMessage = '最初は';
      buttonMessage = 'おわる';
      path_hand_asset = path_rock_shadow;
    });
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!_isPlaying) return;

    setState(() {
      jannkennMessage = 'ぐー！';
      path_hand_asset = path_rock;
    });
    await Future.delayed(const Duration(milliseconds: 1000));
    if(!_isPlaying) return;

    setState(() {
      jannkennMessage = 'じゃんけん！';
      path_hand_asset = path_rock_shadow;
    });
    await Future.delayed(const Duration(milliseconds: 1000));
    if(!_isPlaying) return;

    if (classification != null) {
      battleClassification = classification!.entries.toList();
      battleClassification.sort((a, b) => a.value.compareTo(b.value));
      opponentHand = battleClassification[battleClassification.length - 1].key;
      if(opponentHand == 'なにもなし') {
        opponentHand = battleClassification[battleClassification.length - 2].key;
      }
    }
    switch(opponentHand) {
      case 'ぐー': path_hand_asset = path_scissor;
      case 'ちょき': path_hand_asset = path_paper;
      case 'ぱー': path_hand_asset = path_rock;
      default: path_hand_asset = path_rock_shadow;
    }


     setState(() {
      jannkennMessage = 'ぽん！';
      _doAnalysis = false;
      buttonMessage = 'もういっかい！';
    });

  }

  void terminateJannkenn() {
    setState(() {
      _isPlaying = false;
      _doAnalysis = false;
      battleClassification = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    // Size size = MediaQuery.of(context).size;
    List<Widget> list = [];
    
    list.add(
      Center(
        child: _isPlaying ?
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(path_hand_asset),
                Text(jannkennMessage,
                  style: const TextStyle(fontSize: 30),),
              ],
            )
            : const Text("下のボタンをタップしてね！！"),
      ),
    );
    list.add(
      Align(
        alignment: Alignment.topCenter,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 25),
              child: SizedBox(
                height: 120,
                child: (cameraController.value.isInitialized)
                    ? cameraWidget(context)
                    : Container(),
              ),
            ),
            SizedBox(width: 20,),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (battleClassification != null && _isPlaying)
                      ...(battleClassification..sort(
                              (a, b) => a.value.compareTo(b.value),
                        ))
                          .reversed
                          .take(3)
                          .map(
                            (e) => Container(
                          padding: const EdgeInsets.all(8),
                          color: Colors.white,
                          child: Row(
                            children: [
                              Text(e.key),
                              const Spacer(),
                              Text(e.value.toStringAsFixed(2))
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    list.add(Align(
      alignment: Alignment.bottomCenter,
      child: Column(
        children: <Widget>[
          const Spacer(),
          ElevatedButton(
            onPressed: _isPlaying ? terminateJannkenn : startJannkenn,
            child: Text(_isPlaying ? buttonMessage : 'スタート'),
          ),
          const SizedBox(height: 40,),
        ],
      )
    ));

    return SafeArea(
      child: Stack(
        children: list,
      ),
    );
  }
}