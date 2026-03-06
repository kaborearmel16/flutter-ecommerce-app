import 'package:flutter/material.dart';
import 'package:todo_list/pages/login.dart';
import 'package:todo_list/pages/verified_email.dart';
import 'package:todo_list/service/auth.dart';

class RegisterPage extends StatelessWidget{
  RegisterPage({super.key});

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: const Text("Inscription"),),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 100,),
            TextField(
              controller: emailController,
              decoration: InputDecoration(hintText: "e-mail"),
            ),
            const SizedBox(height: 10,),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(hintText: "password"),
            ),
            const SizedBox(height: 60,),
            ElevatedButton(
              onPressed: ()async{
                await AuthService().signUp(email: emailController.text.trim(), password: passwordController.text.trim()); 
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => VerifiedEmailPage()));
              },
              child: const Text("S'inscrire")),
            TextButton(
              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage())), 
              child: Text("j'ai un compte"))
          ],
        ),
      ),
    );
  }
}