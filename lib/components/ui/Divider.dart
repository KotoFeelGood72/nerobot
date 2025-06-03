import 'package:flutter/material.dart';

class Square extends StatelessWidget {
  final double height; 

  const Square({Key? key, this.height = 16.0}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
    );
  }
}
