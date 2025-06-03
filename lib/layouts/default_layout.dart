import 'package:flutter/material.dart';

class DefaultLayout extends StatelessWidget {
  final String title;
  final PreferredSizeWidget? customAppBar;
  final Color appBarBackgroundColor;
  final Color appBarTextColor;
  final Widget? bottomBar;
  final Widget body;
  final bool centerTitle;
  final List<Widget>? actions;

  const DefaultLayout({
    Key? key,
    required this.title,
    this.customAppBar,
    this.appBarBackgroundColor = Colors.white,
    this.appBarTextColor = Colors.black,
    this.bottomBar,
    required this.body,
    this.centerTitle = true,
    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar ?? AppBar(
        backgroundColor: appBarBackgroundColor,
        elevation: 0,
        centerTitle: centerTitle,
        title: Text(
          title,
          style: TextStyle(
            color: appBarTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: actions,
        automaticallyImplyLeading: false,
      ),
      body: body,
      bottomNavigationBar: bottomBar,
    );
  }
}
