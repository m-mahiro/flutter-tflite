/*
 * Copyright 2023 The TensorFlow Authors. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *             http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_classification_mobilenet/ui/jannkenn.dart';

import 'ui/camera.dart';
import 'ui/gallery.dart';

Future<void> main() async {
  runApp(const BottomNavigationBarApp());
}

class BottomNavigationBarApp extends StatelessWidget {
  const BottomNavigationBarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: BottomNavigationBarExample(),
    );
  }
}

class BottomNavigationBarExample extends StatefulWidget {
  const BottomNavigationBarExample({super.key});

  @override
  State<BottomNavigationBarExample> createState() => _BottomNavigationBarExampleState();
}

class _BottomNavigationBarExampleState extends State<BottomNavigationBarExample> {
  late CameraDescription cameraDescription;
  int _selectedIndex = 0;
  List<Widget>? _widgetOptions;

  bool cameraIsAvailable = Platform.isAndroid || Platform.isIOS;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initPages();
    });
  }

  initPages() async {
    _widgetOptions = [const GalleryScreen()];

    if (cameraIsAvailable) {
      // get list available camera
      cameraDescription = (await availableCameras()).last;
      _widgetOptions!
        ..add(CameraScreen(camera: cameraDescription))
        ..add(JannkennScreen(camera: cameraDescription));
    }

    setState(() {});
  }

  void _onItemTapped(int index) {
    if (!cameraIsAvailable) {
      debugPrint("This is not supported on your current platform");
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: Image.asset('assets/images/tfl_logo.png'),
        // title: Image.asset('assets/images/jannkenn_log.png'),
        // backgroundColor: Colors.black.withOpacity(0.5),
        title: const Center(child: Text('多分負けてくれるアプリ')),
      ),
      body: Center(
        child: _widgetOptions?.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.image),
            label: '写真を選ぶ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera),
            label: 'ライブカメラ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.waving_hand),
            label: 'じゃんけん',
          ),

        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}
