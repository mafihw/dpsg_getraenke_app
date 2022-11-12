import 'package:dpsg_app/shared/colors.dart';
import 'package:flutter/material.dart';

SnackBar CustomSnackBar({required Widget content, SnackBarAction? action}) {
  return SnackBar(
    content: content,
    backgroundColor: kColorScheme.primary,
    padding: EdgeInsets.only(left: 15),
    behavior: SnackBarBehavior.floating,
    action: action,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}