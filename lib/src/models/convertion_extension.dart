import 'package:intl/intl.dart';

extension StringConversion on String {
  DateTime get dateTimeZ {
    DateTime date = DateFormat('yyyy-MM-dd\'T\'HH:mm:ssZ').parse(this);
    return date.add(date.timeZoneOffset);
  }

  DateTime get dateTime {
    DateTime date = DateFormat('MM/dd/yyyy HH:mm:ss').parse(this);
    return date.add(date.timeZoneOffset);
  }

  // https://www.iso.org/iso-8601-date-and-time-format.html
  DateTime get dateTimeISO8601 {
    DateTime date = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').parse(this);
    return date.add(date.timeZoneOffset);
  }
}