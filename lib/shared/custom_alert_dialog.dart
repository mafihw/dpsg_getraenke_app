import 'package:dpsg_app/shared/colors.dart';
import 'package:flutter/material.dart';

AlertDialog CustomAlertDialog({required Widget? title, required Widget? content,
    required actions }) {
  return AlertDialog(
    backgroundColor: kBackgroundColor,
    title: title,
    content: content,
    actions: actions,
    actionsPadding: EdgeInsets.only(left: 10, right: 10, bottom: 10),
    actionsAlignment: MainAxisAlignment.spaceBetween,
  );
}