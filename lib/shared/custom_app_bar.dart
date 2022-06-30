import 'package:dpsg_app/shared/colors.dart';
import 'package:flutter/material.dart';

class CustomAppBar extends AppBar {
  CustomAppBar({Key? key, required this.appBarTitle}) : super(key: key);

  String appBarTitle;

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(widget.appBarTitle),
      leading: Hero(
        tag: 'icon_hero',
        child: TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Image(
            image: AssetImage('assets/icon_2500px.png'),
          ),
        ),
      ),
    );
  }
}
