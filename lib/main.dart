import 'dart:async';
import 'dart:math';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Parallel Downloads'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  StreamController<TaskProgressUpdate> progressUpdateStream =
      StreamController();
  bool loadABunchInProgress = false;

  @override
  void initState() {
    super.initState();
    // Use .enqueue for true parallel downloads, i.e. you don't wait for completion of the tasks you
// enqueue, and can enqueue hundreds of tasks simultaneously.

// First define an event listener to process `TaskUpdate` events sent to you by the downloader,
// typically in your app's `initState()`:

    FileDownloader().updates.listen((update) {
      switch (update) {
        case TaskStatusUpdate():
          // process the TaskStatusUpdate, e.g.
          switch (update.status) {
            case TaskStatus.complete:
              print('Task ${update.task.taskId} success!');

            case TaskStatus.canceled:
              print('Download was canceled');

            case TaskStatus.paused:
              print('Download was paused');

            default:
              print('Download not successful');
          }

        case TaskProgressUpdate():
          // process the TaskProgressUpdate, e.g.
          progressUpdateStream.add(update); // pass on to widget for indicator
      }
    });
  }

  Future<void> processLoadABunch(String uri) async {
    if (!loadABunchInProgress) {
      setState(() {
        loadABunchInProgress = true;
      });
      await getPermission(PermissionType.notifications);
      await FileDownloader().enqueue(DownloadTask(
          url: uri,
          filename: 'File_${Random().nextInt(1000)}',
          group: 'bunch',
          updates: Updates.progress)); // must provide progress updates!
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        loadABunchInProgress = false;
      });
    }
  }

  /// Attempt to get permissions if not already granted
  Future<void> getPermission(PermissionType permissionType) async {
    var status = await FileDownloader().permissions.status(permissionType);
    if (status != PermissionStatus.granted) {
      if (await FileDownloader()
          .permissions
          .shouldShowRationale(permissionType)) {
        debugPrint('Showing some rationale');
      }
      status = await FileDownloader().permissions.request(permissionType);
      debugPrint('Permission for $permissionType was $status');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      bottomSheet: DownloadProgressIndicator(progressUpdateStream.stream,
          showPauseButton: true,
          showCancelButton: true,
          backgroundColor: Colors.grey,
          maxExpandable: 3),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                // final successfullyEnqueued = await FileDownloader().enqueue(
                //     DownloadTask(
                //         url: 'https://google.com',
                //         filename: 'google.html',
                //         updates: Updates.statusAndProgress));
                processLoadABunch(
                  "https://images.pexels.com/photos/24253539/pexels-photo-24253539/free-photo-of-a-bridge-over-a-river-with-a-city-in-the-background.jpeg",
                );
              },
              child: const Text('Download 1'),
            ),
            ElevatedButton(
              onPressed: () {
                processLoadABunch(
                  "https://images.pexels.com/photos/3759126/pexels-photo-3759126.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
                );
              },
              child: const Text('Download 2'),
            ),
            ElevatedButton(
              onPressed: () {
                processLoadABunch(
                  "https://images.pexels.com/photos/8922245/pexels-photo-8922245.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
                );
              },
              child: const Text('Download 3'),
            ),
          ],
        ),
      ),
    );
  }
}
