import 'package:flutter/widgets.dart';

String tr(
  BuildContext context, {
  required String fr,
  required String en,
  required String ar,
}) {
  switch (Localizations.localeOf(context).languageCode) {
    case 'ar':
      return ar;
    case 'en':
      return en;
    default:
      return fr;
  }
}

