import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Toast {
  static void showToast(String message, {Color? backgroundColor, Color? textColor}) {
    Fluttertoast.showToast(
      msg: message,
      timeInSecForIosWeb: 5,
      backgroundColor: backgroundColor ?? Colors.black,
      textColor: textColor ?? Colors.white,
      fontSize: 15,
    );
  }

  static void showErrorToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      timeInSecForIosWeb: 5,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 15,
    );
  }

  static void showSuccessToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      timeInSecForIosWeb: 5,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 15,
    );
  }

  static void showInfoToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      timeInSecForIosWeb: 5,
      backgroundColor: Colors.blue,
      textColor: Colors.white,
      fontSize: 15,
    );
  }
}
