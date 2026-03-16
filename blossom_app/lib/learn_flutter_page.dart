import 'package:flutter/material.dart';

class LearnFlutterPage extends StatefulWidget{
      const LearnFlutterPage({super.key});

     @override
     State<LearnFlutterPage> createState() => _LearnFlutterPageState();

  }


class  _LearnFlutterPageState extends State<LearnFlutterPage>{
  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar:AppBar(
        title: const Text('Learn Flutter new '),
        backgroundColor: Colors.pink,
        automaticallyImplyLeading: false, // removed the default back barrow
        leading: IconButton(onPressed:(){
          Navigator.of(context).pop();// pop the page and shows the page before or under
        } , icon : const Icon(Icons.arrow_back_ios),)
      ),
    );
  }
}
