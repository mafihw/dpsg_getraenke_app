import 'package:dpsg_app/shared/colors.dart';
import 'package:flutter/material.dart';

class CustomBottomBar extends StatelessWidget {
  const CustomBottomBar({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Builder(
                builder: ((context) => IconButton(
                      icon: Icon(
                        Icons.menu,
                        color: colors(context).onSurface,
                      ),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ))),
          ],
        ),
      ),
      elevation: 5,
      color: colors(context).surface,
    );
  }
}
