import 'package:flutter/material.dart';

class EmptyLayout extends StatelessWidget {
  final Widget body;
  final String title;
  const EmptyLayout({super.key, required this.body, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title),),
      body: body,
      
    );
  }
}