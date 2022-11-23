import 'package:flutter/material.dart';

class CustomAppBar extends AppBar {
  CustomAppBar({Key? key, required this.appBarTitle, this.onIconPress})
      : super(key: key);

  String appBarTitle;
  Function? onIconPress;

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(widget.appBarTitle),
      leading: Hero(
        tag: 'icon_hero',
        child: TextButton(
          onPressed: () {
            _controller.forward().then((value) => {_controller.reset()});
            widget.onIconPress?.call();
          },
          child: RotationTransition(
            turns: Tween(begin: 0.0, end: 1.0).animate(_controller),
            child: const Image(image: AssetImage('assets/icon_500px.png')),
          ),
        ),
      ),
    );
  }
}
