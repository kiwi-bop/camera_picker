

import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class PickerStore extends ChangeNotifier {
  final int? maxPicture;
  final int minPicture;
  final List<XFile> filesData;

  PickerStore({this.maxPicture, required this.minPicture, required this.filesData});

  bool get canContinue => filesData.length >= minPicture && (maxPicture == null || filesData.length < maxPicture!);

  void addFile(XFile file) {
    filesData.add(file);
    notifyListeners();
  }

  void removeFile(XFile file) async {
    filesData.remove(file);
    notifyListeners();
    try {
      await File(file.path).delete();
    } catch(ex) {
      //nothing to do if delete file fails
    }
  }
}