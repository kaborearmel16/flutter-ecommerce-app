import 'package:flutter/material.dart';  
import 'package:todo_list/wrapper/auth_wrapper.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
  


Future<void> main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);
  runApp(const MyApp());
}

  


class MyApp extends StatelessWidget {
  const MyApp({super.key});
 
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData( 
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.grey),
      ),
      home:  AuthWrapper(),
    );
  }
}