import 'package:dpsg_app/shared/colors.dart';
import 'package:flutter/material.dart';

class CustomBottomBar extends StatelessWidget {
  const CustomBottomBar({super.key});
  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      elevation: 5,
      color: kMainColor,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Builder(
              builder: ((context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              )),
            ),
          ],
        ),
      ),
    );
  }
}
