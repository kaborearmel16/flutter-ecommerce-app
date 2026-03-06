import 'package:flutter/material.dart'; 
import 'package:todo_list/pages/register.dart';
import 'package:todo_list/service/auth.dart';

class LoginPage extends StatelessWidget{
  LoginPage({super.key});

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: const Text(""),),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 180,),
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
                AuthService().signIn(email: emailController.text.trim(), password: passwordController.text.trim());  
              }, 
              child: const Text("Se connecter")),
            TextButton(
              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => RegisterPage())), 
              child: Text("créer un compte"))
          ],
        ),
      ),
    );
  }
}