Camera picker

This package will allow you to take multiple camera picture at once and return them for you to process them.

## Features

![Preview](previews/preview.jpg "Preview 1")
![Preview 2](previews/preview2.jpg "Preview 2")

## Getting started

This package uses the [camera](https://pub.dev/packages/camera#installation "Camera package") package, so please follow the setup for iOS and Android. 

## Usage

Full example at [example folder](example "example folder"). 

```dart
final results = await Navigator.of(context).push(
  MaterialPageRoute(builder: (context) =>CameraPicker())
);
if (results != null) {
  //Do whatever you want with the files.
}
```

## Additional information

You can customize colors, show/icon the different buttons and specify minimum and maximum number of
picture you want.

To see full list of customization please read [CameraPicker](lib/camera_picker.dart#L18).
