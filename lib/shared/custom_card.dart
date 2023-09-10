import 'package:dpsg_app/shared/colors.dart';
import 'package:flutter/material.dart';

Widget buildCard({required child, Function? onTap, Function? onLongPress}) {
  return Padding(
    padding: const EdgeInsets.all(2.0),
    child: Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: kMainColor,
      child: onTap == null ?
      Padding(
        padding: const EdgeInsets.all(10.0),
        child: child,
      ) :
      InkWell(
        onTap: () => onTap(),
        onLongPress: onLongPress == null ? null : () => onLongPress(),
        customBorder:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: child,
        ),
      ),
    ),
  );
}