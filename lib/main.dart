import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:window_size/window_size.dart' as window_size;
import 'package:pomotask_client/widgets/auth_widgets.dart';

// App 전체에서 사용되는 데이터
late String serverAddress;
late String loggedInUser;

void main()
{
  loadConfig();

  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS)
  {
    window_size.setWindowMinSize(const Size(800, 600));
  }

  runApp(const MyApp());
}

void loadConfig()
{
  final file = File('config/config.json');
  final content = file.readAsStringSync();
  final jsonData = jsonDecode(content);
  serverAddress = jsonData['serverAddress'];
}

class MyApp extends StatelessWidget
{
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context)
  {
    return MaterialApp(
      title: 'PomoTaskManager',
      debugShowCheckedModeBanner: false,
      home: const LoginPage(),
    );
  }
}
