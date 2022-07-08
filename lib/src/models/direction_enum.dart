
// ignore_for_file: constant_identifier_names
enum DirectionEnum {
  N, NE, E, SE, S, SW, W, NW;

  factory DirectionEnum.fromDegrees(double degrees) {
    return DirectionEnum.values[(degrees / 45).round() % 8];
  }
}

extension DirectionEnumExtention on DirectionEnum {
  String get name => toString().split('.').last;
}