library camera_picker;

import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:camera_picker/picker_store.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

export 'package:cross_file/cross_file.dart';

/// A CameraPicker.
class CameraPicker extends HookWidget {
  /// Error callback when an error is throw on takePicture camera
  final Function(dynamic error, dynamic stack)? onError;

  /// Resolution preset of the camera
  final ResolutionPreset resolutionPreset;

  /// Max number of picture allowed, used to enable the continue button
  final int? maxPicture;

  /// Min number of picture allowed, used to enable the continue button
  final int minPicture;

  /// Show or not the cancel button
  final bool showCancelButton;

  /// Show or not the torch button
  final bool showTorchButton;

  /// Show or not the switch camera button
  final bool showSwitchCameraButton;

  /// Color to use for icons
  final Color iconColor;

  /// Callback when an existing picture is asked to be delete, return true or false to continue deletion
  final FutureOr<bool> Function(XFile file)? onDelete;

  /// Initial selection of images to put in the preview
  final List<XFile>? initialFiles;

  /// Custom builder to show "no camera" widget
  final WidgetBuilder? noCameraBuilder;

  const CameraPicker({
    Key? key,
    this.initialFiles,
    this.noCameraBuilder,
    this.showSwitchCameraButton = true,
    this.onDelete,
    this.resolutionPreset = ResolutionPreset.high,
    this.iconColor = Colors.white,
    this.showTorchButton = true,
    this.showCancelButton = true,
    this.onError,
    this.maxPicture,
    this.minPicture = 1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final store = useMemoized(() => PickerStore(filesData: initialFiles ?? [], minPicture: minPicture, maxPicture: maxPicture));
    final availableCamerasFuture = useMemoized(() => availableCameras());
    final cameras = useState<List<CameraDescription>?>(null);
    return Material(
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: ColoredBox(
          color: Colors.black,
          child: FutureBuilder<List<CameraDescription>>(
            builder: (context, snapshot) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (snapshot.connectionState == ConnectionState.done) {
                  cameras.value ??= snapshot.data ?? [];
                }
              });

              if (snapshot.connectionState == ConnectionState.waiting || cameras.value == null) {
                return const Center(child: CircularProgressIndicator());
              }

              if (cameras.value!.isEmpty) {
                return noCameraBuilder?.call(context) ??
                    Center(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'No camera available',
                            style: TextStyle(color: Theme.of(context).errorColor),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('Back'))
                        ],
                      ),
                    );
              }

