import 'package:dpsg_app/shared/colors.dart';
import 'package:flutter/material.dart';

SnackBar CustomSnackBar({required Widget content, SnackBarAction? action, Duration duration = const Duration(seconds: 4)}) {
  return SnackBar(
    content: content,
    duration: duration,
    backgroundColor: kColorScheme.primary,
    padding: EdgeInsets.only(left: 15),
    behavior: SnackBarBehavior.floating,
    action: action,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}