import 'package:dpsg_app/shared/colors.dart';
import 'package:flutter/material.dart';

AlertDialog CustomAlertDialog(
    {required Widget? title,
    required BuildContext context,
    required Widget? content,
    required actions}) {
  return AlertDialog(
    backgroundColor: colors(context).background,
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
      {Key? key,
      required Widget? title,
      required Widget? content,
      required actions})
      : super(key: key);

  @override
  State<CustomStatefulAlertDialog> createState() =>
      _CustomStatefulAlertDialogState(
          title: title, content: content, actions: actions);
}

class _CustomStatefulAlertDialogState extends State<CustomStatefulAlertDialog> {
  Widget? title;
  Widget? content;
  List<Widget>? actions;

  _CustomStatefulAlertDialogState(
      {required Widget? title, required Widget? content, required actions});

  @override
  Widget build(BuildContext context) {
    return CustomAlertDialog(
        context: context, title: title, content: content, actions: actions);
  }
}

Future<DateTime?> selectDate(
    {required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate}) {
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    lastDate: lastDate,
    firstDate: firstDate,
    cancelText: 'Abbrechen',
    confirmText: 'Bestätigen',
    locale: Locale('de'),
    builder: (context, child) => Theme(
      data: ThemeData.from(
        colorScheme:
            colors(context).copyWith(onSurface: colors(context).onBackground),
      ).copyWith(
          brightness: colors(context).brightness == Brightness.light
              ? Brightness.dark
              : Brightness.light),
      child: child!,
    ),
  );
}
