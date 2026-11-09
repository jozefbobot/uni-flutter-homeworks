import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String formatDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

String formatEventTime(DateTime time) =>
    DateFormat('d MMM yyyy · HH:mm').format(time.toLocal());

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