              return HookBuilder(builder: (context) {
                final cameraControllerState = useState(CameraController(
                  cameras.value!.firstWhereOrNull((element) => element.lensDirection == CameraLensDirection.back) ?? cameras.value!.first,
                  resolutionPreset,
                  enableAudio: false,
                ));
                final isBackCamera = useState(true);
                final cameraController = cameraControllerState.value;
                final initializeCamera = useMemoized(() => cameraController.initialize(), [cameraController]);

                return WillPopScope(
                  onWillPop: () async {
                    cameraController.dispose();
                    return true;
                  },
                  child: FutureBuilder(
                      future: initializeCamera,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        return CameraPreview(
                          cameraController,
                          key: Key(cameraController.description.name),
                          child: SafeArea(
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (showTorchButton && isBackCamera.value)
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: HookBuilder(builder: (context) {
                                      final mode = useState(FlashMode.auto);
                                      return IconButton(
                                        onPressed: () {
                                          if (mode.value == FlashMode.auto) {
                                            mode.value = FlashMode.torch;
                                            cameraController.setFlashMode(FlashMode.torch);
                                          } else {
                                            mode.value = FlashMode.auto;
                                            cameraController.setFlashMode(FlashMode.auto);
                                          }
                                        },
                                        icon: Icon(mode.value == FlashMode.auto ? Icons.flashlight_on_outlined : Icons.flashlight_on),
                                        color: iconColor,
                                      );
                                    }),
                                  ),
                                if (showSwitchCameraButton && cameras.value!.length > 1)
                                  Positioned(
                                    top: 10,
                                    left: 10,
                                    child: IconButton(
                                      onPressed: () {
                                        if (isBackCamera.value) {
                                          cameraControllerState.value = CameraController(
                                            cameras.value!.firstWhereOrNull((element) => element.lensDirection == CameraLensDirection.front) ??
                                                cameras.value!.last,
                                            resolutionPreset,
                                            enableAudio: false,
                                          );
                                        } else {
                                          cameraControllerState.value = CameraController(
                                            cameras.value!.firstWhereOrNull((element) => element.lensDirection == CameraLensDirection.back) ??
                                                cameras.value!.first,
                                            resolutionPreset,
                                            enableAudio: false,
                                          );
                                        }
                                        isBackCamera.value = !isBackCamera.value;
                                      },
                                      icon: Icon(isBackCamera.value ? Icons.camera_front_outlined : Icons.camera_rear_outlined),
                                      color: iconColor,
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      HookBuilder(builder: (context) {
                                        useListenable(store);
                                        return ImagesPreview(
                                          files: store.filesData,
                                          onDelete: (index) async {
                                            if (onDelete == null || await onDelete!(store.filesData[index])) {
                                              store.removeFile(store.filesData[index]);
                                            }
                                          },
                                        );
                                      }),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          if (showCancelButton)
                                            IconButton(
                                              onPressed: () {
                                                cameraController.dispose();
                                                Navigator.of(context).pop();
                                              },
                                              tooltip: MaterialLocalizations.of(context).cancelButtonLabel,
                                              color: iconColor,
                                              enableFeedback: true,
                                              icon: const Icon(Icons.close),
                                            ),
                                          IconButton(
                                            onPressed: () async {
                                              try {
                                                final file = await cameraController.takePicture();
                                                store.addFile(file);
                                              } catch (ex, stack) {
                                                onError?.call(ex, stack);
                                              }
                                            },
                                            enableFeedback: true,
                                            color: iconColor,
                                            iconSize: 40,
                                            icon: const Icon(
                                              Icons.photo_camera_outlined,
                                            ),
                                          ),
                                          HookBuilder(
                                            builder: (context) {
                                              useListenable(store);
                                              return IconButton(
                                                onPressed: store.canContinue
                                                    ? () {
                                                        cameraController.dispose();
                                                        Navigator.of(context).pop(store.filesData);
                                                      }
                                                    : null,
                                                enableFeedback: true,
                                                tooltip: MaterialLocalizations.of(context).okButtonLabel,
                                                icon: const Icon(Icons.check),
                                                disabledColor: Colors.grey[600],
                                                color: iconColor,
                                              );
                                            }
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                );
              });
            },
            future: availableCamerasFuture,
          ),
        ),
      ),
    );
  }
}

class ImagesPreview extends HookWidget {
  final List<XFile> files;
  final Function(int index)? onDelete;

  const ImagesPreview({Key? key, this.onDelete, required this.files}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ioFiles = useMemoized(() => files.map((e) => File(e.path)).toList(), [files, files.length]);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < ioFiles.length; i++)
            ImagePreview(
              file: ioFiles[i],
              onDelete: onDelete == null
                  ? null
                  : () {
                      onDelete?.call(i);
                    },
            ),
        ],
      ),
    );
  }
}

class ImagePreview extends StatelessWidget {
  final File file;
  final Color borderColor;
  final Color iconColor;
  final Color? disabledIconColor;
  final VoidCallback? onDelete;
  final double previewHeight;
  final double previewWidth;

  const ImagePreview(
      {Key? key,
      this.previewHeight = 60,
      this.previewWidth = 80,
      this.onDelete,
      required this.file,
      this.disabledIconColor,
      this.iconColor = Colors.white,
      this.borderColor = Colors.white})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: DecoratedBox(
        decoration: BoxDecoration(border: Border.all(color: borderColor)),
        child: Padding(
          padding: const EdgeInsets.all(1),
          child: Stack(
            children: [
              Image.file(
                file,
                height: previewHeight,
                width: previewWidth,
                fit: BoxFit.cover,
              ),
              if (onDelete != null)
                Positioned(
                  top: -10,
                  right: -10,
                  child: IconButton(
                    onPressed: onDelete,
                    color: iconColor,
                    disabledColor: disabledIconColor,
                    iconSize: 18,
                    tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                    icon: const Icon(Icons.cancel),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}
