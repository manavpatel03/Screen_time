import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:screen_state/screen_state.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:move_to_background/move_to_background.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
int sum = 0;
int  counter = 0;
String str = "";
String name = "manav";

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String bgExecutionStatus = '';

  @override
  void initState() {
    super.initState();
    startBackgroundTask();
  }

  void startBackgroundTask() {
    FlutterBackgroundService.initialize(onStart);
    FlutterBackgroundService().start();

    // Register the callback function to be executed in the background
    FlutterBackgroundService().sendData({'action': 'setAsForeground'});
    FlutterBackgroundService().sendData({
      'action': 'startTask',
      'taskName': 'backgroundTask',
      'isLooped': true,
      'frequency': 15 * 60 * 1000, // 15 minutes
    });

    FlutterBackgroundService().sendData({'action': 'setTitle', 'title': 'App in Background'});
  }

  void onStart() {
    WidgetsFlutterBinding.ensureInitialized();
    // This function will be executed in the background
    Timer.periodic(const Duration(seconds: 1), (timer) {
      // Perform your background tasks or operations here
      // This is just an example
      setState(() {
        bgExecutionStatus = 'Executing background task';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Background Execution'),
      ),
      body: Center(
        child: Text(
          'Background Execution Status:\n$bgExecutionStatus',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}


class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => new _MyAppState();
}

class ScreenStateEventEntry {
  ScreenStateEvent event;
  DateTime? time;

  ScreenStateEventEntry(this.event) {
    time = DateTime.now();
  }
}

class _MyAppState extends State<MyApp> {
  Screen _screen = Screen();
  late StreamSubscription<ScreenStateEvent> _subscription;
  bool started = false;
  List<ScreenStateEventEntry> _log = [];
  Timer? _timer;

  void initState() {
    super.initState();
    initPlatformState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        counter = counter + 1;
      });
    });
    sum = 0;
  }


  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    startListening();
  }

  void onData(ScreenStateEvent event) {
    setState(() {
      _log.add(ScreenStateEventEntry(event));
    });

    if (event == ScreenStateEvent.SCREEN_OFF) {
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          counter = counter + 1;
          if (counter % 10 == 0) {
            senddata();
          }
        });
      });
    } else {
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          sum = sum + 1;
          counter = counter + 1;
        });
        if (counter % 10 == 0) {
          senddata();
        }
        if (counter >= 300) {
          setState(() {
            str = "You used mobile for $sum seconds out of 5 minutes.";
          });
          _timer?.cancel();
        }
      });
    }
  }

  Future senddata() async {
    final doc = FirebaseFirestore.instance.collection('total time used').doc(
        'inwiKXKJ9L80eAldwp7z');
    final note = {
      name: "Used $sum out of $counter seconds",
    };
    await doc.set(note);
  }

  void startListening() {
    try {
      _subscription = _screen.screenStateStream!.listen(onData);
      setState(() => started = true);
      counter = 0;
    } on ScreenStateException catch (exception) {
      //print(exception);
    }
  }

  void stopListening() {
    _subscription.cancel();
    setState(() => started = false);
    _timer?.cancel();
    sum = 0;
    counter = 0;
  }

}
