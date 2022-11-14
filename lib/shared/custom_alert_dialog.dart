import 'package:dpsg_app/shared/colors.dart';
import 'package:flutter/material.dart';

AlertDialog CustomAlertDialog({required Widget? title, required Widget? content,
    required actions }) {
  return AlertDialog(
    backgroundColor: kBackgroundColor,
    title: title,
    content: content,
    actions: actions,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    actionsPadding: EdgeInsets.only(left: 10, right: 10, bottom: 10),
    actionsAlignment: MainAxisAlignment.end,
  );
}

class CustomStatefulAlertDialog extends StatefulWidget {
  Widget? title;
  Widget? content;
  List<Widget>? actions;

  CustomStatefulAlertDialog(
      {
        Key? key,
        required Widget? title,
        required Widget? content,
        required actions
      }) : super(key: key);

  @override
  State<CustomStatefulAlertDialog> createState() => _CustomStatefulAlertDialogState(
      title: title,
      content: content,
      actions: actions);
}

class _CustomStatefulAlertDialogState extends State<CustomStatefulAlertDialog> {
  Widget? title;
  Widget? content;
  List<Widget>? actions;

  _CustomStatefulAlertDialogState(
  {
    required Widget? title,
    required Widget? content,
    required actions
  });

  @override
  Widget build(BuildContext context) {
    return CustomAlertDialog(title: title, content: content, actions: actions);
  }
}
