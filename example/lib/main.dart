import 'package:camera_picker/camera_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class HomePage extends StatelessWidget {
  final String title;

  const HomePage({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: HookBuilder(builder: (context) {
          final files = useState(<XFile>[]);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (files.value.isEmpty) const Text('You didn\'t select any files'),
              if (files.value.isNotEmpty) ImagesPreview(files: files.value),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final results = await Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => CameraPicker(
                            initialFiles: files.value,
                            onDelete: (file) async {
                              final confirm = (await showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete image?'),
                                      content: const Text('Do you want to delete this image?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop(false);
                                          },
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop(true);
                                          },
                                          child: const Text('Ok'),
                                        ),
                                      ],
                                    ),
                                  )) ??
                                  false;
                              return confirm;
                            },
                          )));
                  if (results != null) {
                    files.value = List.from(results);
                  }
                },
                child: const Text('Take images from camera'),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class PickerPage extends StatelessWidget {
  const PickerPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(),
      ),
    );
  }
}
