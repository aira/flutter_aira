import 'package:intl/intl.dart';

const kDateTimeZPattern = 'yyyy-MM-dd\'T\'HH:mm:ssZ';
const kDateTimePattern = 'MM/dd/yyyy HH:mm:ss';

extension StringConversion on String {
  DateTime get dateTimeZ {
    DateTime date = DateFormat(kDateTimeZPattern).parse(this);
    return date.add(date.timeZoneOffset);
  }

  DateTime get dateTime {
    DateTime date = DateFormat(kDateTimePattern).parse(this);
    return date.add(date.timeZoneOffset);
  }
}

extension DateTimeE on DateTime {
  String get dateTimeStringZ {
    return DateFormat(kDateTimeZPattern).format(this);
  }

  String get dateTimeString {
    return DateFormat(kDateTimePattern).format(this);
  }
}
