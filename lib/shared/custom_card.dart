import 'package:dpsg_app/shared/colors.dart';
import 'package:flutter/material.dart';

Widget buildCard({required child, Function? onTap, Color? background}) {
  return Padding(
    padding: const EdgeInsets.all(2.0),
    child: Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: background ?? kMainColor,
      child: onTap == null
          ? Padding(
              padding: const EdgeInsets.all(10.0),
              child: child,
            )
          : InkWell(
              onTap: () => onTap(),
              customBorder: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: child,
              ),
            ),
    ),
  );
}
