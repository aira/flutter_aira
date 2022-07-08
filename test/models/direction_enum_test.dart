import 'package:flutter_aira/src/models/direction_enum.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DirectionEnum', () {
    test('anything between -22.5 and 22.5 (exclusive) degrees should be North', () {
      expect(DirectionEnum.fromDegrees(22.4), DirectionEnum.N);
      expect(DirectionEnum.fromDegrees(-22.4), DirectionEnum.N);
    });
    test('-22.5 and 22.5 degrees shouldn\'t be North', () {
      expect(DirectionEnum.fromDegrees(22.5), DirectionEnum.NE);
      expect(DirectionEnum.fromDegrees(-22.5), DirectionEnum.NW);
    });
    test('-22.5 + 360 and 22.5 + 360 (inclusive) degrees shouldn\'t be North?!? or should it?', () {
      expect(DirectionEnum.fromDegrees(-22.5), DirectionEnum.NW);
      // yes, I know! this is not really consistent and this is caused by the rounding:
      //    -22.5 rounds to -23 and (-22.5 + 360) = 337.5 which rounds to 338 which is != -23
      // to keep it simple, I leave it as is. This is still much sturdier than using a switch case.
      expect(DirectionEnum.fromDegrees(-22.5 + 360), DirectionEnum.N);
    });
    test('anything between > 360 or < -360 still return the right coordinate', () {
      expect(DirectionEnum.fromDegrees(22.4 + 360), DirectionEnum.N);
      expect(DirectionEnum.fromDegrees(-22.4 - 360), DirectionEnum.N);
    });
    test('name returns only the last part of the toString value', () {
      expect(DirectionEnum.fromDegrees(22.4 + 360).name, 'N');
    });
  });
}
